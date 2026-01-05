import 'package:flutter/cupertino.dart';

class MediaPickerTheme {
  const MediaPickerTheme({
    this.appBarBgColor,
    this.appBarTextColor,
    this.appBarBack,
    this.appBarClose,
    this.appBarArrowDown,
    this.arrowRight,
    this.selectedTextColor,
    this.selectedColor,
    this.selectedGradient,
    this.preview,
    this.confirm,
  });

  final Color? appBarBgColor;
  final Color? appBarTextColor;
  final Widget? appBarBack;
  final Widget? appBarClose;
  final Widget? appBarArrowDown;
  final Widget? arrowRight;
  final Color? selectedTextColor;
  final Color? selectedColor;
  final Gradient? selectedGradient;
  final Widget Function(VoidCallback? onTap)? preview;
  final Widget Function(String title, VoidCallback? onTap)? confirm;
}
