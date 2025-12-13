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
      // Builder to handle the phone frame layout
      builder: (context, child) {
        return Scaffold(
          // Grey background for the browser/desktop area
          backgroundColor: Colors.grey[200],
          body: Center(
            // 1. Add margin so the phone never touches the browser edges
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              
              // 2. FittedBox scales the child down if the screen is too small
              // avoiding distortion/squeezing while keeping aspect ratio.
              child: FittedBox(
                fit: BoxFit.contain,
                
                // 3. Define the ideal logical size of the phone (iPhone 14)
                child: SizedBox(
                  width: 390, 
                  height: 844, 
                  child: Container(
                    // 4. Decoration (Shadow and Rounded Corners)
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
                    // 5. Clip the app content to the rounded corners
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
    
    // Splash animation setup
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
            // Use logo from theme.dart
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