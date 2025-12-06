import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({Key? key}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // TODO: SECURITY - Move API key to environment variables or secure storage
  // For now using placeholder - replace with actual key in local development only
  // Use API key from GeminiService
  static String get _apiKey => GeminiService.apiKey;
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('chat_history') ?? [];
      
      setState(() {
        _messages.clear();
        for (var msgJson in history) {
          final msg = ChatMessage.fromJson(json.decode(msgJson));
          _messages.add(msg);
        }
      });
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = _messages.map((msg) => json.encode(msg.toJson())).toList();
      await prefs.setStringList('chat_history', history);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  void _addWelcomeMessage() {
    if (_messages.isEmpty) {
      final welcomeMessage = ChatMessage(
        text: "Hello! I'm your OncoNutri health assistant, here to support you with nutrition guidance during your cancer care journey.\n\nI can help you with:\n\n• Personalized nutrition advice for different cancer types\n• Dietary recommendations during treatment\n• Managing side effects through diet\n• Meal planning and food choices\n• General wellness and health queries\n\nWhat would you like to know today?",
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(welcomeMessage);
      });
      
      _saveChatHistory();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();
    await _saveChatHistory();

    print('📨 Sending message: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');

    try {
      print('🔄 Calling Gemini API...');
      final response = await _getGeminiResponse(text);
      
      print('✅ Got response: "${response.substring(0, response.length > 50 ? 50 : response.length)}..."');
      
      final botMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(botMessage);
        _isTyping = false;
      });

      _scrollToBottom();
      await _saveChatHistory();
    } catch (e) {
      print('❌ Send message error: $e');
      setState(() {
        _messages.add(ChatMessage(
          text: "I'm experiencing connectivity issues. Here are some tips while we reconnect:\n\n"
              "• Focus on whole, unprocessed foods\n"
              "• Stay well hydrated throughout the day\n"
              "• Eat small, frequent meals\n"
              "• Include protein with each meal\n\n"
              "Try asking your question again in a moment!",
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      await _saveChatHistory();
    }
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    // Handle simple conversational messages first
    final msgLower = userMessage.toLowerCase().trim();
    
    // Greetings
    if (msgLower == 'hi' || msgLower == 'hello' || msgLower == 'hey' || msgLower == 'hi there') {
      return 'Hello! I am here to provide professional nutrition guidance for your cancer care journey. How may I assist you today?';
    }
    
    // Thanks responses
    if (msgLower == 'thanks' || msgLower == 'thank you' || msgLower == 'thank you so much' || msgLower == 'thanks a lot') {
      return 'You\'re very welcome! I\'m here to support you anytime you need nutrition guidance. Please don\'t hesitate to reach out with any questions about your diet or wellness. Take care!';
    }
    
    // OK/Acknowledgment
    if (msgLower == 'ok' || msgLower == 'okay' || msgLower == 'got it' || msgLower == 'understood' || msgLower == 'alright') {
      return 'Wonderful! If you have any other questions about nutrition, meal planning, or managing treatment side effects, I\'m always here to help. Feel free to ask anything!';
    }
    
    // Goodbye
    if (msgLower == 'bye' || msgLower == 'goodbye' || msgLower == 'see you' || msgLower == 'good night') {
      return 'Take care and wishing you strength on your journey. Remember to stay hydrated, eat nutritious meals, and rest well. I\'m here whenever you need nutrition support. Goodbye for now!';
    }
    
    // Good morning/evening
    if (msgLower.contains('good morning') || msgLower.contains('good afternoon') || msgLower.contains('good evening')) {
      final greeting = msgLower.contains('morning') ? 'Good morning!' : 
                      msgLower.contains('afternoon') ? 'Good afternoon!' : 'Good evening!';
      return '$greeting I hope you\'re feeling well today. How can I assist you with your nutrition needs?';
    }
    
    // Detect cancer type from user message
    String? cancerType = _detectCancerType(msgLower);
    
    // Try API with retry logic (3 attempts with exponential backoff)
    int maxRetries = 3;
    int retryCount = 0;
    Exception? lastError;
    
    while (retryCount < maxRetries) {
      try {
        final url = Uri.parse('$_baseUrl?key=$_apiKey');
        
        String cancerContext = cancerType != null 
            ? '\n\nIMPORTANT: The user is asking about $cancerType. Provide SPECIFIC food recommendations for $cancerType with detailed nutritional benefits. Focus your entire response on $cancerType nutrition.'
            : '';
        
        final systemPrompt = '''You are a professional OncoNutri health assistant - a knowledgeable, compassionate medical nutrition specialist focused on cancer care.

Your role:
- Provide evidence-based, professional nutrition guidance for cancer patients
- Offer specific, actionable food recommendations for different cancer types
- Suggest practical dietary modifications based on treatment stages
- Help manage treatment-related side effects through nutrition
- Provide clear, medically-sound meal planning advice

Professional standards:
- Maintain a warm yet professional tone (like a skilled nurse or dietitian)
- Use clear, accessible medical terminology when appropriate
- Provide structured, easy-to-follow recommendations
- Include specific foods with their nutritional benefits (at least 6-8 foods)
- Always encourage consultation with healthcare providers
- Never diagnose conditions or prescribe treatments
- Focus on evidence-based nutrition science$cancerContext

CRITICAL FORMATTING RULES:
- DO NOT use markdown symbols like ** or __ or ## or ***
- Use UPPERCASE for section headers (e.g., NUTRITION GUIDANCE FOR BREAST CANCER)
- Use bullet points (•) for lists WITHOUT any bold or italic markers
- Write in plain text only - no asterisks, no underscores for formatting
- Keep responses informative yet concise (250-400 words)
- End with a supportive, professional closing

User question: $userMessage''';

      final body = json.encode({
        'contents': [
          {
            'parts': [
              {'text': systemPrompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 500,
        }
      });

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw Exception('Request timed out after 20 seconds');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('✅ Gemini API Success - Status: 200');
        print('📦 Response data keys: ${data.keys.toList()}');
        
        // Check if we have valid response structure
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          
          // Check for parts in content
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty &&
              candidate['content']['parts'][0]['text'] != null) {
            
            String responseText = candidate['content']['parts'][0]['text'].toString();
            
            print('💬 Gemini response length: ${responseText.length} characters');
            
            // Clean any markdown formatting that might have slipped through
            responseText = _cleanMarkdown(responseText);
            
            print('✅ Returning cleaned response');
            return responseText;
          } else {
            print('❌ No text in parts, checking alternative structure');
            print('📦 Candidate structure: ${json.encode(candidate)}');
            throw Exception('No text content found in API response');
          }
        } else {
          print('❌ Invalid API response structure - no candidates');
          print('📦 Full response: ${json.encode(data)}');
          throw Exception('Invalid response structure from API');
        }
      } else {
        print('❌ API Error: ${response.statusCode} - ${response.body}');
        throw Exception('API request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      lastError = e as Exception;
      retryCount++;
      print('❌ Gemini API Error (attempt $retryCount/$maxRetries): $e');
      
      if (retryCount < maxRetries) {
        // Wait before retrying with exponential backoff (500ms, 1000ms, 1500ms)
        int delayMs = 500 * retryCount;
        print('🔄 Retrying in ${delayMs}ms...');
        await Future.delayed(Duration(milliseconds: delayMs));
        continue; // Retry
      }
      
      // All retries failed, use fallback
      print('🚫 All $maxRetries API retry attempts failed. Last error: $lastError');
      print('💡 Using intelligent fallback response...');
      break; // Exit retry loop
    }
    } // End retry loop
    
    // Enhanced fallback responses with specific food recommendations
    // Use cancer type detection if available
    if (cancerType != null) {
      return _getCancerSpecificFallback(cancerType, userMessage);
    }
    
    // Generic fallback for non-cancer specific questions
    return 'I apologize, but I\'m having trouble connecting right now. However, I can provide general cancer nutrition guidance.\n\n'
        'GENERAL NUTRITION GUIDELINES:\n\n'
        '• Focus on whole, unprocessed foods\n'
        '• Eat 5+ servings of vegetables daily\n'
        '• Stay well hydrated with water and herbal teas\n'
        '• Include lean proteins with each meal\n'
        '• Choose whole grains over refined grains\n'
        '• Limit processed meats and added sugars\n\n'
        'Please try your question again in a moment, or specify which cancer type you need guidance for (breast, lung, colon, prostate, etc.).';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _deleteMessage(int index) async {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.colorDarkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          localizations.chatDeleteMessage,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
          ),
        ),
        content: Text(
          localizations.chatDeleteConfirm,
          style: TextStyle(color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel, style: TextStyle(color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF666666))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(localizations.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _messages.removeAt(index);
      });
      await _saveChatHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(localizations.chatMessageDeleted),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _clearChat() async {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.colorDarkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          localizations.chatClearHistory,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
          ),
        ),
        content: Text(
          localizations.chatClearConfirm,
          style: TextStyle(color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel, style: TextStyle(color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF666666))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(localizations.chatClear),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      
      setState(() {
        _messages.clear();
      });
      
      // Add welcome message after clearing
      _addWelcomeMessage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppTheme.colorDarkSurface : const Color(0xFF2D2D2D),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF4CAF50),
              child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: 20),
            ),
            SizedBox(width: 12),
            Text(
              localizations.chatbotTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            onPressed: _clearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index], index);
                    },
                  ),
          ),
          if (_isTyping) _buildTypingIndicator(),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark 
                  ? AppTheme.colorDarkSurface.withOpacity(0.5) 
                  : const Color(0xFF4CAF50).withOpacity(0.1),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 60,
              color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF4CAF50),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.chatStartConversation,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.chatAskAnything,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return TweenAnimationBuilder<double>(
      key: ValueKey('${message.timestamp.millisecondsSinceEpoch}_$index'),
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isUser) ...[
              Hero(
                tag: 'bot_avatar_$index',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GestureDetector(
                onLongPress: () => _deleteMessage(index),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: message.isUser 
                        ? (isDark ? AppTheme.colorDarkPrimary : const Color(0xFF2D2D2D))
                        : (isDark ? AppTheme.colorDarkSurface : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: message.isUser 
                              ? Colors.white 
                              : (isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatTime(message.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: message.isUser 
                                  ? Colors.white.withOpacity(0.6) 
                                  : const Color(0xFF999999),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.touch_app_outlined,
                            size: 11,
                            color: message.isUser 
                                ? Colors.white.withOpacity(0.3) 
                                : const Color(0xFFCCCCCC),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Hold to delete',
                            style: TextStyle(
                              fontSize: 10,
                              color: message.isUser 
                                  ? Colors.white.withOpacity(0.3) 
                                  : const Color(0xFFCCCCCC),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.isUser) ...[
              const SizedBox(width: 8),
              Hero(
                tag: 'user_avatar_$index',
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFE0E0E0),
                  child: const Icon(Icons.person, color: Color(0xFF666666), size: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF4CAF50),
            child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.colorDarkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, double value, child) {
        final delay = index * 0.2;
        final animValue = (value - delay).clamp(0.0, 1.0);
        return Transform.translate(
          offset: Offset(0, -5 * (animValue < 0.5 ? animValue * 2 : (1 - animValue) * 2)),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildMessageInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.colorDarkSurface : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D)),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF999999)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF4CAF50)),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendMessage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCancerSpecificFallback(String cancerType, String userMessage) {
    switch (cancerType) {
      case 'BREAST CANCER':
        return 'NUTRITION GUIDANCE FOR BREAST CANCER\n\n'
            'Here are evidence-based food recommendations:\n\n'
            'Recommended Foods:\n'
            '• Cruciferous vegetables (broccoli, cauliflower, Brussels sprouts) - contain sulforaphane compounds\n'
            '• Berries (blueberries, strawberries, raspberries) - rich in antioxidants and vitamin C\n'
            '• Fatty fish (salmon, mackerel, sardines) - provide omega-3 fatty acids\n'
            '• Walnuts and flaxseeds - support hormonal balance\n'
            '• Green tea - contains beneficial EGCG compounds\n'
            '• Dark leafy greens (spinach, kale) - high in folate and fiber\n'
            '• Soy foods (tofu, edamame) - provide protective isoflavones\n'
            '• Turmeric - anti-inflammatory properties\n\n'
            'These foods support immune function and provide anti-inflammatory benefits. Please consult your oncology team for personalized dietary guidance.';
      
      case 'LUNG CANCER':
        return 'NUTRITION GUIDANCE FOR LUNG CANCER\n\n'
            'Recommended therapeutic foods:\n\n'
            'Key Recommendations:\n'
            '• Citrus fruits (oranges, grapefruits) - vitamin C supports immune health\n'
            '• Carrots and sweet potatoes - beta-carotene for respiratory health\n'
            '• Turmeric - contains anti-inflammatory curcumin\n'
            '• Apples - flavonoids protect cellular health\n'
            '• Spinach and Swiss chard - rich in folate and antioxidants\n'
            '• Lentils and beans - provide plant-based protein and fiber\n'
            '• Green tea - antioxidant properties\n'
            '• Tomatoes - lycopene benefits\n\n'
            'Focus on foods that support respiratory function and reduce inflammation. Consult your healthcare provider for individualized nutrition planning.';
      
      case 'COLORECTAL CANCER':
        return 'NUTRITION GUIDANCE FOR COLORECTAL CANCER\n\n'
            'Diet plays a crucial role in colon health:\n\n'
            'Recommended Foods:\n'
            '• Whole grains (brown rice, quinoa, oats) - excellent fiber sources\n'
            '• Legumes (beans, lentils, chickpeas) - provide folate and resistant starch\n'
            '• Cruciferous vegetables (broccoli, cabbage) - contain protective compounds\n'
            '• Fatty fish - omega-3 reduces inflammation\n'
            '• Dark leafy greens - rich in magnesium and fiber\n'
            '• Berries - antioxidants support gut health\n'
            '• Garlic and onions - prebiotic benefits\n'
            '• Probiotic yogurt - supports gut microbiome\n\n'
            'Adequate fiber and hydration are essential. Work closely with your dietitian to optimize your nutrition plan.';
      
      case 'PROSTATE CANCER':
        return 'NUTRITION GUIDANCE FOR PROSTATE CANCER\n\n'
            'Evidence-based dietary recommendations:\n\n'
            'Beneficial Foods:\n'
            '• Tomatoes and tomato products - rich in lycopene\n'
            '• Cruciferous vegetables (broccoli, cauliflower) - contain protective phytochemicals\n'
            '• Fatty fish (salmon, tuna) - omega-3 fatty acids\n'
            '• Nuts and seeds (Brazil nuts, pumpkin seeds) - selenium and zinc\n'
            '• Green tea - contains beneficial polyphenols\n'
            '• Pomegranate juice - rich in antioxidants\n'
            '• Soy products - protective isoflavones\n'
            '• Berries - vitamin C and antioxidants\n\n'
            'These foods support prostate health through various mechanisms. Please discuss dietary changes with your urologist or oncologist.';
      
      default:
        return 'GENERAL CANCER NUTRITION GUIDANCE\n\n'
            'Evidence-based dietary recommendations:\n\n'
            'Core Food Groups:\n'
            '• Vegetables - especially cruciferous and leafy greens (5+ servings daily)\n'
            '• Fruits - berries, citrus, and colorful varieties (3-4 servings daily)\n'
            '• Lean proteins - fish, poultry, legumes, eggs (at each meal)\n'
            '• Whole grains - quinoa, brown rice, oats (3-4 servings daily)\n'
            '• Healthy fats - nuts, seeds, avocado, olive oil (in moderation)\n'
            '• Beverages - green tea, turmeric golden milk (daily)\n\n'
            'Foods to Limit:\n'
            'Processed meats, refined sugars, alcohol, excessive red meat\n\n'
            'Please consult your healthcare team for personalized nutrition guidance.';
    }
  }

  String? _detectCancerType(String msgLower) {
    if (msgLower.contains('breast')) return 'BREAST CANCER';
    if (msgLower.contains('lung')) return 'LUNG CANCER';
    if (msgLower.contains('colon') || msgLower.contains('colorectal') || msgLower.contains('bowel')) return 'COLORECTAL CANCER';
    if (msgLower.contains('prostate')) return 'PROSTATE CANCER';
    if (msgLower.contains('throat') || msgLower.contains('esophag') || msgLower.contains('oral')) return 'THROAT/ESOPHAGEAL CANCER';
    if (msgLower.contains('stomach') || msgLower.contains('gastric')) return 'GASTRIC CANCER';
    if (msgLower.contains('liver')) return 'LIVER CANCER';
    if (msgLower.contains('pancrea')) return 'PANCREATIC CANCER';
    if (msgLower.contains('ovarian') || msgLower.contains('ovary')) return 'OVARIAN CANCER';
    if (msgLower.contains('cervical') || msgLower.contains('cervix')) return 'CERVICAL CANCER';
    if (msgLower.contains('kidney') || msgLower.contains('renal')) return 'KIDNEY CANCER';
    if (msgLower.contains('bladder')) return 'BLADDER CANCER';
    if (msgLower.contains('skin') || msgLower.contains('melanoma')) return 'SKIN CANCER';
    if (msgLower.contains('thyroid')) return 'THYROID CANCER';
    if (msgLower.contains('leukemia') || msgLower.contains('blood cancer')) return 'LEUKEMIA';
    if (msgLower.contains('lymphoma')) return 'LYMPHOMA';
    return null;
  }

  String _cleanMarkdown(String text) {
    // Remove markdown bold (**text** or __text__)
    text = text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'\1');
    text = text.replaceAll(RegExp(r'__([^_]+)__'), r'\1');
    
    // Remove markdown italic (*text* or _text_)
    text = text.replaceAll(RegExp(r'(?<!\*)\*(?!\*)([^*]+)\*(?!\*)'), r'\1');
    text = text.replaceAll(RegExp(r'(?<!_)_(?!_)([^_]+)_(?!_)'), r'\1');
    
    // Remove markdown headers (## or ###)
    text = text.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    
    return text;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    // Show actual time for messages less than 1 minute old
    if (diff.inSeconds < 60) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    
    // For older messages, show date and time
    if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    }
    
    return '${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}


