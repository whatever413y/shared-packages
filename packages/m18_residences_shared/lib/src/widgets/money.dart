import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_theme.dart';

final NumberFormat _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 0);
final NumberFormat _count = NumberFormat.decimalPattern('en_PH');

/// Whole pesos as shown everywhere in the apps: `₱6,050` (negative: `-₱200`).
String formatPeso(num amount) => _peso.format(amount);

/// A count with thousands separators: `1,234`.
String formatCount(num value) => _count.format(value);

/// An amount in pesos with tabular figures, so amounts line up; [style] defaults to the ambient text style.
class MoneyText extends StatelessWidget {
  final num amount;
  final TextStyle? style;
  final TextAlign? textAlign;

  const MoneyText(this.amount, {super.key, this.style, this.textAlign});

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text(
      formatPeso(amount),
      textAlign: textAlign,
      style: base.copyWith(fontFeatures: AppTheme.tabularFigures),
    );
  }
}
