import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.placeholder,
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Text(
              'ロゴ',
              style: TextStyle(color: AppColors.iconMuted, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
