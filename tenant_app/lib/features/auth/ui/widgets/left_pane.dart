import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'dart:async';

import '../../../../core/shared_widgets/app_logo.dart';

class LeftPane extends StatefulWidget {
  const LeftPane({super.key});

  @override
  State<LeftPane> createState() => LeftPaneState();
}

class LeftPaneState extends State<LeftPane> {
  Timer? _timer;
  int _textIndex = 0;

  final List<String> _texts = [
    'Queue Management\nfor Modern Teams.',
    'Manage Your Queue.\nIn Real Time.',
  ];

  final List<String> _descriptions = [
    'Real-time insights and seamless customer flow. Optimize your waiting lines and improve customer satisfaction with our intelligent dashboard.',
    'Experience seamless customer flow optimization. Join thousands of businesses using Ontapi to reduce wait times and boost satisfaction.',
  ];

  final List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1170&q=80',
    'https://images.unsplash.com/photo-1704204656144-3dd12c110dd8?q=80&w=1109&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    'https://images.unsplash.com/photo-1649775391951-e3fdf0e7e7ec?q=80&w=881&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() {
        _textIndex = (_textIndex + 1) % 2;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          center: Alignment.centerLeft,
          radius: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 48.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppLogo(),
                const SizedBox(width: 12),
                Text('Ontapi', style: AppTextStyles.heading3),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 48),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                key: ValueKey(_textIndex),
                _texts[_textIndex],
                style: AppTextStyles.heading1,
              ),
            ),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                key: ValueKey(_textIndex),
                _descriptions[_textIndex],
                style: AppTextStyles.bodyLarge,
              ),
            ),
            const SizedBox(height: 48),
            // Trust indicators mockup
            Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 40,
                  child: Stack(
                    children: [
                      Avatar(AppColors.borderLight, 0, _imageUrls[0]),
                      Avatar(AppColors.borderMedium, 20, _imageUrls[1]),
                      Avatar(AppColors.textLight, 40, _imageUrls[2]),
                      Positioned(
                        left: 60,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.textSecondary,
                          child: Text(
                            '+2k',
                            style: AppTextStyles.label.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (index) => const Icon(
                          Icons.star,
                          color: AppColors.starWarning,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trusted by 2,000+ businesses',
                      style: AppTextStyles.label,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: 48),
            const Divider(color: AppColors.dividerDark),
            const SizedBox(height: 16),
            Text(
              '© 2026 Ontapi Inc. All rights reserved.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Avatar extends StatelessWidget {
  final Color color;
  final double left;
  final String imageUrl;
  const Avatar(this.color, this.left, this.imageUrl, {super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderDark, width: 2),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: color,
          backgroundImage: NetworkImage(imageUrl),
        ),
      ),
    );
  }
}
