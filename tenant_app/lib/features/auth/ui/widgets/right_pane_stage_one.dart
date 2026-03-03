import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tenant_app/features/auth/logic/auth_state.dart' show AuthError;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../logic/auth_cubit.dart';
import 'auth_header.dart';
import 'auth_input_field.dart';
import 'auth_primary_button.dart';

class RightPaneStageOne extends StatefulWidget {
  final VoidCallback onSignInTap;
  final bool isLoading;

  const RightPaneStageOne({
    super.key,
    required this.onSignInTap,
    this.isLoading = false,
  });

  @override
  State<RightPaneStageOne> createState() => RightPaneStageOneState();
}

class RightPaneStageOneState extends State<RightPaneStageOne> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().proceedToStageTwo(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isError = context.read<AuthCubit>().state is AuthError;
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: EdgeInsets.symmetric(
        horizontal: 32.0,
        vertical: isError ? 0.0 : 48.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AuthHeader(
              step: '1',
              title: 'Get started for free',
              subtitle:
                  'Create your free account and start managing queues today.',
              progress: 0.5,
            ),
            const SizedBox(height: 32),
            AuthInputField(
              label: 'Email',
              hint: 'e.g. hello@ontapi.com',
              icon: Icons.mail_outline,
              controller: _emailCtrl,
              validator: (val) =>
                  (val == null || !val.contains('@')) ? 'Invalid email' : null,
            ),
            const SizedBox(height: 24),
            AuthInputField(
              label: 'Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _passCtrl,
              validator: (val) =>
                  (val == null || val.length < 8) ? 'Min 8 chars' : null,
            ),
            const SizedBox(height: 24),
            AuthInputField(
              label: 'Confirm Password',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscure: true,
              controller: _confirmCtrl,
              validator: (val) {
                if (val != _passCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 48),
            AuthPrimaryButton(
              text: 'Continue',
              icon: Icons.arrow_forward_rounded,
              onPressed: _submit,
              isLoading: widget.isLoading,
            ),
            const SizedBox(height: 32),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    "Already have a workspace?",
                    style: AppTextStyles.bodyMedium,
                  ),
                  TextButton(
                    onPressed: widget.onSignInTap,
                    child: Text(
                      'Sign in',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
