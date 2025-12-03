import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import '../widgets/ui_components.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Personalized Nutrition',
      description:
          'Get AI-powered food recommendations tailored to your cancer type, treatment phase, and symptoms.',
      icon: Icons.restaurant_menu,
      colorBuilder: (ctx) => AppTheme.primary400Color(ctx),
    ),
    OnboardingPage(
      title: 'Evidence-Based Care',
      description:
          'Our recommendations are based on clinical nutrition guidelines and the latest research.',
      icon: Icons.science,
      colorBuilder: (ctx) => AppTheme.colorSuccess,
    ),
    OnboardingPage(
      title: 'Track Your Progress',
      description:
          'Monitor your dietary intake, symptoms, and overall well-being throughout your journey.',
      icon: Icons.trending_up,
      colorBuilder: (ctx) => AppTheme.colorWarning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppTheme.pageTransitionDuration,
        curve: AppTheme.defaultCurve,
      );
    } else {
      _goToLogin();
    }
  }

  Future<void> _goToLogin() async {
    await AuthService.setNotFirstTime();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.backgroundGradientFor(context),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _goToLogin,
                  child: Text(
                    'Skip',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.subtextColor(context),
                    ),
                  ),
                ),
              ),
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPageContent(_pages[index]);
                  },
                ),
              ),
              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildDot(index),
                ),
              ),
              const SizedBox(height: 32),
              // Next/Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.horizontalPadding,
                ),
                child: PrimaryButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Get Started'
                      : 'Next',
                  onPressed: _nextPage,
                  fullWidth: true,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon/Illustration
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: page.colorBuilder(context).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
                child: Icon(
                  page.icon,
                  size: 80,
                  color: page.colorBuilder(context),
                ),
          ),
          const SizedBox(height: 48),
          // Title
          Text(
            page.title,
            style: AppTheme.h1.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            page.description,
            style: AppTheme.body.copyWith(fontSize: 15, color: AppTheme.subtextColor(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: AppTheme.fadeInDuration,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppTheme.primaryColor(context)
            : AppTheme.borderColor(context),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color Function(BuildContext) colorBuilder;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.colorBuilder,
  });
}


