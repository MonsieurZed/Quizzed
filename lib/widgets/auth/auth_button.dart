/// Widget de bouton pour l'authentification
///
/// Un bouton personnalisé avec affichage d'état de chargement
/// pour les actions d'authentification

import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const AuthButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.width = double.infinity,
    this.height = 50.0,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      height: height,
      child:
          isOutlined
              ? OutlinedButton(
                onPressed: isLoading ? null : onPressed,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: textColor ?? theme.colorScheme.primary,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(12.0),
                  ),
                  padding: padding,
                ),
                child: _buildChild(theme),
              )
              : ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor ?? theme.colorScheme.primary,
                  foregroundColor: textColor ?? theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(12.0),
                  ),
                  padding: padding,
                ),
                child: _buildChild(theme),
              ),
    );
  }

  Widget _buildChild(ThemeData theme) {
    return isLoading
        ? SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color:
                isOutlined
                    ? (textColor ?? theme.colorScheme.primary)
                    : (textColor ?? theme.colorScheme.onPrimary),
          ),
        )
        : Text(
          text,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: isOutlined ? (textColor ?? theme.colorScheme.primary) : null,
          ),
        );
  }
}
