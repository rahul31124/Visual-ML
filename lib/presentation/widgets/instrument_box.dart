import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InstrumentBox extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? titleBoxColor;
  final Color? titleColor;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry contentPadding;
  final EdgeInsetsGeometry margin;
  final double? height;
  final double? width;
  final double titleFontSize;
  final VoidCallback? onTap;

  const InstrumentBox({
    super.key,
    required this.title,
    required this.child,
    this.titleBoxColor,
    this.titleColor,
    this.borderColor,
    this.backgroundColor,
    this.borderWidth = 1.0,
    this.borderRadius = 10.0,
    this.contentPadding = const EdgeInsets.fromLTRB(10, 14, 10, 10),
    this.margin = const EdgeInsets.only(bottom: 12),
    this.height,
    this.width,
    this.titleFontSize = 12.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    final effectiveTitleBoxColor = titleBoxColor ?? Colors.white;
    final effectiveTitleColor = titleColor ?? AppColors.deepGreen;
    final effectiveBorderColor = borderColor ?? AppColors.green;
    final effectiveBgColor = backgroundColor ?? Colors.white;

    Widget boxStack = Stack(
      children: [
        Container(
          height: height,
          width: width ?? double.infinity,
          margin: const EdgeInsets.only(top: 8, bottom: 4),
          decoration: BoxDecoration(
            color: effectiveBgColor,
            border: Border.all(width: borderWidth, color: effectiveBorderColor),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: contentPadding,
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 1,
          child: Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(color: effectiveTitleBoxColor),
              child: Text(
                title,
                style: TextStyle(
                  color: effectiveTitleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: titleFontSize,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );

    if (onTap != null) {
      boxStack = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: boxStack,
      );
    }

    if (margin != EdgeInsets.zero) {
      return Padding(
        padding: margin,
        child: boxStack,
      );
    }

    return boxStack;
  }
}
