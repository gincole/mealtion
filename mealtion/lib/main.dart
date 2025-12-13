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
      builder: (context, child) {
        // Get current screen width
        final screenWidth = MediaQuery.of(context).size.width;

        // CHECK: Is it a mobile device? (width less than 600px)
        if (screenWidth < 600) {
          // If mobile: Return the app directly (Full Screen)
          return child!;
        }

        // If desktop/tablet: Show the Phone Frame wrapper
        return Scaffold(
          // Grey background for desktop area
          backgroundColor: Colors.grey[200],
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              // Scale the phone frame to fit the screen without distortion
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 390, // Fixed width (iPhone 14)
                  height: 844, // Fixed height (iPhone 14)
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    // Clip content to rounded corners
                    clipBehavior: Clip.hardEdge,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
    _splashController.forward();
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
            child: const MealtionLogo(height: 40, variant: 'white'),
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
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            );
          case AppAuthState.unauthenticated:
            if (_showRegister) {
              return RegisterPage(
                onRegisterSuccess: () => context.read<AppState>().onAuthenticated(),
                onGoToLogin: () => setState(() => _showRegister = false),
              );
            }
            return LoginPage(
              onLoginSuccess: () => context.read<AppState>().onAuthenticated(),
              onGoToRegister: () => setState(() => _showRegister = true),
            );
          case AppAuthState.authenticated:
            return const MealtionHomePage();
        }
      },
    );
  }
}