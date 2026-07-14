import 'package:flutter/material.dart';

class CouponHowToUse extends StatelessWidget {
  const CouponHowToUse({super.key});

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(title, style: TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        row("1", "アニメ〇〇の聖地〇〇店へ"),
        row("2", "店舗レジにてクーポンを提示し「利用する」をクリック"),
        row("3", "お好きな商品を注文する"),
      ],
    );
  }
}
