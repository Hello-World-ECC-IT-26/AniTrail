import 'package:flutter/material.dart';

class UserInfoSection extends StatelessWidget {
  const UserInfoSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // アバター（未設定時はグレーの人アイコン）
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
            ),
            child: const Icon(Icons.person),
          ),
          const SizedBox(width: 12),

          // ユーザー名・スタンプ数
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('かなや', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text('集めたスタンプ数：10', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),

          // 通知ボタン（TODO: 通知画面へ遷移）
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
