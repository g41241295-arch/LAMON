import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/app_colors.dart';
import '../../../models/consultation_model.dart';
import 'doctor_avatar.dart';

/// Widget bubble pesan chat yang mendukung peran Pasien maupun Dokter.
/// - Bubble sendiri selalu di sebelah kanan.
/// - Bubble lawan bicara di sebelah kiri.
/// - Mendukung teks, gambar (zoomable), dan dokumen PDF.
/// - Menampilkan status "Dibaca HH.mm" atau "Terkirim HH.mm".
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String currentUserRole; // 'patient' | 'doctor'
  final String peerPhotoUrl;
  final String peerInitials;
  final DateTime? lastReadByPeerAt;

  const ChatBubble({
    super.key,
    required this.message,
    this.currentUserRole = 'patient',
    this.peerPhotoUrl = '',
    this.peerInitials = 'P',
    this.lastReadByPeerAt,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = (currentUserRole == 'doctor' && message.isDoctor) ||
        (currentUserRole == 'patient' && message.isPatient);
    final timeStr = _formatTime(message.sentAt);

    // Cek apakah pesan sudah dibaca lawan bicara
    final isRead = lastReadByPeerAt != null &&
        (lastReadByPeerAt!.isAfter(message.sentAt) ||
            lastReadByPeerAt!.isAtSameMomentAs(message.sentAt));

    final statusText = isMe ? (isRead ? 'Dibaca $timeStr' : 'Terkirim $timeStr') : timeStr;

    // Skema warna bubble
    Color bubbleColor;
    Color textColor;
    Border? bubbleBorder;

    if (isMe) {
      if (currentUserRole == 'doctor') {
        // Bubble dokter (milik sendiri): kuning lembut
        bubbleColor = const Color(0xFFFFF7D6);
        textColor = AppColors.primaryText;
        bubbleBorder = Border.all(color: const Color(0xFFF0E4B0), width: 1);
      } else {
        // Bubble pasien (milik sendiri): teal-biru
        bubbleColor = AppColors.primary;
        textColor = Colors.white;
      }
    } else {
      // Bubble lawan bicara: biru lembut
      bubbleColor = const Color(0xFFEDF5FA);
      textColor = AppColors.primaryText;
      bubbleBorder = Border.all(color: const Color(0xFFD6E8F3), width: 1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar lawan bicara (kiri)
          if (!isMe) ...[
            if (currentUserRole == 'patient')
              DoctorAvatar(
                photoUrl: peerPhotoUrl,
                size: 32,
                borderRadius: 10,
              )
            else
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                child: Text(
                  peerInitials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],

          // Bubble konten
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    border: bubbleBorder,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Konten Lampiran Gambar ──
                        if (message.isImage && message.hasAttachment)
                          _buildImageAttachment(context),

                        // ── Konten Lampiran Dokumen PDF ──
                        if (message.isFile && message.hasAttachment)
                          _buildFileAttachment(context, isMe),

                        // ── Teks Pesan (atau Caption) ──
                        if (message.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: textColor,
                                height: 1.4,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusText,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutralGray,
                  ),
                ),
              ],
            ),
          ),

          // Avatar diri sendiri (kanan)
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: isMe && currentUserRole == 'doctor'
                  ? const Color(0xFFFFF0B3)
                  : AppColors.primaryLight.withValues(alpha: 0.25),
              child: Icon(
                currentUserRole == 'doctor'
                    ? Icons.medical_services_rounded
                    : Icons.person_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageAttachment(BuildContext context) {
    final url = message.attachmentUrl!;
    final isBase64 = url.startsWith('data:image');

    Widget imageWidget;
    if (isBase64) {
      final base64String = url.split(',').last;
      final bytes = base64Decode(base64String);
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
      );
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 180,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          height: 120,
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        ),
      );
    } else {
      imageWidget = Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, _, _) => Container(
          height: 120,
          color: Colors.black12,
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.grey),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openFullScreenImage(context, url, isBase64),
      child: Hero(
        tag: 'img_${message.id}_$url',
        child: imageWidget,
      ),
    );
  }

  Widget _buildFileAttachment(BuildContext context, bool isMe) {
    final fileName = message.fileName ?? 'Dokumen.pdf';
    final fileSize = _formatFileSize(message.fileSize);

    return InkWell(
      onTap: () => _openDocument(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe && currentUserRole == 'patient'
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(
              color: isMe && currentUserRole == 'patient' ? Colors.white24 : Colors.black12,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFD32F2F),
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isMe && currentUserRole == 'patient'
                          ? Colors.white
                          : AppColors.primaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileSize,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMe && currentUserRole == 'patient'
                          ? Colors.white70
                          : AppColors.neutralGray,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: isMe && currentUserRole == 'patient'
                  ? Colors.white70
                  : AppColors.neutralGray,
            ),
          ],
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String url, bool isBase64) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(url: url, isBase64: isBase64),
      ),
    );
  }

  Future<void> _openDocument(BuildContext context) async {
    final url = message.attachmentUrl;
    if (url == null || url.isEmpty) return;

    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tidak dapat membuka file dokumen ini.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return 'PDF';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }
}

/// Layar Full Screen Image Viewer dengan InteractiveViewer (pinch-to-zoom).
class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  final bool isBase64;

  const _FullScreenImageViewer({required this.url, required this.isBase64});

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (isBase64) {
      final base64String = url.split(',').last;
      final bytes = base64Decode(base64String);
      imageWidget = Image.memory(bytes, fit: BoxFit.contain);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(url, fit: BoxFit.contain);
    } else {
      imageWidget = Image.asset(url, fit: BoxFit.contain);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Tutup',
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: imageWidget,
        ),
      ),
    );
  }
}
