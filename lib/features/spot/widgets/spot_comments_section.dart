import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/styles/app_dimens.dart';
import '../../../core/styles/app_styles.dart';
import '../../../core/styles/app_text.dart';
import '../../map/services/spot_api.dart';

/// 聖地詳細で共有する公開コメント一覧と投稿導線。
class SpotCommentsSection extends StatefulWidget {
  final String spotId;
  final SpotDetailPayload? initialDetail;

  const SpotCommentsSection({
    super.key,
    required this.spotId,
    this.initialDetail,
  });

  @override
  State<SpotCommentsSection> createState() => _SpotCommentsSectionState();
}

class _SpotCommentsSectionState extends State<SpotCommentsSection> {
  final SpotApi _api = SpotApi();
  List<SpotComment> _comments = const [];
  bool _loading = true;
  bool _canPost = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDetail;
    if (initial == null) {
      _load();
    } else {
      _comments = initial.comments;
      _canPost = initial.canPostComment;
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(SpotCommentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spotId != widget.spotId) {
      _load();
    } else if (!identical(oldWidget.initialDetail, widget.initialDetail) &&
        widget.initialDetail != null) {
      setState(() {
        _comments = widget.initialDetail!.comments;
        _canPost = widget.initialDetail!.canPostComment;
        _loading = false;
      });
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await _api.fetchSpotComments(widget.spotId);
      if (!mounted) return;
      setState(() {
        _comments = result.comments;
        _canPost = result.canPost;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'コメントを読み込めませんでした';
      });
    }
  }

  Future<void> _openComposer() async {
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _SpotCommentComposer(spotId: widget.spotId, api: _api),
    );
    if (posted == true && mounted) await _load();
  }

  Future<void> _deleteComment(SpotComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('コメントを削除しますか？'),
        content: const Text('削除したコメントは元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _api.deleteSpotComment(comment.id);
      if (mounted) await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('みんなのコメント', style: AppTextStyles.subtitle)),
            IconButton(
              tooltip: '再読み込み',
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          _ErrorMessage(message: _errorMessage!, onRetry: _load)
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text('まだコメントはありません', style: AppTextStyles.hint),
          )
        else
          ..._comments.map(
            (comment) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _SpotCommentCard(
                comment: comment,
                onDelete: comment.canDelete
                    ? () => _deleteComment(comment)
                    : null,
              ),
            ),
          ),
        if (_canPost) ...[
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openComposer,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('コメントする'),
            ),
          ),
        ],
      ],
    );
  }
}

/// モーダルが完全に閉じるまで入力コントローラーを保持する投稿フォーム。
class _SpotCommentComposer extends StatefulWidget {
  final String spotId;
  final SpotApi api;

  const _SpotCommentComposer({required this.spotId, required this.api});

  @override
  State<_SpotCommentComposer> createState() => _SpotCommentComposerState();
}

class _SpotCommentComposerState extends State<_SpotCommentComposer> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final comment = _controller.text.trim();
    if (comment.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      await widget.api.createSpotComment(
        spotId: widget.spotId,
        comment: comment,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _controller.text.trim().isNotEmpty && !_sending;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('コメントを投稿', style: AppTextStyles.heading),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              maxLength: 1000,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: '訪問した感想を共有しましょう',
                border: OutlineInputBorder(borderRadius: AppRadius.brSm),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? _submit : null,
                child: _sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('投稿する'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Row(
      children: [
        Expanded(child: Text(message, style: AppTextStyles.hint)),
        TextButton(onPressed: onRetry, child: const Text('再読み込み')),
      ],
    ),
  );
}

class _SpotCommentCard extends StatelessWidget {
  final SpotComment comment;
  final VoidCallback? onDelete;

  const _SpotCommentCard({required this.comment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = comment.avatarUrl;
    final imageUrl = comment.imageUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? const ColoredBox(
                          color: AppColors.placeholder,
                          child: Icon(Icons.person, size: 18),
                        )
                      : CachedNetworkImage(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => const ColoredBox(
                            color: AppColors.placeholder,
                            child: Icon(Icons.person, size: 18),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  comment.username?.isNotEmpty == true
                      ? comment.username!
                      : 'ユーザー',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(_relativeTime(comment.createdAt), style: AppTextStyles.hint),
              if (onDelete != null) ...[
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  tooltip: 'コメントを削除',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline, size: 19),
                  color: AppColors.error,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(comment.comment, style: AppTextStyles.body),
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: AppRadius.brSm,
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: AppColors.placeholder),
                  errorWidget: (_, _, _) =>
                      const ColoredBox(color: AppColors.placeholder),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final difference = DateTime.now().difference(date.toLocal());
    if (difference.inMinutes < 1) return 'たった今';
    if (difference.inHours < 1) return '${difference.inMinutes}分前';
    if (difference.inDays < 1) return '${difference.inHours}時間前';
    if (difference.inDays < 7) return '${difference.inDays}日前';
    return '${date.toLocal().year}/${date.toLocal().month}/${date.toLocal().day}';
  }
}
