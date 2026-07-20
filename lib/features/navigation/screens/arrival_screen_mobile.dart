import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/loading_screen.dart';
import '../../coupon/data/coupon_repository.dart';
import '../../coupon/models/coupon.dart';
import '../../coupon/widgets/coupon_detail.dart';
import '../../coupon/widgets/coupon_grant_dialog.dart';
import '../../home/screens/home_screen.dart';
import '../../map/models/anime_spot.dart';
import '../../map/services/spot_api.dart';
import '../../spot/screens/spot_comments_screen.dart';
import '../../stamp/screens/stamp_screen.dart';
import '../../stamp/widgets/stamp_badge.dart';

enum ArrivalFlowStep { choice, confirmPhoto, submitting, error, earned }

class ArrivalScreen extends StatefulWidget {
  const ArrivalScreen({
    super.key,
    required this.spot,
    required this.cardId,
    required this.stampCount,
    required this.stampTotal,
    this.imageUrl,
    this.spotApi,
    this.imagePicker,
  });

  final Spot spot;
  final String cardId;
  final int stampCount;
  final int stampTotal;
  final String? imageUrl;
  final SpotApi? spotApi;
  final ImagePicker? imagePicker;

  @override
  State<ArrivalScreen> createState() => _ArrivalScreenState();
}

class _ArrivalScreenState extends State<ArrivalScreen> {
  late final SpotApi _spotApi = widget.spotApi ?? SpotApi();
  late final ImagePicker _imagePicker = widget.imagePicker ?? ImagePicker();
  final String _stampId = const Uuid().v4();
  final DateTime _obtainedAt = DateTime.now();

  ArrivalFlowStep _step = ArrivalFlowStep.choice;
  XFile? _photo;
  Object? _submitError;
  bool _couponDialogShown = false;

  Map<String, String> get _authHeaders {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return token == null ? const {} : {'Authorization': 'Bearer $token'};
  }

  Future<void> _takePhoto() async {
    try {
      final photo = await _imagePicker.pickImage(source: ImageSource.camera);
      if (!mounted || photo == null) return;
      setState(() {
        _photo = photo;
        _step = ArrivalFlowStep.confirmPhoto;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('カメラを起動できませんでした: $error')));
    }
  }

  Future<void> _submit({required bool withPhoto}) async {
    if (_step == ArrivalFlowStep.submitting ||
        _step == ArrivalFlowStep.earned) {
      return;
    }
    setState(() {
      _step = ArrivalFlowStep.submitting;
      _submitError = null;
    });
    try {
      final photo = withPhoto ? _photo : null;
      final result = await _spotApi.createArrivalStamp(
        cardId: widget.cardId,
        spotId: widget.spot.spotId,
        stampId: _stampId,
        obtainedAt: _obtainedAt,
        imageBytes: photo == null ? null : await photo.readAsBytes(),
        imageFilename: photo?.name,
        imageContentType: photo?.mimeType,
      );
      if (!mounted) return;
      final appDataRepository = context.read<AppDataRepository?>();
      if (appDataRepository != null) {
        unawaited(appDataRepository.load(refresh: true));
      }
      setState(() => _step = ArrivalFlowStep.earned);
      if (result.newGrants.isNotEmpty && !_couponDialogShown) {
        _couponDialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_showEarnedCoupons(result.newGrants));
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error;
        _step = ArrivalFlowStep.error;
      });
    }
  }

  Future<void> _showEarnedCoupons(List<CouponGrant> grants) async {
    final viewCoupons = await showCouponGrantDialog(context, grants);
    if (!mounted) return;
    final repository = context.read<CouponRepository>();
    try {
      await Future.wait(
        grants.map((grant) => repository.markGrantSeen(grant.grantId)),
      );
      if (!viewCoupons || !mounted) return;
      if (repository.category != null) {
        await repository.setCategory(null);
      } else {
        await repository.load(refresh: true);
      }
      if (!mounted) return;
      if (grants.length == 1) {
        final coupon = repository.coupons
            .where((item) => item.id == grants.single.couponId)
            .firstOrNull;
        if (coupon != null) {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => CouponDetailScreen(coupon: coupon),
            ),
          );
          return;
        }
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 3)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('クーポン情報を更新できませんでした: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step != ArrivalFlowStep.submitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: switch (_step) {
          ArrivalFlowStep.choice => _buildChoice(),
          ArrivalFlowStep.confirmPhoto => _buildPhotoConfirmation(),
          ArrivalFlowStep.submitting => const AppLoadingScreen(
            message: 'スタンプと写真を保存しています・・・',
            imageSize: 220,
          ),
          ArrivalFlowStep.error => _buildError(),
          ArrivalFlowStep.earned => _buildEarned(),
        },
      ),
    );
  }

  Widget _buildChoice() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                  ),
                ),
                Text(
                  '聖地に到着！',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    color: const Color(0xFF12265A),
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: AppRadius.brLg,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _destinationImage(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  widget.spot.name,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title,
                ),
                if ((widget.spot.animeTitle ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'アニメ「${widget.spot.animeTitle}」',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body,
                  ),
                ],
                const SizedBox(height: AppSpacing.xxl),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6FF),
                    borderRadius: AppRadius.brLg,
                  ),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/weasel.png',
                        height: 128,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text('記念の写真を残しますか？', style: AppTextStyles.subtitle),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: '写真を撮って獲得',
                        icon: Icons.camera_alt_outlined,
                        onPressed: _takePhoto,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: '写真なしで獲得',
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _submit(withPhoto: false),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoConfirmation() {
    final photo = _photo;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => setState(() {
                    _photo = null;
                    _step = ArrivalFlowStep.choice;
                  }),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Text(
                    '撮影した写真',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.heading,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.brMd,
                child: photo == null
                    ? const ColoredBox(color: AppColors.placeholder)
                    : Image.file(
                        File(photo.path),
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text('この写真を使いますか？', style: AppTextStyles.subtitle),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: '撮り直す',
                    variant: AppButtonVariant.secondary,
                    onPressed: _takePhoto,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton(
                    label: '写真を使う',
                    onPressed: () => _submit(withPhoto: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 54,
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('保存できませんでした', style: AppTextStyles.title),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$_submitError',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: '再試行',
                  onPressed: () => _submit(withPhoto: _photo != null),
                ),
                if (_photo != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: '写真を使わず獲得',
                    variant: AppButtonVariant.secondary,
                    onPressed: () {
                      _photo = null;
                      _submit(withPhoto: false);
                    },
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: '戻る',
                  variant: AppButtonVariant.text,
                  onPressed: () =>
                      setState(() => _step = ArrivalFlowStep.choice),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarned() {
    return SizedBox.expand(
      key: const ValueKey('arrival-earned-background'),
      child: ColoredBox(
        color: const Color(0xFF172238),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stampSize = math.min(constraints.maxWidth * 0.78, 330.0);
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight - AppSpacing.xxl - AppSpacing.lg,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'スタンプ獲得！',
                        style: AppTextStyles.title.copyWith(
                          color: AppColors.white,
                          fontSize: 34,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      StampBadge(label: widget.spot.name, size: stampSize),
                      const SizedBox(height: AppSpacing.md),
                      if ((widget.spot.animeTitle ?? '').isNotEmpty)
                        Text(
                          'アニメ「${widget.spot.animeTitle}」',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                      SizedBox(
                        width: 280,
                        child: AppButton(
                          label: 'コレクションを見る',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StampScreen(
                                cardId: widget.cardId,
                                animeId: widget.spot.animeId,
                                animeTitle: widget.spot.animeTitle,
                                recentlyObtainedSpotId: widget.spot.spotId,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: 280,
                        child: AppButton(
                          label: 'コメントする',
                          variant: AppButtonVariant.secondary,
                          icon: Icons.edit_outlined,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SpotCommentsScreen(
                                spot: widget.spot,
                                animeTitle: widget.spot.animeTitle ?? '',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          '閉じる',
                          style: TextStyle(color: AppColors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _destinationImage() {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      return const ColoredBox(
        color: AppColors.placeholder,
        child: Icon(Icons.image_outlined, color: AppColors.iconMuted),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: _authHeaders,
      fit: BoxFit.cover,
      placeholder: (_, _) => const ColoredBox(color: AppColors.placeholder),
      errorWidget: (_, _, _) => const ColoredBox(
        color: AppColors.placeholder,
        child: Icon(Icons.image_outlined, color: AppColors.iconMuted),
      ),
    );
  }
}
