import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../widgets/ui_components.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_localizations.dart';
import 'intake/age_picker_screen.dart';
import 'login_screen.dart';
import 'user_history_screen.dart';
import 'meal_timer_screen.dart';
import '../models/intake_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _profileImagePath;
  String _userName = 'Add Name';
  String _userEmail = 'Add Email';
  
  // Notification settings
  bool _mealNotifications = true;
  bool _tipsNotifications = true;
  bool _remindersNotifications = true;
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image');
      _userName = prefs.getString('user_name') ?? 'Add Name';
      _userEmail = prefs.getString('user_email') ?? 'Add Email';
      
      // Load notification settings
      _mealNotifications = prefs.getBool('meal_notifications') ?? true;
      _tipsNotifications = prefs.getBool('tips_notifications') ?? true;
      _remindersNotifications = prefs.getBool('reminders_notifications') ?? true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', image.path);
        setState(() {
          _profileImagePath = image.path;
        });
        
        // Log to history
        await HistoryLogger.logEvent(
          type: 'profile_update',
          title: 'Profile Photo Updated',
          description: 'Changed profile photo',
        );
        
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(localizations.profilePhotoUpdated),
                ],
              ),
              backgroundColor: AppTheme.colorSuccess,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToPickImage}: $e'),
            backgroundColor: AppTheme.colorDanger,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    final localizations = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.settingsChoosePhoto,
              style: AppTheme.h2,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor(context)),
              title: Text(localizations.settingsCamera),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryColor(context)),
              title: Text(localizations.settingsGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.colorDanger),
                title: Text(localizations.settingsRemovePhoto),
                onTap: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('profile_image');
                  setState(() {
                    _profileImagePath = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName() async {
    final localizations = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _userName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.profileEditName),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: localizations.profileName,
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(localizations.save),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final oldName = _userName;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', result);
      setState(() {
        _userName = result;
      });
      
      // Log history
      await HistoryLogger.logEvent(
        type: 'name_update',
        title: 'Name Updated',
        description: 'Changed name from "$oldName" to "$result"',
      );
    }
  }

  Future<void> _logout() async {
    final localizations = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.logoutConfirmTitle),
        content: Text(localizations.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(localizations.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(localizations.logout, style: TextStyle(color: AppTheme.colorDanger)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localizations = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    localizations.profileTitle,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.colorDarkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22),
                      onPressed: () {
                        _showSettingsBottomSheet();
                      },
                      color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Profile Photo Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.colorDarkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showImageSourceDialog,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark ? AppTheme.colorDarkPrimary : const Color(0xFF2D2D2D),
                              image: _profileImagePath != null
                                  ? DecorationImage(
                                      image: FileImage(File(_profileImagePath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _profileImagePath == null
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _showImageSourceDialog,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: _editName,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _userName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.edit,
                            size: 18,
                            color: Color(0xFF666666),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userEmail,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Options
              _buildOptionCard(
                icon: Icons.history,
                title: 'User History',
                subtitle: 'View your activity logs and changes',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              _buildOptionCard(
                icon: Icons.medical_information_outlined,
                title: localizations.profileHealthInformation,
                subtitle: localizations.profileHealthInformationDesc,
                onTap: () {
                  _showHealthInfoDialog();
                },
              ),
              const SizedBox(height: 12),

              _buildOptionCard(
                icon: Icons.notifications_outlined,
                title: localizations.profileNotifications,
                subtitle: localizations.profileNotificationsDesc,
                onTap: () {
                  _showNotificationSettings();
                },
              ),
              const SizedBox(height: 12),

              _buildOptionCard(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Toggle dark theme for the app',
                onTap: () {},
                trailing: Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) async {
                        await themeProvider.toggleTheme();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                value ? 'Dark mode enabled' : 'Light mode enabled',
                              ),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      activeColor: const Color(0xFF4CAF50),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              _buildOptionCard(
                icon: Icons.help_outline,
                title: localizations.profileHelpSupport,
                subtitle: localizations.profileHelpSupportDesc,
                onTap: () {
                  _showHelpDialog();
                },
              ),
              const SizedBox(height: 12),

              _buildOptionCard(
                icon: Icons.info_outline,
                title: localizations.profileAboutApp,
                subtitle: localizations.profileAboutAppDesc,
                onTap: () {
                  _showAboutDialog();
                },
              ),
              const SizedBox(height: 24),

              // Logout Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(localizations.logout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D2D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: isDark ? AppTheme.colorDarkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.colorDarkBackground : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right,
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey.shade400,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsBottomSheet() {
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.colorDarkSurface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              localizations.settingsTitle,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.language,
                color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
              ),
              title: Text(
                localizations.profileLanguage,
                style: TextStyle(
                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                ),
              ),
              subtitle: Text(
                _getLanguageName(currentLanguage),
                style: TextStyle(
                  color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[400],
              ),
              onTap: () {
                Navigator.pop(context);
                _showLanguageDialog();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.alarm,
                color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
              ),
              title: Text(
                'Meal Reminders',
                style: TextStyle(
                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                ),
              ),
              subtitle: Text(
                'Set notification times',
                style: TextStyle(
                  color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[400],
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MealTimerScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    final languages = {
      'en': 'English',
      'hi': 'हिन्दी (Hindi)',
      'kn': 'ಕನ್ನಡ (Kannada)',
      'ta': 'தமிழ் (Tamil)',
      'te': 'తెలుగు (Telugu)',
      'ml': 'മലയാളം (Malayalam)',
      'mr': 'मराठी (Marathi)',
      'gu': 'ગુજરાતી (Gujarati)',
      'bn': 'বাংলা (Bengali)',
      'pa': 'ਪੰਜਾਬੀ (Punjabi)',
    };
    return languages[code] ?? 'English';
  }

  void _showLanguageDialog() {
    final localizations = AppLocalizations.of(context)!;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentLanguage = languageProvider.locale.languageCode;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.settingsLanguageSelect),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('en', 'English', currentLanguage),
              _buildLanguageOption('hi', 'हिन्दी (Hindi)', currentLanguage),
              _buildLanguageOption('kn', 'ಕನ್ನಡ (Kannada)', currentLanguage),
              _buildLanguageOption('ta', 'தமிழ் (Tamil)', currentLanguage),
              _buildLanguageOption('te', 'తెలుగు (Telugu)', currentLanguage),
              _buildLanguageOption('ml', 'മലയാളം (Malayalam)', currentLanguage),
              _buildLanguageOption('mr', 'मराठी (Marathi)', currentLanguage),
              _buildLanguageOption('gu', 'ગુજરાતી (Gujarati)', currentLanguage),
              _buildLanguageOption('bn', 'বাংলা (Bengali)', currentLanguage),
              _buildLanguageOption('pa', 'ਪੰਜਾਬੀ (Punjabi)', currentLanguage),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String code, String name, String currentLanguage) {
    final isSelected = code == currentLanguage;
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.colorAccent.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.language,
          color: isSelected ? AppTheme.colorAccent : Colors.grey.shade600,
          size: 20,
        ),
      ),
      title: Text(name),
      trailing: isSelected 
          ? const Icon(Icons.check_circle, color: AppTheme.colorSuccess)
          : null,
      tileColor: isSelected ? AppTheme.colorSuccess.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () async {
        final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
        await languageProvider.setLanguage(code);
        
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.profileLanguageUpdated),
                ],
              ),
              backgroundColor: AppTheme.colorSuccess,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  void _showHealthInfoDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.profileHealthInfo),
        content: Text(localizations.profileHealthInfoDesc),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgePickerScreen(
                    intakeData: IntakeData(),
                  ),
                ),
              ).then((_) async {
                // Log history when returning from health update
                await HistoryLogger.logEvent(
                  type: 'health_update',
                  title: 'Health Information Updated',
                  description: 'Updated health assessment and preferences',
                );
              });
            },
            child: Text(localizations.profileUpdateNow),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.colorDarkSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.colorDarkBorder : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                localizations.settingsNotifications,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppTheme.colorDarkText : const Color(0xFF2D2D2D),
                ),
              ),
              const SizedBox(height: 24),
              
              // Meal Notifications
              SwitchListTile(
                title: Text(
                  'Meal Notifications',
                  style: TextStyle(
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Receive reminders for breakfast, lunch, and dinner',
                  style: TextStyle(
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                  ),
                ),
                value: _mealNotifications,
                activeColor: const Color(0xFF4CAF50),
                onChanged: (value) async {
                  setModalState(() {
                    _mealNotifications = value;
                  });
                  setState(() {
                    _mealNotifications = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('meal_notifications', value);
                  
                  // Cancel or schedule meal notifications based on saved times
                  final notificationService = NotificationService();
                  if (value) {
                    // Check if individual meal times are enabled
                    final breakfastEnabled = prefs.getBool('breakfast_enabled') ?? true;
                    final lunchEnabled = prefs.getBool('lunch_enabled') ?? true;
                    final dinnerEnabled = prefs.getBool('dinner_enabled') ?? true;
                    
                    if (breakfastEnabled || lunchEnabled || dinnerEnabled) {
                      await notificationService.scheduleMealReminders();
                    }
                  } else {
                    // Cancel all meal notifications (IDs 1-6)
                    for (int i = 1; i <= 6; i++) {
                      await notificationService.cancelNotification(i);
                    }
                  }
                },
              ),
              
              // Tips Notifications
              SwitchListTile(
                title: Text(
                  'Health Tips',
                  style: TextStyle(
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Get helpful health and nutrition tips',
                  style: TextStyle(
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                  ),
                ),
                value: _tipsNotifications,
                activeColor: const Color(0xFF4CAF50),
                onChanged: (value) async {
                  setModalState(() {
                    _tipsNotifications = value;
                  });
                  setState(() {
                    _tipsNotifications = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('tips_notifications', value);
                  
                  final notificationService = NotificationService();
                  if (value) {
                    await notificationService.scheduleHealthTipNotification();
                  } else {
                    await notificationService.cancelNotification(20);
                  }
                },
              ),
              
              // Reminders Notifications
              SwitchListTile(
                title: Text(
                  'General Reminders',
                  style: TextStyle(
                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Stay on track with wellness reminders',
                  style: TextStyle(
                    color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                  ),
                ),
                value: _remindersNotifications,
                activeColor: const Color(0xFF4CAF50),
                onChanged: (value) async {
                  setModalState(() {
                    _remindersNotifications = value;
                  });
                  setState(() {
                    _remindersNotifications = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('reminders_notifications', value);
                  
                  final notificationService = NotificationService();
                  if (value) {
                    await notificationService.scheduleDailyProgressReminder();
                  } else {
                    await notificationService.cancelNotification(10);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFF4CAF50),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(localizations.helpTitle),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.helpFaqTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                question: localizations.helpQuestion1,
                answer: 'A: Tap on Health Information from your profile to update your health details.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                question: localizations.helpQuestion2,
                answer: localizations.helpAnswer2,
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                question: 'Q: How do I save foods to my diet plan?',
                answer: 'A: Browse recommendations and tap the bookmark icon to save foods to your personalized diet plan.',
              ),
              const SizedBox(height: 12),
              _buildHelpItem(
                question: 'Q: How do notifications work?',
                answer: 'A: Enable notifications in Profile settings to receive meal reminders, progress updates, and health tips.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem({required String question, required String answer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
  void _showAboutDialog() {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_hospital,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context)!.appTitle),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              localizations.aboutVersion,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(localizations.aboutDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }
}


