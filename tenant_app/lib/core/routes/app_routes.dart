import 'package:flutter/material.dart';

import '../../features/auth/ui/pages/sign_up_page.dart';
import '../../features/auth/ui/pages/tenant_dashboard_page.dart';

class AppRoutes {
  static const String initial =
      '/'; // Resolves auth state normally handled by AuthWrapper
  static const String signUp = '/sign-up';
  static const String tenantDashboard = '/tenant-dashboard';

  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case signUp:
        return MaterialPageRoute(builder: (_) => const SignUpPage());
      case tenantDashboard:
        return MaterialPageRoute(builder: (_) => const TenantDashboardPage());
      default:
        // Let the root handle the wrapper via '/'
        return null;
    }
  }
}
