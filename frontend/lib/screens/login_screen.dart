import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/app_theme.dart';
import '../widgets/ui_components.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'signin_screen.dart';
import 'onboarding_screen.dart';
import 'intake/age_picker_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  
  Future<void> _guestLogin() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await AuthService.guestLogin();
      if (result['success'] && mounted) {
        // Mark as not first time
        await AuthService.setNotFirstTime();
        // Navigate to intake flow (age picker) first
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AgePickerScreen()),
        );
      } else if (mounted) {
        throw Exception(result['error'] ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localizations.loginFailed}: $e'),
            backgroundColor: AppTheme.colorDanger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.horizontalPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo (60px as per spec)
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor(context),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.defaultShadow,
                      ),
                      child: const Icon(
                        Icons.restaurant_menu,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Welcome text (H2 as per spec)
                  Text(
                    'Welcome to OncoNutri+',
                    textAlign: TextAlign.center,
                    style: AppTheme.h2.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your personalized cancer nutrition companion',
                    textAlign: TextAlign.center,
                    style: AppTheme.body.copyWith(
                        color: AppTheme.subtextColor(context),
                      ),
                  ),
                  const SizedBox(height: 48),
                  // Primary CTA - Sign In (for existing users)
                  PrimaryButton(
                    label: 'Sign In',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignInScreen()),
                      );
                    },
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  // Continue as Guest
                  GhostButton(
                    label: _isLoading ? 'Loading...' : 'Continue as Guest',
                    onPressed: _isLoading ? null : _guestLogin,
                    fullWidth: true,
                  ),
                  const SizedBox(height: 16),
                  // Create Account
                  GhostButton(
                    label: 'Create Account',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    fullWidth: true,
                  ),
                  const SizedBox(height: 32),
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.black26)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: AppTheme.caption.copyWith(color: Theme.of(context).dividerColor.withOpacity(0.6)),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.black26)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Google Sign In (Ghost button with icon - as per spec)
                  OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Implement Google Sign In
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.loginGoogleComingSoon),
                        ),
                      );
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(AppLocalizations.of(context)!.loginWithGoogle),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black26, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Learn more about the app
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        );
                      },
                      child: Text(
                        'Learn more about OncoNutri+',
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.primaryColor(context),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


