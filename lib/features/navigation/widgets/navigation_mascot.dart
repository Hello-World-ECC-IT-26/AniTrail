import 'package:flutter/material.dart';

class NavigationMascot extends StatelessWidget {
  const NavigationMascot({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // GIFの透明な余白を含めて配置し、デザイン上の見た目の大きさを合わせる。
      width: 226,
      height: 320,
      child: Image.asset(
        'assets/images/weasel_walk.gif',
        fit: BoxFit.contain,
        cacheWidth: 452,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
