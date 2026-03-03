import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'core/routes/app_routes.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_colors.dart';
import 'core/utils/injection_container.dart';
import 'features/auth/data/models/app_user.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/logic/auth_cubit.dart';
import 'features/auth/logic/auth_state.dart';
import 'features/auth/ui/pages/sign_in_page.dart';
import 'features/auth/ui/pages/tenant_dashboard_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: getIt<AuthRepository>(),
      child: BlocProvider.value(
        value: getIt<AuthCubit>(),
        child: const _AppConfiguration(),
      ),
    );
  }
}

class _AppConfiguration extends StatefulWidget {
  const _AppConfiguration();

  @override
  State<_AppConfiguration> createState() => _AppConfigurationState();
}

class _AppConfigurationState extends State<_AppConfiguration> {
  @override
  void initState() {
    super.initState();
    final authService = getIt<AuthService>();
    final cubit = getIt<AuthCubit>();

    final sessionUser = authService.currentUser;
    if (sessionUser != null) {
      cubit.resolveRole(sessionUser.id, sessionUser.email!);
    } else {
      cubit.setUnauthenticated();
    }

    authService.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut) {
        cubit.setUnauthenticated();
      } else if (event.event == AuthChangeEvent.signedIn) {
        cubit.resolveRole(event.session!.user.id, event.session!.user.email!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OnTapi Tenant App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is AuthAuthenticated) {
          if (state.user.role == UserRole.tenantAdmin) {
            return const TenantDashboardPage();
          } else {
            return const Scaffold(
              body: Center(child: Text('Branch View Placeholder')),
            );
          }
        } else if (state is AuthBranchSelection) {
          return const Scaffold(
            body: Center(child: Text('Branch Selector Placeholder')),
          );
        } else {
          // AuthUnauthenticated or AuthError
          return SignInPage();
        }
      },
    );
  }
}
