import 'package:flutter/material.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import '../../logic/auth_state.dart';
import 'right_pane_stage_one.dart';
import 'right_pane_stage_two.dart';
import '../../../../core/shared_widgets/app_logo.dart';

class RightPane extends StatelessWidget {
  final bool isWide;
  const RightPane({super.key, required this.isWide});

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
                  Text('Get started with', style: AppTextStyles.heading2),
                  const SizedBox(width: 8),
                  const AppLogo(),
                  const SizedBox(width: 8),
                  Text('Ontapi', style: AppTextStyles.heading2),
                ],
              ),
            const SizedBox(height: 12),
            if (!isWide)
              Text(
                'Create your workspace and start managing your queue\nin real-time.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),

            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                if (state is AuthLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (state is AuthSignUpStageOne) {
                  return RightPaneStageTwo(
                    email: state.email,
                    password: state.password,
                  );
                }

                return const RightPaneStageOne();
              },
            ),
          ],
        ),
      ),
    );
  }
}
