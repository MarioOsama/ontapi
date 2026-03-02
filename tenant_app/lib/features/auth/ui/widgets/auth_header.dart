import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';


class AuthHeader extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;
  final double progress;

  const AuthHeader({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('STEP $step OF 2', style: AppTextStyles.labelBold),
            const SizedBox(width: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(title, style: AppTextStyles.heading2),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.5)),
      ],
    );
  }
}

