import 'package:flutter/material.dart';

class CustomDropdownForm<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final T? value;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final bool isExpanded;
  final EdgeInsetsGeometry contentPadding;

  /// Stable id for browser e2e tests (rendered as `flt-semantics-identifier`); leave null otherwise.
  final String? semanticsId;

  const CustomDropdownForm({
    super.key,
    required this.label,
    this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    this.validator,
    this.isExpanded = true,
    this.contentPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    this.semanticsId,
  });

  @override
  Widget build(BuildContext context) {
    final dropdown = DropdownButtonFormField<T>(
      isExpanded: isExpanded,
      decoration: InputDecoration(labelText: label, hintText: hint, border: const OutlineInputBorder(), contentPadding: contentPadding),
      initialValue: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );

    return semanticsId == null ? dropdown : Semantics(container: true, identifier: semanticsId, child: dropdown);
  }
}
