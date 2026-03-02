import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';


class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: const Icon(Icons.hub_outlined, color: Colors.white, size: 32),
    );
  }
}

