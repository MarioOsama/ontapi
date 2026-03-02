import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_cubit.dart';
import '../../logic/auth_state.dart';
import '../widgets/left_pane.dart';
import '../widgets/right_pane.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 980;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: isWide
                      ? EdgeInsetsGeometry.zero
                      : const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isWide) const Expanded(flex: 5, child: LeftPane()),
                      Expanded(
                        flex: 6,
                        child: BlocConsumer<AuthCubit, AuthState>(
                          listener: (context, state) {
                            if (state is AuthError) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(content: Text(state.message)),
                                );
                            }
                          },
                          builder: (context, state) {
                            return RightPane(isWide: isWide);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
