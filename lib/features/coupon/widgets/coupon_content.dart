import 'package:flutter/material.dart';

class CouponContent extends StatelessWidget {
  const CouponContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'お好きなドリンク1杯10%OFFでご利用いただけます。',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 10),

          Text(
            '・1商品につき、クーポン券1枚をご利用いただけます。\n'
            '・他の割引サービスとの併用はできません。\n'
            '・割引後の金額はレジにてご確認ください。',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
