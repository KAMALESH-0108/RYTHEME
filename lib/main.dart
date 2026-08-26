import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'services/backend_service.dart';
import 'services/player_provider.dart';
import 'services/customization_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI parameters for clean edge-to-edge Android render
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Ensure the application can draw behind system bars (edge-to-edge)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Initialize Backend Infrastructure (Supabase & JioSaavn Open-Source API)
  await BackendService.instance.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => CustomizationProvider()),
      ],
      child: const RythemeApp(),
    ),
  );
}

class RythemeApp extends StatelessWidget {
  const RythemeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: RythemeConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: RythemeTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const AppShell(),
      },
    );
  }
}
