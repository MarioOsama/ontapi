import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/shared_widgets/app_error_banner.dart';
import '../../../../core/shared_widgets/app_logo.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/auth_state.dart';
import 'auth_input_field.dart';
import 'auth_primary_button.dart';

class SignInRightPane extends StatefulWidget {
  final bool isWide;
  final VoidCallback onSignUpTap;

  const SignInRightPane({
    super.key,
    required this.isWide,
    required this.onSignUpTap,
  });

  @override
  State<SignInRightPane> createState() => _SignInRightPaneState();
}

class _SignInRightPaneState extends State<SignInRightPane> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signIn(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!widget.isWide) ...[
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
              const SizedBox(height: 32),
              Text('Welcome back', style: AppTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                'Sign in to your workspace.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],

            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 48.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isWide) ...[
                          Text('Welcome back', style: AppTextStyles.heading2),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your workspace.',
                            style: AppTextStyles.bodyMedium,
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (state is AuthError)
                          AppErrorBanner(
                            message: state.message,
                            onDismiss: () =>
                                context.read<AuthCubit>().setUnauthenticated(),
                          ),

                        AuthInputField(
                          label: 'Email address',
                          hint: 'name@company.com',
                          icon: Icons.mail_outline,
                          controller: _emailCtrl,
                          validator: (val) =>
                              (val == null || !val.contains('@'))
                              ? 'Invalid email'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        AuthInputField(
                          label: 'Password',
                          hint: 'Enter your password',
                          icon: Icons.lock_outline,
                          obscure: true,
                          controller: _passCtrl,
                          validator: (val) => (val == null || val.length < 8)
                              ? 'Min 8 chars'
                              : null,
                        ),

                        // Forgot password Right-aligned text button
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not implemented yet')));
                            },
                            child: Text(
                              'Forgot password?',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        AuthPrimaryButton(
                          text: 'Sign In',
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _submit,
                          isLoading: state is AuthLoading,
                        ),

                        const SizedBox(height: 48),

                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                "Don't have a workspace?",
                                style: AppTextStyles.bodyMedium,
                              ),
                              TextButton(
                                onPressed: widget.onSignUpTap,
                                child: Text(
                                  'Create one',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundCard,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  size: 14,
                                  color: AppColors.textMuted,
                                ),
                                Expanded(
                                  child: Text(
                                    'Secure authentication powered by modern infrastructure',
                                    style: AppTextStyles.label,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
