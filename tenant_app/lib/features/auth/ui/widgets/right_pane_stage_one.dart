import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import 'auth_header.dart';
import 'auth_input_field.dart';
import 'auth_primary_button.dart';

class RightPaneStageOne extends StatefulWidget {
  const RightPaneStageOne({super.key});

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
    return Container(
      constraints: const BoxConstraints(maxWidth: 480),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
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
            ),
          ],
        ),
      ),
    );
  }
}
