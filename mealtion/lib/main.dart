import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/theme.dart';
import 'app/app_state.dart';
import 'app/colors.dart';
import 'features/home/mealtion_home_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/register_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const MealtionApp(),
    ),
  );
}

class MealtionApp extends StatelessWidget {
  const MealtionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mealtion',
      debugShowCheckedModeBanner: false,
      theme: buildMealtionTheme(),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with SingleTickerProviderStateMixin {
  bool _showRegister = false;
  bool _showSplash = true;
  late AnimationController _splashController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Splash animation
    _splashController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeOutBack),
    );
    
    // Start animation
    _splashController.forward();
    
    // Show splash for 2.5 seconds on app open, then hide
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show splash screen once on app open
    if (_showSplash) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        body: Center(
          child: AnimatedBuilder(
            animation: _splashController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: MealtionLogo(height: 40, variant: 'white'),
          ),
        ),
      );
    }

    return Consumer<AppState>(
      builder: (context, appState, _) {
        switch (appState.authState) {
          case AppAuthState.loading:
            return Scaffold(
              backgroundColor: AppColors.bg,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );

          case AppAuthState.unauthenticated:
            if (_showRegister) {
              return RegisterPage(
                onRegisterSuccess: () {
                  context.read<AppState>().onAuthenticated();
                },
                onGoToLogin: () {
                  setState(() => _showRegister = false);
                },
              );
            }
            return LoginPage(
              onLoginSuccess: () {
                context.read<AppState>().onAuthenticated();
              },
              onGoToRegister: () {
                setState(() => _showRegister = true);
              },
            );

          case AppAuthState.authenticated:
            return const MealtionHomePage();
        }
      },
    );
  }
}
