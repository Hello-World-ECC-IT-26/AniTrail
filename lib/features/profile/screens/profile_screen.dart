import 'package:flutter/material.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../profile/widgets/subscription.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // 編集モードフラグ
  bool _isEditing = false;

  // ユーザー情報
  final _nameController = TextEditingController(text: 'まーくん');
  final String _email = 'xxxxxxxxxx@ecc.ac.jp';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // 保存処理
  void _saveEdit() {
    setState(() => _isEditing = false);
    // TODO: Supabaseへ保存
  }

  // ログアウト確認ダイアログ
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          '確認',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'ログアウトしてもよろしいでしょうか？',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          // キャンセル
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'キャンセル',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
          ),

          // ログアウト
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: ログアウト処理 → ログイン画面へ遷移
            },
            child: const Text(
              'ログアウト',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      // アプリバー
      appBar: const AniTrailAppBar(),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── ヘッダーバー（戻る + タイトル + 編集/保存） ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'アカウント情報',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // 編集 / 保存ボタン
                  TextButton(
                    onPressed: _isEditing
                        ? _saveEdit
                        : () => setState(() => _isEditing = true),
                    child: Text(
                      _isEditing ? '保存' : '編集',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── アバター ──────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // アバター画像
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/avatar_sample.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ),

                // 編集中: カメラアイコンオーバーレイ
                if (_isEditing)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        // TODO: 画像選択
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 18,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 32),
            const Divider(height: 1, indent: 16, endIndent: 16),

            // ── ユーザー情報フィールド ──────────────────
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // 名前フィールド
                  _buildInfoRow(
                    label: '名前',
                    child: _isEditing
                        ? TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                        : Text(
                            _nameController.text,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                  ),

                  const Divider(height: 1, indent: 16, endIndent: 16),

                  // アドレスフィールド（編集不可）
                  _buildInfoRow(
                    label: 'アドレス',
                    child: Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 360),
            // ── サブスクリプション ──────────────────────
            const Divider(height: 1, indent: 16, endIndent: 16),
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) => const SubscriptionSheet(),
                  );
                },

                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                ),
                child: const Text(
                  'サブスクリプション',
                  style: TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            const SizedBox(height: 8),

            // ── ログアウト ────────────────────────────
            Container(
              color: Colors.white,
              width: double.infinity,
              child: TextButton(
                onPressed: _showLogoutDialog,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'ログアウト',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),

      // ── ボトムナビゲーション ──────────────────────
      bottomNavigationBar: MainBottomNav(onTap: (index) {}),
    );
  }

  // ── 情報行（ラベル + コンテンツ） ──────────────────────
  Widget _buildInfoRow({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
