import 'package:flutter/material.dart';

class CouponNotice extends StatelessWidget {
  const CouponNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '・換金や払い戻しはできません\n'
            '・他の割引サービスとの併用はできません\n'
            '・クーポンの利用は1枚につき1回限りです\n'
            '・商品品切れの際にはご了承ください',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
