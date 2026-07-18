import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../models/comment_model.dart';
import '../../models/message_model.dart';
import '../../models/pixel_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_exception.dart';
import '../../services/pixel_service.dart';
import '../../theme/colors.dart';
import '../../theme/text_styles.dart';
import '../../utils/formatters.dart';
import '../common/loading_widget.dart';

enum _CommentsState { loading, loaded, empty, error }

/// Sección de comentarios en Pixel Detail Screen (spec 9.2): listado
/// público + input para agregar uno nuevo + "Responder privadamente" que
/// abre el chat 1:1 sobre ese píxel (Sprint 6).
///
/// Endpoint propuesto GET/POST /pixels/pixel_comments/ — ver
/// PENDING_BACKEND_ENDPOINTS.md. Si aún no existe en el backend, esta
/// sección muestra el error de forma no intrusiva sin romper el resto de
/// Pixel Detail.
class PixelCommentsWidget extends StatefulWidget {
  final PixelModel pixel;
  const PixelCommentsWidget({super.key, required this.pixel});

  @override
  State<PixelCommentsWidget> createState() => _PixelCommentsWidgetState();
}

class _PixelCommentsWidgetState extends State<PixelCommentsWidget> {
  final _controller = TextEditingController();
  _CommentsState _state = _CommentsState.loading;
  List<CommentModel> _comments = [];
  String? _errorMessage;
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = _CommentsState.loading);
    final userId = context.read<AuthProvider>().user?.id;
    try {
      final comments = await PixelService.instance.getComments(
        widget.pixel.id,
        currentUserId: userId,
      );
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _state = comments.isEmpty ? _CommentsState.empty : _CommentsState.loaded;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _state = _CommentsState.error;
      });
    }
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    final userId = context.read<AuthProvider>().user?.id;
    try {
      final comment = await PixelService.instance.addComment(
        pixelId: widget.pixel.id,
        message: text,
        currentUserId: userId,
      );
      if (!mounted) return;
      _controller.clear();
      setState(() {
        _comments = [comment, ..._comments];
        _state = _CommentsState.loaded;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  void _replyPrivately(CommentModel comment) {
    Navigator.of(context).pushNamed(
      AppRoutes.chatDetail,
      arguments: ChatSummaryModel(
        pixelId: widget.pixel.id,
        pixelImageUrl: widget.pixel.imageUrl,
        pixelOwnerName: comment.authorName,
        lastMessage: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Comentarios (${_comments.length})', style: AppTextStyles.title),
        const SizedBox(height: 10),
        _buildInput(),
        const SizedBox(height: 14),
        _buildList(),
      ],
    );
  }

  Widget _buildInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'Escribe un comentario…'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: _isPosting ? null : _post,
          style: IconButton.styleFrom(backgroundColor: AppColors.primary),
          icon: _isPosting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Icon(Icons.send, size: 18, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildList() {
    switch (_state) {
      case _CommentsState.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: LoadingWidget(compact: true),
        );
      case _CommentsState.error:
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _errorMessage ?? 'No se pudieron cargar los comentarios',
                style: AppTextStyles.caption,
              ),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        );
      case _CommentsState.empty:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Sé el primero en comentar este píxel.',
            style: AppTextStyles.bodySecondary,
          ),
        );
      case _CommentsState.loaded:
        return Column(
          children: _comments
              .map((c) => _CommentTile(
                    comment: c,
                    onReplyPrivately: () => _replyPrivately(c),
                  ))
              .toList(),
        );
    }
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel comment;
  final VoidCallback onReplyPrivately;

  const _CommentTile({required this.comment, required this.onReplyPrivately});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surfaceLight,
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: AppTextStyles.caption,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(comment.authorName, style: AppTextStyles.body),
                    if (comment.createdAt != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        Formatters.timeAgo(comment.createdAt!),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.message, style: AppTextStyles.bodySecondary),
                if (!comment.isMine) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: onReplyPrivately,
                    child: const Text(
                      'Responder privadamente',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
