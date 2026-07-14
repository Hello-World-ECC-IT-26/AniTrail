import 'package:flutter/material.dart';

class NavigationMascot extends StatelessWidget {
  const NavigationMascot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 112,
      height: 132,
      child: Image.asset(
        'assets/images/weasel.png',
        fit: BoxFit.contain,
        cacheWidth: 224,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
