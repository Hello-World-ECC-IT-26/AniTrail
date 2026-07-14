import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/styles/app_styles.dart';
import '../../../core/widgets/app_bar.dart';
import '../../../core/widgets/main_buttom_nav.dart';
import '../../auth/services/auth_service.dart';
import '../../profile/services/profile_service.dart';
import '../../profile/widgets/subscription.dart';

class MyPageScreen extends StatefulWidget {
  const MyPageScreen({super.key});

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  // 編集モードフラグ
  bool _isEditing = false;
  bool _saving = false;
  final _imagePicker = ImagePicker();
  XFile? _selectedAvatar;
  Uint8List? _selectedAvatarBytes;
  UserProfile? _profile;

  // ユーザー情報
  final _nameController = TextEditingController();

  String get _email => Supabase.instance.client.auth.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      await AuthService().ensureProfile();
      final profile = await ProfileService().fetchMyProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (!_isEditing) _nameController.text = profile.username ?? '';
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('プロフィールを読み込めませんでした: $error')));
    }
  }

  // 保存処理
  Future<void> _saveEdit() async {
    if (_saving) return;
    final username = _nameController.text.trim();
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ユーザー名を入力してください')));
      return;
    }
    setState(() => _saving = true);
    try {
      final avatar = _selectedAvatar;
      if (avatar != null) {
        await AuthService().uploadAvatar(avatar);
      }
      final profile = await ProfileService().updateUsername(username);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _selectedAvatar = null;
        _isEditing = false;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('プロフィール写真を保存できませんでした: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectAvatar() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedAvatar = image;
        _selectedAvatarBytes = bytes;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('写真を選択できませんでした: $error')));
    }
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
    final avatarUrl = _profile?.avatarUrl;
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
                    onPressed: _saving
                        ? null
                        : _isEditing
                        ? _saveEdit
                        : () => setState(() => _isEditing = true),
                    child: Text(
                      _saving
                          ? '保存中'
                          : _isEditing
                          ? '保存'
                          : '編集',
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
                    child: _selectedAvatarBytes != null
                        ? Image.memory(_selectedAvatarBytes!, fit: BoxFit.cover)
                        : avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey.shade400,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey.shade400,
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
                        _selectAvatar();
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
                            _profile?.username ?? '',
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
                  const Divider(height: 1, indent: 16, endIndent: 16),
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
