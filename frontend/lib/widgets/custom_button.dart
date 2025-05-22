import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final Color color;
  final bool isFullWidth;

  const CustomButton({
    super.key,
    required this.text,
    this.icon,
    this.trailingIcon,
    this.onPressed,
    this.isOutlined = false,
    this.color = const Color(0xFF1DB954),
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isOutlined ? Colors.transparent : color,
        foregroundColor: isOutlined ? color : Colors.white,
        side: isOutlined ? BorderSide(color: color) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      child: Row(
        mainAxisAlignment: trailingIcon == null
            ? MainAxisAlignment.center // Center if no trailing icon
            : MainAxisAlignment.spaceBetween, // Space between if trailing icon exists
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the icon and text within this Row
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: isOutlined ? color : Colors.white,
                    ),
              ),
            ],
          ),
          if (trailingIcon != null)
            Icon(
              trailingIcon,
              size: 20,
              color: Colors.white,
            ),
        ],
      ),
    );
  }
}