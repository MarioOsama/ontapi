import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../logic/auth_cubit.dart';
import 'auth_header.dart';
import 'auth_input_field.dart';
import 'auth_primary_button.dart';

class RightPaneStageTwo extends StatefulWidget {
  final String email;
  final String password;
  final bool isLoading;

  const RightPaneStageTwo({
    super.key,
    required this.email,
    required this.password,
    this.isLoading = false,
  });

  @override
  State<RightPaneStageTwo> createState() => RightPaneStageTwoState();
}

class RightPaneStageTwoState extends State<RightPaneStageTwo> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Uint8List? _logoBytes;
  String? _logoExt;
  String? _logoName;

  Future<void> _pickLogo() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'gif'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.size > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File exceeds 5MB limit')));
        return;
      }
      setState(() {
        _logoBytes = file.bytes;
        _logoExt = file.extension;
        _logoName = file.name;
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().signUp(
        email: widget.email,
        password: widget.password,
        businessName: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        logoBytes: _logoBytes,
        logoExtension: _logoExt,
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
              step: '2',
              title: 'Set up your workspace',
              subtitle:
                  'Tell us about your organization to personalize your dashboard.',
              progress: 1.0,
            ),
            const SizedBox(height: 32),
            AuthInputField(
              label: 'Workspace Name',
              hint: 'e.g. Smile Dental Clinic',
              icon: Icons.storefront_outlined,
              controller: _nameCtrl,
              validator: (val) =>
                  (val == null || val.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 24),
            AuthInputField(
              label: 'Workspace Description',
              hint: 'Briefly describe your services...',
              icon: Icons.description_outlined,
              maxLines: 4,
              controller: _descCtrl,
            ),
            const SizedBox(height: 24),
            Text('Brand Logo', style: AppTextStyles.inputLabel),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickLogo,
              borderRadius: BorderRadius.circular(12),
              child: DottedBorder(
                options: const RoundedRectDottedBorderOptions(
                  color: AppColors.borderMedium,
                  strokeWidth: 2,
                  dashPattern: [6, 4],
                  radius: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 12),
                      if (_logoBytes != null)
                        Text(
                          _logoName ?? 'Logo selected',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else ...[
                        RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                            children: [
                              TextSpan(
                                text: 'Upload a file',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' or drag and drop'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG, GIF up to 5MB',
                          style: AppTextStyles.label,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            AuthPrimaryButton(
              text: 'Finish Setup',
              icon: Icons.check_circle_outline,
              onPressed: _submit,
              isLoading: widget.isLoading,
            ),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () => context.read<AuthCubit>().backToStageOne(),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                label: Text(
                  'Back to previous step',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
