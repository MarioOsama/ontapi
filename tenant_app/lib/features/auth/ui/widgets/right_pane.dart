import 'package:flutter/material.dart';
import 'package:tenant_app/core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/auth_state.dart';
import 'right_pane_stage_one.dart';
import 'right_pane_stage_two.dart';
import '../../../../core/shared_widgets/app_error_banner.dart';
import '../../../../core/shared_widgets/app_logo.dart';

class RightPane extends StatelessWidget {
  final bool isWide;
  final VoidCallback onSignInTap;

  const RightPane({super.key, required this.isWide, required this.onSignInTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isWide)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppLogo(),
                  const SizedBox(width: 12),
                  Text(
                    'Ontapi',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            if (isWide)
              Text(
                'Create your workspace',
                style: AppTextStyles.heading2,
                textAlign: TextAlign.center,
              ),
            if (!isWide) const SizedBox(height: 12),
            if (!isWide)
              Text(
                'Create your workspace and start managing your queue in real-time.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Column(
                  children: [
                    if (state is AuthError)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32.0,
                          vertical: 16.0,
                        ),
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 425),
                          child: AppErrorBanner(
                            message: state.message,
                            onDismiss: () =>
                                context.read<AuthCubit>().setUnauthenticated(),
                          ),
                        ),
                      ),

                    if (state is AuthSignUpStageOne)
                      RightPaneStageTwo(
                        email: state.email,
                        password: state.password,
                        isLoading: isLoading,
                      )
                    else
                      RightPaneStageOne(
                        onSignInTap: onSignInTap,
                        isLoading: isLoading,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
