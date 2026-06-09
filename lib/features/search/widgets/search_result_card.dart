import 'package:flutter/material.dart';
import '../../../core/styles/app_styles.dart';

/// 表示内容: サムネイル画像 / アニメタイトル / 場所名 / 住所 / 詳細ボタン
class SearchResultCard extends StatelessWidget {
  final String title;
  final String place;
  final String address;
  final String? imagePath;
  final VoidCallback? onDetail;

  const SearchResultCard({
    super.key,
    required this.title,
    required this.place,
    required this.address,
    this.imagePath,
    this.onDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // サムネイル画像（左側）
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: SizedBox(
              width: 110,
              height: 110,
              child: imagePath != null
                  ? Image.asset(imagePath!, fit: BoxFit.cover)
                  : Image.asset(
                      'assets/images/place_sample.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade400,
                          size: 36,
                        ),
                      ),
                    ),
            ),
          ),

          // テキスト情報（中央）
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // アニメタイトル
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),

                  const SizedBox(height: 4),

                  // 場所名
                  Text(
                    place,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // 住所
                  Text(
                    address,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ),

          // 詳細ボタン（右側）
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ElevatedButton(
              onPressed: onDetail ?? () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                '詳細',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
