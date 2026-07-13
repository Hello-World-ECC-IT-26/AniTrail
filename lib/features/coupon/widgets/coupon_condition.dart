import 'package:flutter/material.dart';

class CouponCondition extends StatelessWidget {
  const CouponCondition({super.key});

  Widget row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 80,
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
        row("対象商品", "ドリンクorフード1品（10%OFF）"),
        row("有効期限", "2026年10月31日"),
        row("対象店舗", "アニメ〇〇の聖地　〇〇店"),
      ],
    );
  }
}
