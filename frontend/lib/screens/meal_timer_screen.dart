import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_theme.dart';
import '../providers/theme_provider.dart';
import '../l10n/app_localizations.dart';

class MealTimerScreen extends StatefulWidget {
  const MealTimerScreen({Key? key}) : super(key: key);

  @override
  State<MealTimerScreen> createState() => _MealTimerScreenState();
}

class _MealTimerScreenState extends State<MealTimerScreen> {
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 13, minute: 0);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 19, minute: 0);
  
  bool _breakfastEnabled = true;
  bool _lunchEnabled = true;
  bool _dinnerEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _loadMealTimes();
  }
  
  Future<void> _loadMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Load breakfast
      _breakfastEnabled = prefs.getBool('breakfast_enabled') ?? true;
      final breakfastHour = prefs.getInt('breakfast_hour') ?? 8;
      final breakfastMinute = prefs.getInt('breakfast_minute') ?? 0;
      _breakfastTime = TimeOfDay(hour: breakfastHour, minute: breakfastMinute);
      
      // Load lunch
      _lunchEnabled = prefs.getBool('lunch_enabled') ?? true;
      final lunchHour = prefs.getInt('lunch_hour') ?? 13;
      final lunchMinute = prefs.getInt('lunch_minute') ?? 0;
      _lunchTime = TimeOfDay(hour: lunchHour, minute: lunchMinute);
      
      // Load dinner
      _dinnerEnabled = prefs.getBool('dinner_enabled') ?? true;
      final dinnerHour = prefs.getInt('dinner_hour') ?? 19;
      final dinnerMinute = prefs.getInt('dinner_minute') ?? 0;
      _dinnerTime = TimeOfDay(hour: dinnerHour, minute: dinnerMinute);
    });
  }
  
  Future<void> _saveMealTimes() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save breakfast preferences
    await prefs.setBool('breakfast_enabled', _breakfastEnabled);
    await prefs.setInt('breakfast_hour', _breakfastTime.hour);
    await prefs.setInt('breakfast_minute', _breakfastTime.minute);
    
    // Save lunch preferences
    await prefs.setBool('lunch_enabled', _lunchEnabled);
    await prefs.setInt('lunch_hour', _lunchTime.hour);
    await prefs.setInt('lunch_minute', _lunchTime.minute);
    
    // Save dinner preferences
    await prefs.setBool('dinner_enabled', _dinnerEnabled);
    await prefs.setInt('dinner_hour', _dinnerTime.hour);
    await prefs.setInt('dinner_minute', _dinnerTime.minute);
    
    // If any meal is enabled, ensure meal notifications are enabled
    if (_breakfastEnabled || _lunchEnabled || _dinnerEnabled) {
      await prefs.setBool('meal_notifications', true);
    }
    
    // Note: This only saves the preferences. Actual notification scheduling
    // should be handled by a background service or notification manager.
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.mealTimesSaved),
            ],
          ),
          backgroundColor: AppTheme.colorSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }
  
  Future<void> _selectTime(BuildContext context, String mealType) async {
    TimeOfDay initialTime;
    switch (mealType) {
      case 'breakfast':
        initialTime = _breakfastTime;
        break;
      case 'lunch':
        initialTime = _lunchTime;
        break;
      case 'dinner':
        initialTime = _dinnerTime;
        break;
      default:
        initialTime = const TimeOfDay(hour: 12, minute: 0);
    }
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDark = themeProvider.isDarkMode;
        
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppTheme.colorPrimary,
                    onPrimary: Colors.white,
                    surface: AppTheme.colorDarkSurface,
                    onSurface: AppTheme.colorDarkText,
                  ),
                  dialogBackgroundColor: AppTheme.colorDarkSurface,
                  timePickerTheme: TimePickerThemeData(
                    backgroundColor: AppTheme.colorDarkSurface,
                    hourMinuteTextColor: AppTheme.colorDarkText,
                    dayPeriodTextColor: AppTheme.colorDarkText,
                    dialHandColor: AppTheme.colorPrimary,
                    dialTextColor: AppTheme.colorDarkText,
                    helpTextStyle: TextStyle(color: AppTheme.colorDarkText),
                    hourMinuteColor: AppTheme.colorDarkBackground,
                    dayPeriodColor: AppTheme.colorDarkBackground,
                  ),
                )
              : ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(
                    primary: AppTheme.colorPrimary,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: AppTheme.colorText,
                  ),
                ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        switch (mealType) {
          case 'breakfast':
            _breakfastTime = picked;
            break;
          case 'lunch':
            _lunchTime = picked;
            break;
          case 'dinner':
            _dinnerTime = picked;
            break;
        }
      });
      await _saveMealTimes();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Meal Reminders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? AppTheme.colorDarkSurface 
                              : AppTheme.colorPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.colorPrimary.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppTheme.colorPrimary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Set your preferred meal times to receive timely reminders',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Breakfast
                      _buildMealTimeCard(
                        context,
                        'Breakfast',
                        Icons.wb_sunny,
                        _breakfastTime,
                        _breakfastEnabled,
                        'breakfast',
                        isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Lunch
                      _buildMealTimeCard(
                        context,
                        'Lunch',
                        Icons.restaurant,
                        _lunchTime,
                        _lunchEnabled,
                        'lunch',
                        isDark,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Dinner
                      _buildMealTimeCard(
                        context,
                        'Dinner',
                        Icons.nightlight_round,
                        _dinnerTime,
                        _dinnerEnabled,
                        'dinner',
                        isDark,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Note about other notifications
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.colorDarkSurface : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.colorDarkBorder : Colors.grey[200]!,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_active,
                                  color: AppTheme.colorPrimary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Other Notifications',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'You will also receive health tips and reminders at random times throughout the day to help you on your wellness journey.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.colorDarkSubtext : Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMealTimeCard(
    BuildContext context,
    String mealName,
    IconData icon,
    TimeOfDay time,
    bool enabled,
    String mealType,
    bool isDark,
  ) {
    // Get the properly formatted time based on device's 12/24-hour preference
    final formattedTime = time.format(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.colorDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.colorDarkBorder : Colors.grey[200]!,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.colorPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.colorPrimary,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Meal info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mealName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.colorDarkText : AppTheme.colorText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    enabled ? formattedTime : 'Disabled',
                    style: TextStyle(
                      fontSize: 15,
                      color: enabled 
                          ? AppTheme.colorPrimary 
                          : (isDark ? AppTheme.colorDarkSubtext : Colors.grey[500]),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Time picker button
            if (enabled)
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.colorPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.access_time,
                    color: AppTheme.colorPrimary,
                    size: 24,
                  ),
                  onPressed: () => _selectTime(context, mealType),
                  tooltip: 'Change time',
                ),
              ),
            
            const SizedBox(width: 8),
            
            // Toggle switch
            Switch(
              value: enabled,
              activeColor: const Color(0xFF4CAF50),
              inactiveThumbColor: isDark ? AppTheme.colorDarkSubtext : Colors.grey[400],
              inactiveTrackColor: isDark ? AppTheme.colorDarkBackground : Colors.grey[300],
              onChanged: (value) async {
                setState(() {
                  switch (mealType) {
                    case 'breakfast':
                      _breakfastEnabled = value;
                      break;
                    case 'lunch':
                      _lunchEnabled = value;
                      break;
                    case 'dinner':
                      _dinnerEnabled = value;
                      break;
                  }
                });
                await _saveMealTimes();
              },
            ),
          ],
        ),
      ),
    );
  }
}
