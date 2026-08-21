import 'package:chapp/core/theme/app_theme.dart';
import 'package:chapp/features/Auth/presentation/bloc/auth_bloc.dart';
import 'package:chapp/features/Auth/presentation/pages/log_in_page.dart';
import 'package:chapp/features/Auth/presentation/pages/register_page.dart';
import 'package:chapp/features/Chat/presentation/pages/home_page.dart';
import 'package:chapp/features/Users/presentation/widgets/presence_wrapper.dart';
import 'package:chapp/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>()..add(AuthCheckStatus()),
      child: MaterialApp(
        title: 'Chapp',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // Only rebuild for navigation-level states. Transient states
      // (AuthLoading/AuthFailure/OtpSent/AuthNoError) are handled locally by
      // each page, so a failed login/register doesn't swap the whole screen.
      buildWhen: (previous, current) =>
          current is AuthInitial ||
          current is Authenticated ||
          current is Unauthenticated ||
          current is ProfileSetupRequired,
      builder: (context, state) {
        if (state is Authenticated) {
          return const PresenceWrapper(child: HomePage());
        } else if (state is ProfileSetupRequired) {
          return const RegisterPage();
        } else if (state is Unauthenticated) {
          return const LogInPage();
        }
        // AuthInitial (startup) → splash spinner.
        return const _SplashScreen();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
