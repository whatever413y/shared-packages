import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final bool autofocus;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool enabled;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final int errorMaxLines;

  /// Stable id for browser e2e tests (rendered as `flt-semantics-identifier`); leave null otherwise.
  final String? semanticsId;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.onFieldSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.errorMaxLines = 2,
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: textInputAction,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      onFieldSubmitted: onFieldSubmitted,
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(labelText: labelText, prefixIcon: prefixIcon, suffixIcon: suffixIcon, errorMaxLines: errorMaxLines),
      style: Theme.of(context).textTheme.bodyMedium,
    );

    return semanticsId == null ? field : Semantics(container: true, identifier: semanticsId, child: field);
  }
}
