import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:talent_foot_connect/services/social_service.dart';
import 'package:talent_foot_connect/social/contact_filter.dart';
import 'package:talent_foot_connect/theme/app_colors.dart';
import 'package:talent_foot_connect/widgets/register_widgets.dart';

class CommentsSheet extends StatefulWidget {
  const CommentsSheet({super.key, required this.postId});

  final String postId;

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _social = SocialService();
  final _body = TextEditingController();
  late Future<List<FeedComment>> _future;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _social.commentsFor(widget.postId);
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _body.text.trim();
    if (containsContact(text)) {
      await showAppError(context, contactBlockedMessage);
      return;
    }
    setState(() => _sending = true);
    try {
      await _social.addComment(postId: widget.postId, body: text);
      _body.clear();
      setState(() => _future = _social.commentsFor(widget.postId));
    } catch (e) {
      if (!mounted) return;
      await showAppError(context, mapAuthError(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Text(
              'COMMENTAIRES',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<FeedComment>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.mint),
                    );
                  }
                  final comments = snapshot.data ?? const <FeedComment>[];
                  if (comments.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucun commentaire.',
                        style: GoogleFonts.inter(color: AppColors.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.authorName,
                            style: GoogleFonts.montserrat(
                              fontWeight: FontWeight.w700,
                              color: AppColors.mint,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            comment.body,
                            style: GoogleFonts.inter(color: AppColors.textPrimary),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _body,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Commenter sans numéro',
                        hintStyle: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send, color: AppColors.orange),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
