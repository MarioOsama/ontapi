import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../logic/auth_cubit.dart';
import '../../logic/auth_state.dart';
import '../widgets/left_pane.dart';
import '../widgets/sign_in_right_pane.dart';

import '../widgets/right_pane.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  bool _isSignIn = true;

  void _toggleView() {
    setState(() {
      _isSignIn = !_isSignIn;
      context.read<AuthCubit>().setUnauthenticated();
    });
  }

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
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            if (_isSignIn) {
                              return SignInRightPane(
                                isWide: isWide,
                                onSignUpTap: _toggleView,
                              );
                            } else {
                              return RightPane(
                                isWide: isWide,
                                onSignInTap: _toggleView,
                              );
                            }
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
