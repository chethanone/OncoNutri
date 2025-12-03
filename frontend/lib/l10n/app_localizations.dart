import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('gu'),
    Locale('hi'),
    Locale('kn'),
    Locale('ml'),
    Locale('mr'),
    Locale('pa'),
    Locale('ta'),
    Locale('te')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'OncoNutri+'**
  String get appName;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to OncoNutri+'**
  String get welcome;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signup;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get dontHaveAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @patientProfile.
  ///
  /// In en, this message translates to:
  /// **'Patient Profile'**
  String get patientProfile;

  /// No description provided for @dietRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Diet Recommendations'**
  String get dietRecommendations;

  /// No description provided for @progressHistory.
  ///
  /// In en, this message translates to:
  /// **'Progress History'**
  String get progressHistory;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDietPlan.
  ///
  /// In en, this message translates to:
  /// **'Diet Plan'**
  String get navDietPlan;

  /// No description provided for @navChatbot.
  ///
  /// In en, this message translates to:
  /// **'Chatbot'**
  String get navChatbot;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get homeGreeting;

  /// No description provided for @homeHealthPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Health Plan'**
  String get homeHealthPlan;

  /// No description provided for @homeTasksToday.
  ///
  /// In en, this message translates to:
  /// **'Tasks Today:'**
  String get homeTasksToday;

  /// No description provided for @dietPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Diet Plan'**
  String get dietPlanTitle;

  /// No description provided for @dietMySavedPlans.
  ///
  /// In en, this message translates to:
  /// **'My Saved Plans'**
  String get dietMySavedPlans;

  /// No description provided for @dietBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get dietBreakfast;

  /// No description provided for @dietLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get dietLunch;

  /// No description provided for @dietDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dietDinner;

  /// No description provided for @chatbotTitle.
  ///
  /// In en, this message translates to:
  /// **'OncoNutri Assistant'**
  String get chatbotTitle;

  /// No description provided for @chatbotWelcome.
  ///
  /// In en, this message translates to:
  /// **'Hello! I\'m your OncoNutri health assistant, here to support you with nutrition guidance during your cancer care journey.'**
  String get chatbotWelcome;

  /// No description provided for @chatbotAskPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything...'**
  String get chatbotAskPlaceholder;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettings;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get profileLanguage;

  /// No description provided for @profileNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get profileNotifications;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @settingsLanguageSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get settingsLanguageSelect;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose Photo Source'**
  String get settingsChoosePhoto;

  /// No description provided for @settingsCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get settingsCamera;

  /// No description provided for @settingsGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get settingsGallery;

  /// No description provided for @settingsRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get settingsRemovePhoto;

  /// No description provided for @settingsPrivacySecurity.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Security'**
  String get settingsPrivacySecurity;

  /// No description provided for @todayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todayProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'completed'**
  String get completed;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get streak;

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get dailyGoal;

  /// No description provided for @yourDietPlan.
  ///
  /// In en, this message translates to:
  /// **'Your Diet Plan'**
  String get yourDietPlan;

  /// No description provided for @foods.
  ///
  /// In en, this message translates to:
  /// **'foods'**
  String get foods;

  /// No description provided for @removeFood.
  ///
  /// In en, this message translates to:
  /// **'Remove Food'**
  String get removeFood;

  /// No description provided for @removeFoodConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove from your diet plan'**
  String get removeFoodConfirm;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removedFromDietPlan.
  ///
  /// In en, this message translates to:
  /// **'removed from diet plan'**
  String get removedFromDietPlan;

  /// No description provided for @settingsDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get settingsDataManagement;

  /// No description provided for @notifSettings.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notifSettings;

  /// No description provided for @notifDailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get notifDailyReminders;

  /// No description provided for @notifDailyRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get daily nutrition reminders'**
  String get notifDailyRemindersDesc;

  /// No description provided for @notifProgressUpdates.
  ///
  /// In en, this message translates to:
  /// **'Progress Updates'**
  String get notifProgressUpdates;

  /// No description provided for @notifProgressUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications about your progress'**
  String get notifProgressUpdatesDesc;

  /// No description provided for @notifHealthTips.
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get notifHealthTips;

  /// No description provided for @notifHealthTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive personalized health tips'**
  String get notifHealthTipsDesc;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get profilePhotoUpdated;

  /// No description provided for @profileEditName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get profileEditName;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileRetakeAssessment.
  ///
  /// In en, this message translates to:
  /// **'Retake Health Assessment'**
  String get profileRetakeAssessment;

  /// No description provided for @profileRetakeAssessmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your health information'**
  String get profileRetakeAssessmentDesc;

  /// No description provided for @profilePersonalDetails.
  ///
  /// In en, this message translates to:
  /// **'Personal Details'**
  String get profilePersonalDetails;

  /// No description provided for @profilePersonalDetailsDesc.
  ///
  /// In en, this message translates to:
  /// **'View and edit your profile'**
  String get profilePersonalDetailsDesc;

  /// No description provided for @profileHealthInformation.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get profileHealthInformation;

  /// No description provided for @profileHealthInformationDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your medical data'**
  String get profileHealthInformationDesc;

  /// No description provided for @profileNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your alerts'**
  String get profileNotificationsDesc;

  /// No description provided for @profileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// No description provided for @profileHelpSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Get assistance and FAQs'**
  String get profileHelpSupportDesc;

  /// No description provided for @profileAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About OncoNutri+'**
  String get profileAboutApp;

  /// No description provided for @profileAboutAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get profileAboutAppDesc;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmMessage;

  /// No description provided for @healthInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get healthInfoTitle;

  /// No description provided for @healthInfoMessage.
  ///
  /// In en, this message translates to:
  /// **'Your health data is securely stored and used to provide personalized nutrition recommendations. You can update this information by retaking the health assessment.'**
  String get healthInfoMessage;

  /// No description provided for @healthInfoUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get healthInfoUpdateNow;

  /// No description provided for @helpSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpSupportFAQ.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions:'**
  String get helpSupportFAQ;

  /// No description provided for @helpSupportQ1.
  ///
  /// In en, this message translates to:
  /// **'Q: How do I update my health information?'**
  String get helpSupportQ1;

  /// No description provided for @helpSupportA1.
  ///
  /// In en, this message translates to:
  /// **'A: Use \"Retake Health Assessment\" from your profile.'**
  String get helpSupportA1;

  /// No description provided for @helpSupportQ2.
  ///
  /// In en, this message translates to:
  /// **'Q: How are recommendations generated?'**
  String get helpSupportQ2;

  /// No description provided for @helpSupportA2.
  ///
  /// In en, this message translates to:
  /// **'A: Our AI analyzes your health data to provide personalized nutrition advice.'**
  String get helpSupportA2;

  /// No description provided for @helpSupportNeedMore.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get helpSupportNeedMore;

  /// No description provided for @helpSupportContact.
  ///
  /// In en, this message translates to:
  /// **'Contact us at support@onconutri.com'**
  String get helpSupportContact;

  /// No description provided for @aboutAppTitle.
  ///
  /// In en, this message translates to:
  /// **'OncoNutri+'**
  String get aboutAppTitle;

  /// No description provided for @aboutAppVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutAppVersion;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'OncoNutri+ provides AI-powered personalized nutrition recommendations for cancer patients.'**
  String get aboutAppDescription;

  /// No description provided for @aboutAppCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 OncoNutri+ Team\nAll rights reserved.'**
  String get aboutAppCopyright;

  /// No description provided for @chatDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete Message'**
  String get chatDeleteMessage;

  /// No description provided for @chatDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this message?'**
  String get chatDeleteConfirm;

  /// No description provided for @chatMessageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get chatMessageDeleted;

  /// No description provided for @chatClearHistory.
  ///
  /// In en, this message translates to:
  /// **'Clear Chat History'**
  String get chatClearHistory;

  /// No description provided for @chatClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the entire chat history?'**
  String get chatClearConfirm;

  /// No description provided for @chatCleared.
  ///
  /// In en, this message translates to:
  /// **'Chat history cleared'**
  String get chatCleared;

  /// No description provided for @chatClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get chatClear;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHindi.
  ///
  /// In en, this message translates to:
  /// **'हिन्दी'**
  String get languageHindi;

  /// No description provided for @languageKannada.
  ///
  /// In en, this message translates to:
  /// **'ಕನ್ನಡ'**
  String get languageKannada;

  /// No description provided for @languageTamil.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get languageTamil;

  /// No description provided for @languageTelugu.
  ///
  /// In en, this message translates to:
  /// **'తెలుగు'**
  String get languageTelugu;

  /// No description provided for @languageMalayalam.
  ///
  /// In en, this message translates to:
  /// **'മലയാളം'**
  String get languageMalayalam;

  /// No description provided for @languageMarathi.
  ///
  /// In en, this message translates to:
  /// **'मराठी'**
  String get languageMarathi;

  /// No description provided for @languageGujarati.
  ///
  /// In en, this message translates to:
  /// **'ગુજરાતી'**
  String get languageGujarati;

  /// No description provided for @languageBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা'**
  String get languageBengali;

  /// No description provided for @languagePunjabi.
  ///
  /// In en, this message translates to:
  /// **'ਪੰਜਾਬੀ'**
  String get languagePunjabi;

  /// No description provided for @languageSelected.
  ///
  /// In en, this message translates to:
  /// **'Language updated!'**
  String get languageSelected;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon!'**
  String get comingSoon;

  /// No description provided for @homeNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent!'**
  String get homeNotificationSent;

  /// No description provided for @homeAvailable.
  ///
  /// In en, this message translates to:
  /// **'available'**
  String get homeAvailable;

  /// No description provided for @homeActiveProjects.
  ///
  /// In en, this message translates to:
  /// **'Active projects'**
  String get homeActiveProjects;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homeSeeAll;

  /// No description provided for @homeDailyPlan.
  ///
  /// In en, this message translates to:
  /// **'Your daily plan'**
  String get homeDailyPlan;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get settingsNotifications;

  /// No description provided for @notificationDailyReminders.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminders'**
  String get notificationDailyReminders;

  /// No description provided for @notificationDailyRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Get daily nutrition reminders'**
  String get notificationDailyRemindersDesc;

  /// No description provided for @notificationProgressUpdates.
  ///
  /// In en, this message translates to:
  /// **'Progress Updates'**
  String get notificationProgressUpdates;

  /// No description provided for @notificationProgressUpdatesDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifications about your progress'**
  String get notificationProgressUpdatesDesc;

  /// No description provided for @notificationHealthTips.
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get notificationHealthTips;

  /// No description provided for @notificationHealthTipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive personalized health tips'**
  String get notificationHealthTipsDesc;

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpTitle;

  /// No description provided for @helpFaqTitle.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions:'**
  String get helpFaqTitle;

  /// No description provided for @helpQuestion1.
  ///
  /// In en, this message translates to:
  /// **'Q: How do I update my health information?'**
  String get helpQuestion1;

  /// No description provided for @helpAnswer1.
  ///
  /// In en, this message translates to:
  /// **'A: Use \"Retake Health Assessment\" from your profile.'**
  String get helpAnswer1;

  /// No description provided for @helpQuestion2.
  ///
  /// In en, this message translates to:
  /// **'Q: How are recommendations generated?'**
  String get helpQuestion2;

  /// No description provided for @helpAnswer2.
  ///
  /// In en, this message translates to:
  /// **'A: Our AI analyzes your health data to provide personalized nutrition advice.'**
  String get helpAnswer2;

  /// No description provided for @helpNeedMore.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get helpNeedMore;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get aboutVersion;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'OncoNutri+ provides AI-powered personalized nutrition recommendations for cancer patients.'**
  String get aboutDescription;

  /// No description provided for @aboutCopyright.
  ///
  /// In en, this message translates to:
  /// **'© 2025 OncoNutri+ Team\nAll rights reserved.'**
  String get aboutCopyright;

  /// No description provided for @chatStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get chatStartConversation;

  /// No description provided for @chatAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about nutrition and health'**
  String get chatAskAnything;

  /// No description provided for @profileLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated!'**
  String get profileLanguageUpdated;

  /// No description provided for @profileHealthInfo.
  ///
  /// In en, this message translates to:
  /// **'Health Information'**
  String get profileHealthInfo;

  /// No description provided for @profileHealthInfoDesc.
  ///
  /// In en, this message translates to:
  /// **'Your health data is securely stored and used to provide personalized nutrition recommendations. You can update this information by retaking the health assessment.'**
  String get profileHealthInfoDesc;

  /// No description provided for @profileUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get profileUpdateNow;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @loginGoogleComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Google Sign In coming soon'**
  String get loginGoogleComingSoon;

  /// No description provided for @loginWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginWithGoogle;

  /// No description provided for @signupSuccess.
  ///
  /// In en, this message translates to:
  /// **'Account created successfully!'**
  String get signupSuccess;

  /// No description provided for @signupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupTitle;

  /// No description provided for @signupHeading.
  ///
  /// In en, this message translates to:
  /// **'Join OncoNutri+'**
  String get signupHeading;

  /// No description provided for @signupSubheading.
  ///
  /// In en, this message translates to:
  /// **'Start your personalized nutrition journey'**
  String get signupSubheading;

  /// No description provided for @dietPlanAdded.
  ///
  /// In en, this message translates to:
  /// **'added to your diet plan'**
  String get dietPlanAdded;

  /// No description provided for @dietPlanAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add food to diet plan'**
  String get dietPlanAddFailed;

  /// No description provided for @dietPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan saved!'**
  String get dietPlanSaved;

  /// No description provided for @ageQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your age?'**
  String get ageQuestion;

  /// No description provided for @ageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us personalize your nutrition plan'**
  String get ageSubtitle;

  /// No description provided for @ageYears.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get ageYears;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @dietaryPreferenceQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is your dietary preference?'**
  String get dietaryPreferenceQuestion;

  /// No description provided for @dietaryPreferenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us suggest foods that match your diet'**
  String get dietaryPreferenceSubtitle;

  /// No description provided for @pureVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Pure Vegetarian'**
  String get pureVegetarian;

  /// No description provided for @pureVegSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No meat, no eggs, no fish'**
  String get pureVegSubtitle;

  /// No description provided for @vegetarianEggs.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian + Eggs'**
  String get vegetarianEggs;

  /// No description provided for @vegEggsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian with eggs'**
  String get vegEggsSubtitle;

  /// No description provided for @nonVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Non-Vegetarian'**
  String get nonVegetarian;

  /// No description provided for @nonVegSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All foods including meat'**
  String get nonVegSubtitle;

  /// No description provided for @pescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get pescatarian;

  /// No description provided for @pescatarianSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian + fish/seafood'**
  String get pescatarianSubtitle;

  /// No description provided for @vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get vegan;

  /// No description provided for @veganSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No animal products'**
  String get veganSubtitle;

  /// No description provided for @jain.
  ///
  /// In en, this message translates to:
  /// **'Jain'**
  String get jain;

  /// No description provided for @jainSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No root vegetables, no meat'**
  String get jainSubtitle;

  /// No description provided for @cancerTypeQuestion.
  ///
  /// In en, this message translates to:
  /// **'What type of cancer?'**
  String get cancerTypeQuestion;

  /// No description provided for @cancerTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us provide targeted nutritional guidance'**
  String get cancerTypeSubtitle;

  /// No description provided for @breastCancer.
  ///
  /// In en, this message translates to:
  /// **'Breast Cancer'**
  String get breastCancer;

  /// No description provided for @lungCancer.
  ///
  /// In en, this message translates to:
  /// **'Lung Cancer'**
  String get lungCancer;

  /// No description provided for @colorectalCancer.
  ///
  /// In en, this message translates to:
  /// **'Colorectal Cancer'**
  String get colorectalCancer;

  /// No description provided for @prostateCancer.
  ///
  /// In en, this message translates to:
  /// **'Prostate Cancer'**
  String get prostateCancer;

  /// No description provided for @stomachCancer.
  ///
  /// In en, this message translates to:
  /// **'Stomach Cancer'**
  String get stomachCancer;

  /// No description provided for @liverCancer.
  ///
  /// In en, this message translates to:
  /// **'Liver Cancer'**
  String get liverCancer;

  /// No description provided for @pancreaticCancer.
  ///
  /// In en, this message translates to:
  /// **'Pancreatic Cancer'**
  String get pancreaticCancer;

  /// No description provided for @kidneyCancer.
  ///
  /// In en, this message translates to:
  /// **'Kidney Cancer'**
  String get kidneyCancer;

  /// No description provided for @treatmentStageQuestion.
  ///
  /// In en, this message translates to:
  /// **'Current treatment stage?'**
  String get treatmentStageQuestion;

  /// No description provided for @treatmentStageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Different stages have different nutritional needs'**
  String get treatmentStageSubtitle;

  /// No description provided for @preTreatment.
  ///
  /// In en, this message translates to:
  /// **'Pre-Treatment'**
  String get preTreatment;

  /// No description provided for @preTreatmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Building strength before treatment'**
  String get preTreatmentDesc;

  /// No description provided for @chemotherapy.
  ///
  /// In en, this message translates to:
  /// **'Chemotherapy'**
  String get chemotherapy;

  /// No description provided for @chemotherapyDesc.
  ///
  /// In en, this message translates to:
  /// **'Managing side effects'**
  String get chemotherapyDesc;

  /// No description provided for @radiation.
  ///
  /// In en, this message translates to:
  /// **'Radiation'**
  String get radiation;

  /// No description provided for @radiationDesc.
  ///
  /// In en, this message translates to:
  /// **'Supporting tissue recovery'**
  String get radiationDesc;

  /// No description provided for @surgeryRecovery.
  ///
  /// In en, this message translates to:
  /// **'Surgery Recovery'**
  String get surgeryRecovery;

  /// No description provided for @surgeryRecoveryDesc.
  ///
  /// In en, this message translates to:
  /// **'Healing and recovery'**
  String get surgeryRecoveryDesc;

  /// No description provided for @postTreatment.
  ///
  /// In en, this message translates to:
  /// **'Post-Treatment'**
  String get postTreatment;

  /// No description provided for @postTreatmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Rebuilding health'**
  String get postTreatmentDesc;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @maintenanceDesc.
  ///
  /// In en, this message translates to:
  /// **'Sustaining wellness'**
  String get maintenanceDesc;

  /// No description provided for @symptomsQuestion.
  ///
  /// In en, this message translates to:
  /// **'What symptoms are you experiencing?'**
  String get symptomsQuestion;

  /// No description provided for @symptomsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply'**
  String get symptomsSubtitle;

  /// No description provided for @mouthSores.
  ///
  /// In en, this message translates to:
  /// **'Mouth Sores'**
  String get mouthSores;

  /// No description provided for @tasteChanges.
  ///
  /// In en, this message translates to:
  /// **'Taste Changes'**
  String get tasteChanges;

  /// No description provided for @difficultySwallowing.
  ///
  /// In en, this message translates to:
  /// **'Difficulty Swallowing'**
  String get difficultySwallowing;

  /// No description provided for @bloating.
  ///
  /// In en, this message translates to:
  /// **'Bloating'**
  String get bloating;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @allergiesQuestion.
  ///
  /// In en, this message translates to:
  /// **'Any food allergies or restrictions?'**
  String get allergiesQuestion;

  /// No description provided for @allergiesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select all that apply to you'**
  String get allergiesSubtitle;

  /// No description provided for @diabeticDiet.
  ///
  /// In en, this message translates to:
  /// **'Diabetic Diet'**
  String get diabeticDiet;

  /// No description provided for @diabeticSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Low sugar intake'**
  String get diabeticSubtitle;

  /// No description provided for @lowSodium.
  ///
  /// In en, this message translates to:
  /// **'Low Sodium'**
  String get lowSodium;

  /// No description provided for @lowSodiumSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reduced salt'**
  String get lowSodiumSubtitle;

  /// No description provided for @otherAllergies.
  ///
  /// In en, this message translates to:
  /// **'Other Allergies'**
  String get otherAllergies;

  /// No description provided for @otherAllergiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Type any other food allergy or restriction. Our AI will understand and help.'**
  String get otherAllergiesDesc;

  /// No description provided for @otherAllergiesPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g., I can\'t eat tomatoes...'**
  String get otherAllergiesPlaceholder;

  /// No description provided for @getRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get Recommendations'**
  String get getRecommendations;

  /// No description provided for @skipNoAllergies.
  ///
  /// In en, this message translates to:
  /// **'Skip - No Allergies'**
  String get skipNoAllergies;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @ofLabel.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofLabel;

  /// No description provided for @foodsLabel.
  ///
  /// In en, this message translates to:
  /// **'Foods'**
  String get foodsLabel;

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get caloriesLabel;

  /// No description provided for @overviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewLabel;

  /// No description provided for @healthTipsLabel.
  ///
  /// In en, this message translates to:
  /// **'Health Tips'**
  String get healthTipsLabel;

  /// No description provided for @getPersonalizedRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Get Personalized Recommendations'**
  String get getPersonalizedRecommendations;

  /// No description provided for @nutritionPlan.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Plan'**
  String get nutritionPlan;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'Active today'**
  String get activeToday;

  /// No description provided for @healthProgress.
  ///
  /// In en, this message translates to:
  /// **'Health Progress'**
  String get healthProgress;

  /// No description provided for @foodsSuggested.
  ///
  /// In en, this message translates to:
  /// **'Foods suggested'**
  String get foodsSuggested;

  /// No description provided for @daysTracked.
  ///
  /// In en, this message translates to:
  /// **'Days tracked'**
  String get daysTracked;

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommendedForYou;

  /// No description provided for @unableToLoadDashboard.
  ///
  /// In en, this message translates to:
  /// **'Unable to load dashboard'**
  String get unableToLoadDashboard;

  /// No description provided for @pleaseTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get pleaseTryAgain;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['bn', 'en', 'es', 'gu', 'hi', 'kn', 'ml', 'mr', 'pa', 'ta', 'te'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn': return AppLocalizationsBn();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
    case 'gu': return AppLocalizationsGu();
    case 'hi': return AppLocalizationsHi();
    case 'kn': return AppLocalizationsKn();
    case 'ml': return AppLocalizationsMl();
    case 'mr': return AppLocalizationsMr();
    case 'pa': return AppLocalizationsPa();
    case 'ta': return AppLocalizationsTa();
    case 'te': return AppLocalizationsTe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
