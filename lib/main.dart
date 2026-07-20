import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/styles/app_styles.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/success_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/auth/screens/password_change_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/data/app_data_repository.dart';
import 'features/map/services/spot_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const MyApp());
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    return isAuthenticated ? const HomeScreen() : const LoginScreen();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppDataRepository(SpotApi())),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.zenMaruGothicTextTheme(),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          // ── Auth ──────────────────────────────────────
          AppConstants.routeLogin: (_) => const LoginScreen(),
          AppConstants.routeRegister: (_) => const RegisterScreen(),
          AppConstants.routeOtp: (context) => OtpScreen(
            email: ModalRoute.of(context)!.settings.arguments as String,
          ),

          // ── Password ──────────────────────────────────
          AppConstants.routeForgotPassword: (_) => const ForgotPasswordScreen(),
          AppConstants.routePasswordChange: (_) => const PasswordChangeScreen(),

          // ── Success ───────────────────────────────────
          AppConstants.routeSuccessRegister: (_) =>
              const SuccessScreen(type: SuccessType.register),
          AppConstants.routeSuccessLogin: (_) =>
              const SuccessScreen(type: SuccessType.login),
          AppConstants.routeSuccessPassword: (_) =>
              const SuccessScreen(type: SuccessType.password),

          // ── Home（仮） ───────────────────────────────────
          AppConstants.routeHomeScreen: (_) => const HomeScreen(),
        },
      ),
    );
  }
}
