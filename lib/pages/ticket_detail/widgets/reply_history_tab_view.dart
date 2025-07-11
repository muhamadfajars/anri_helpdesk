import 'package:anri/models/reply_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';

class ReplyHistoryTabView extends StatelessWidget {
  final bool isLoadingDetails;
  final List<Reply> replies;
  final bool isResolved;
  final Widget replyForm;

  const ReplyHistoryTabView({
    super.key,
    required this.isLoadingDetails,
    required this.replies,
    required this.isResolved,
    required this.replyForm,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 1,
            shadowColor: Colors.black.withAlpha(26),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                maintainState: true,
                initiallyExpanded: true,
                title: Row(
                  children: [
                    // DIUBAH: Warna ikon dibuat adaptif
                    Icon(Icons.forum_outlined, color: Theme.of(context).textTheme.bodyLarge?.color),
                    const SizedBox(width: 16),
                    // DIUBAH: Warna teks dibuat adaptif
                    Text("Riwayat Balasan (${replies.length})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                children: [
                  const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildRepliesList(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!isResolved)
            _buildTitledCard(
              context: context,
              icon: Icons.reply,
              title: "Balas Tiket",
              child: replyForm,
            ),
        ],
      ),
    );
  }

  Widget _buildRepliesList(BuildContext context) {
    if (isLoadingDetails) {
      return const Center(child: CircularProgressIndicator());
    }
    if (replies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text('Belum ada balasan.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: replies.length,
      separatorBuilder: (context, index) => const Divider(height: 24),
      itemBuilder: (context, index) {
        final reply = replies[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(reply.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  DateFormat('d MMM yy, HH:mm').format(reply.date),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Html(data: reply.message),
          ],
        );
      },
    );
  }

   Widget _buildTitledCard({ required BuildContext context, required IconData icon, required String title, required Widget child }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black.withAlpha(26),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // DIUBAH: Warna ikon dibuat adaptif
                Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color, size: 20),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 24),
            child,
          ],
        ),
      ),
    );
  }
}