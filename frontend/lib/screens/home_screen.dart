import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../routes/app_routes.dart';
import '../models/intake_data.dart';
import '../models/dashboard_data.dart';
import '../services/dashboard_service.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../utils/app_theme.dart';
import 'intake/age_picker_screen.dart';
import 'profile_screen.dart';
import 'diet_recommendation_screen.dart';
import 'chatbot_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final GlobalKey<_HomeTabState> _homeTabKey = GlobalKey<_HomeTabState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(key: _homeTabKey),
      const DietRecommendationScreen(),
      const ChatbotScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            // Reload profile photo when returning to home tab from profile tab
            if (index == 0 && _homeTabKey.currentState != null) {
              _homeTabKey.currentState!._loadUserName();
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppTheme.colorDarkSurface : Colors.white,
          selectedItemColor: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF2D2D2D),
          unselectedItemColor: isDark ? AppTheme.colorDarkSubtext : const Color(0xFFBDBDBD),
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: localizations.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: localizations.navDietPlan,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline_rounded),
              activeIcon: Icon(Icons.chat_bubble_rounded),
              label: localizations.navChatbot,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: localizations.navProfile,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  DashboardData? _dashboardData;
  bool _isLoading = true;
  String? _error;
  String _userName = 'User';
  String? _profileImagePath;
  List<String> _suggestions = [];
  List<Map<String, dynamic>> _videos = [];
  bool _loadingSuggestions = false;
  bool _loadingVideos = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _loadUserName();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Detect language changes and reload videos
    final languageProvider = Provider.of<LanguageProvider>(context);
    final newLanguage = languageProvider.locale.languageCode;
    
    if (_currentLanguage != newLanguage && _dashboardData != null) {
      _currentLanguage = newLanguage;
      print('🌐 Language changed to: $newLanguage, reloading videos...');
      if (_dashboardData!.profile.cancerType.isNotEmpty) {
        _loadVideos(_dashboardData!.profile.cancerType);
      }
    } else if (_currentLanguage != newLanguage) {
      _currentLanguage = newLanguage;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload profile photo when app resumes
      _loadUserName();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? 'User';
    final imagePath = prefs.getString('profile_image');
    print('📸 Loading profile: name=$name, imagePath=$imagePath');
    if (mounted) {
      setState(() {
        _userName = name.split(' ').first; // Get first name only
        _profileImagePath = imagePath;
      });
      print('✅ Profile updated: _userName=$_userName, _profileImagePath=$_profileImagePath');
    }
  }

  Future<void> _loadDashboardData({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('📱 HomeScreen: Loading dashboard data...');
      final data = await DashboardService.getDashboardData(forceRefresh: forceRefresh);
      print('✅ HomeScreen: Dashboard data loaded successfully');
      
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
          _error = null;
        });
        _animationController.forward();
        
        // Load suggestions and videos based on cancer type
        if (data.profile.cancerType.isNotEmpty) {
          _loadSuggestions(data.profile.cancerType);
          _loadVideos(data.profile.cancerType);
        }
      }
    } catch (e) {
      print('❌ HomeScreen: Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSuggestions(String cancerType) async {
    if (_loadingSuggestions) return;
    
    setState(() {
      _loadingSuggestions = true;
    });

    try {
      print('🔍 Loading suggestions for cancer type: $cancerType');
      
      // Use Gemini API to generate nutrition suggestions
      final prompt = '''Generate 3 concise nutrition suggestions for a patient with $cancerType. 
Each suggestion should be:
- Actionable and specific
- Evidence-based
- Related to diet and nutrition
- Maximum 10 words each

Format as a simple list with one suggestion per line, no numbering or bullets.''';

      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=${GeminiService.apiKey}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final List<String> suggestions = text
            .split('\n')
            .where((dynamic s) => s.toString().trim().isNotEmpty)
            .map((dynamic s) => s.toString().trim())
            .take(3)
            .toList()
            .cast<String>();
        
        if (mounted) {
          setState(() {
            _suggestions = suggestions;
            _loadingSuggestions = false;
          });
        }
        print('✅ Loaded ${suggestions.length} suggestions');
      } else {
        print('❌ Failed to load suggestions: ${response.statusCode}');
        setState(() {
          _loadingSuggestions = false;
        });
      }
    } catch (e) {
      print('❌ Error loading suggestions: $e');
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _loadVideos(String cancerType) async {
    if (_loadingVideos) return;
    
    setState(() {
      _loadingVideos = true;
    });

    try {
      print('🎥 Loading videos for cancer type: $cancerType');
      
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ No auth token found');
        return;
      }

      // Get user's selected language
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString('language_code') ?? 'en';
      print('🌐 Language preference: $languageCode');

      // Fetch cancer-specific videos from backend API with language parameter
      final response = await http.get(
        Uri.parse('http://localhost:5000/api/videos/${Uri.encodeComponent(cancerType)}?language=$languageCode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Video API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['videos'] != null) {
          final videos = (data['videos'] as List).map((video) => {
            'title': video['title'] ?? 'Educational Video',
            'description': video['description'] ?? '',
            'category': video['category'] ?? 'Education',
            'videoId': video['videoId'] ?? '',
            'thumbnail': video['thumbnail'] ?? '',
            'url': video['url'] ?? '',
          }).toList();
          
          print('📹 Loaded ${videos.length} videos for $cancerType');
          for (var video in videos) {
            print('   - ${video['title']}');
          }
          
          if (mounted) {
            setState(() {
              _videos = videos;
              _loadingVideos = false;
            });
          }
        } else {
          print('❌ Invalid video response format');
          _loadFallbackVideos(cancerType);
        }
      } else {
        print('❌ Video API error: ${response.statusCode}');
        _loadFallbackVideos(cancerType);
      }
    } catch (e) {
      print('❌ Error loading videos: $e');
      _loadFallbackVideos(cancerType);
    }
  }

  void _loadFallbackVideos(String cancerType) {
    print('🔄 Using fallback videos for $cancerType');
    final videos = [
      {
        'title': 'Nutrition for Cancer Patients',
        'description': 'Expert advice on diet during cancer treatment',
        'category': 'Nutrition',
        'videoId': 'dQw4w9WgXcQ',
        'thumbnail': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/mqdefault.jpg',
        'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      },
      {
        'title': 'Cancer Fighting Foods',
        'description': 'Foods that help fight cancer',
        'category': 'Nutrition',
        'videoId': 'jNQXAC9IVRw',
        'thumbnail': 'https://i.ytimg.com/vi/jNQXAC9IVRw/mqdefault.jpg',
        'url': 'https://www.youtube.com/watch?v=jNQXAC9IVRw',
      },
      {
        'title': 'Managing Treatment Side Effects',
        'description': 'Nutrition tips for managing cancer treatment side effects',
        'category': 'Treatment',
        'videoId': 'M7lc1UVf-VE',
        'thumbnail': 'https://i.ytimg.com/vi/M7lc1UVf-VE/mqdefault.jpg',
        'url': 'https://www.youtube.com/watch?v=M7lc1UVf-VE',
      },
    ];
    
    if (mounted) {
      setState(() {
        _videos = videos;
        _loadingVideos = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary,
              ),
            )
          : _error != null
              ? _buildErrorState()
              : SafeArea(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: RefreshIndicator(
                        onRefresh: () => _loadDashboardData(forceRefresh: true),
                        color: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Modern Header with username
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: _profileImagePath == null
                                                ? (isDark ? AppTheme.colorDarkPrimary : const Color(0xFF2D2D2D))
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                            image: _profileImagePath != null
                                                ? DecorationImage(
                                                    image: FileImage(File(_profileImagePath!)),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: _profileImagePath == null
                                              ? Icon(
                                                  Icons.person_outline,
                                                  color: isDark ? AppTheme.colorDarkBackground : Colors.white,
                                                  size: 24,
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hello',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark ? AppTheme.colorDarkSubtext : const Color(0xFF666666),
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                            Text(
                                              _userName,
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: isDark ? AppTheme.colorDarkText : Colors.grey.shade800,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Suggestions Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Suggestions',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                                          ),
                                        ),
                                        if (_dashboardData?.profile.cancerType != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isDark ? AppTheme.colorDarkPrimary.withOpacity(0.2) : const Color(0xFFE8F5E9),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              _dashboardData!.profile.cancerType,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF4CAF50),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildSuggestionsBar(isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Recommended Foods Section (if available)
                              if (_dashboardData?.recommendations.isNotEmpty == true) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            AppLocalizations.of(context)!.recommendedForYou,
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                (context.findAncestorStateOfType<_HomeScreenState>() as _HomeScreenState)._selectedIndex = 1;
                                              });
                                            },
                                            child: Text(
                                              AppLocalizations.of(context)!.homeSeeAll,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? AppTheme.colorDarkPrimary : Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 140,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: (_dashboardData!.recommendations.length > 5) 
                                              ? 5 
                                              : _dashboardData!.recommendations.length,
                                          itemBuilder: (context, index) {
                                            final food = _dashboardData!.recommendations[index];
                                            return _buildFoodCard(food, isDark);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],

                              // Videos Section
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.play_circle_outline,
                                          color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF2D2D2D),
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Educational Videos',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildVideosSection(isDark),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // CTA Button
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AgePickerScreen(
                                            intakeData: IntakeData(),
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF2D2D2D),
                                      foregroundColor: isDark ? AppTheme.colorDarkBackground : Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      AppLocalizations.of(context)!.getPersonalizedRecommendations,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorState() {
    final bool isNetworkError = _error?.contains('SocketException') == true ||
                                 _error?.contains('Connection') == true ||
                                 _error?.contains('timeout') == true ||
                                 _error?.contains('connect') == true;
    
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => _loadDashboardData(forceRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height - 100,
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isNetworkError ? Icons.cloud_off : Icons.error_outline,
                  size: 80,
                  color: isNetworkError ? Colors.orange.shade300 : Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                Text(
                  isNetworkError ? 'Connection Issue' : AppLocalizations.of(context)!.unableToLoadDashboard,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isNetworkError 
                    ? 'Unable to connect to the server.\nPlease check your internet connection.' 
                    : _error?.replaceAll('Exception: ', '') ?? AppLocalizations.of(context)!.pleaseTryAgain,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _loadDashboardData(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2A694),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AgePickerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(AppLocalizations.of(context)!.getRecommendations),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFF2A694),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pull down to refresh or check your internet connection',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsBar(bool isDark) {
    if (_loadingSuggestions) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary,
          ),
        ),
      );
    }

    if (_suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFFFFC107),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete your profile to get personalized nutrition suggestions',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _suggestions.asMap().entries.map((entry) {
        final index = entry.key;
        final suggestion = entry.value;
        return Padding(
          padding: EdgeInsets.only(bottom: index < _suggestions.length - 1 ? 12 : 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.colorDarkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.colorDarkPrimary.withOpacity(0.2) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
                    color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF4CAF50),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVideosSection(bool isDark) {
    if (_loadingVideos) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary,
          ),
        ),
      );
    }

    if (_videos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.video_library_outlined,
              color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFFFF5252),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Complete your profile to get educational video recommendations',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _videos.asMap().entries.map((entry) {
        final index = entry.key;
        final video = entry.value;
        final categoryColor = _getVideoCategoryColor(video['category'], isDark);
        
        return Padding(
          padding: EdgeInsets.only(bottom: index < _videos.length - 1 ? 12 : 0),
          child: GestureDetector(
            onTap: () async {
              final url = video['url'];
              print('🎬 Video clicked: ${video['title']}');
              print('🔗 URL: $url');
              if (url != null) {
                try {
                  final uri = Uri.parse(url);
                  print('📱 Launching: $uri');
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                  print('✅ Video launched successfully');
                } catch (e) {
                  print('❌ Error launching URL: $e');
                }
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.colorDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    // Video thumbnail
                    Stack(
                      children: [
                        Image.network(
                          video['thumbnail'] ?? '',
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) {
                              print('✅ Thumbnail loaded: ${video['thumbnail']}');
                              return child;
                            }
                            return Container(
                              height: 140,
                              color: Colors.grey.shade300,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('❌ Thumbnail error for ${video['thumbnail']}: $error');
                            return Container(
                              height: 140,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    categoryColor.withOpacity(0.3),
                                    categoryColor.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Video info
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  video['category'],
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: categoryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            video['title'],
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            video['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade600,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getVideoCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'nutrition':
        return isDark ? const Color(0xFF66BB6A) : const Color(0xFF4CAF50);
      case 'treatment':
        return isDark ? const Color(0xFF42A5F5) : const Color(0xFF2196F3);
      case 'motivation':
        return isDark ? const Color(0xFFFF7043) : const Color(0xFFFF5722);
      default:
        return isDark ? AppTheme.colorDarkPrimary : AppTheme.colorPrimary;
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'water_drop':
        return Icons.water_drop;
      case 'bedtime':
        return Icons.bedtime;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_dining':
        return Icons.local_dining;
      case 'eco':
        return Icons.eco;
      case 'restaurant_menu':
        return Icons.restaurant_menu;
      case 'favorite':
        return Icons.favorite;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'directions_walk':
        return Icons.directions_walk;
      default:
        return Icons.info;
    }
  }

  Widget _buildFoodCard(FoodRecommendationSimple food, bool isDark) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 400),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image or Icon
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: food.imageUrl != null && food.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.network(
                          food.imageUrl!,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.restaurant,
                              size: 40,
                              color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF4CAF50),
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        size: 40,
                        color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF4CAF50),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      food.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 14,
                          color: Color(0xFFFFB800),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${(food.score * 10).toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
