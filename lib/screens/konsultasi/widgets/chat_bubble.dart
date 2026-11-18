import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constants/consultation_constants.dart';
import '../../../constants/consultation_theme.dart';
import '../../../models/consultation_model.dart';
import '../../../services/attachment_service.dart';
import 'doctor_avatar.dart';

/// Widget bubble pesan chat yang mendukung peran Pasien maupun Dokter.
/// - Bubble pasien: latar biru tua #1F5C7A, teks putih 13, radius 16/16/4/16, status di bawah bubble.
/// - Bubble dokter: latar putih, border krem #EFE3D0, teks #24435A, radius 16/16/16/4, avatar bulat 30.
/// - Memperbaiki bug tinggi bubble dengan mainAxisSize: MainAxisSize.min dan pengecekan lampiran yang ketat.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final String currentUserRole; // 'patient' | 'doctor'
  final String peerPhotoUrl;
  final String peerInitials;
  final DateTime? lastReadByPeerAt;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final String consultationId;
  final String patientUid;

  const ChatBubble({
    super.key,
    required this.message,
    this.currentUserRole = 'patient',
    this.peerPhotoUrl = '',
    this.peerInitials = 'P',
    this.lastReadByPeerAt,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
    this.consultationId = '',
    this.patientUid = '',
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = _formatTime(message.sentAt);

    // ── Kartu Rekomendasi Dokter Khusus ─────────────────────────────────────
    if (message.type == 'consultation_summary') {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1FAF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFE3CE), width: 1.2),
            boxShadow: ConsultationTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.medical_information_rounded,
                      color: ConsultationTheme.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Rekomendasi Dokter',
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: ConsultationTheme.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message.text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF24435A),
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  timeStr,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: ConsultationTheme.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMe = (currentUserRole == 'doctor' && message.isDoctor) ||
        (currentUserRole == 'patient' && message.isPatient);

    final isRead = lastReadByPeerAt != null &&
        (lastReadByPeerAt!.isAfter(message.sentAt) ||
            lastReadByPeerAt!.isAtSameMomentAs(message.sentAt));

    final editLabel = message.isEdited ? 'Diedit • ' : '';

    // Status terkirim / dibaca
    final statusText = isMe
        ? (isRead ? '${editLabel}Dibaca $timeStr ✓✓' : '${editLabel}Terkirim $timeStr ✓')
        : '$editLabel$timeStr';

    // ── Kasus Pesan Dihapus untuk Semua Orang ──────────────────────────────
    if (message.deletedForEveryone) {
      final deletedText =
          isMe ? 'Anda menghapus pesan ini' : 'Pesan ini telah dihapus';
      return InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: isSelected
              ? ConsultationTheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                _buildPeerAvatar(),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isMe ? 16 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.block_rounded,
                            size: 15,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              deletedText,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      timeStr,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: ConsultationTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMe && currentUserRole == 'doctor') ...[
                const SizedBox(width: 8),
                _buildMeAvatar(isMe),
              ],
            ],
          ),
        ),
      );
    }

    // ── Skema Warna & Bentuk Bubble ────────────────────────────────────────
    final Color bubbleColor;
    final Color textColor;
    final Border? bubbleBorder;
    final BorderRadius borderRadius;
    final bool hasTealBackground;

    if (currentUserRole == 'doctor') {
      if (isMe) {
        bubbleColor = ConsultationTheme.primary;
        textColor = Colors.white;
        bubbleBorder = null;
        hasTealBackground = true;
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        );
      } else {
        bubbleColor = Colors.white;
        textColor = const Color(0xFF24435A);
        bubbleBorder = Border.all(color: ConsultationTheme.cardBorder, width: 1);
        hasTealBackground = false;
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        );
      }
    } else {
      // Sisi Pasien
      if (isMe) {
        // Bubble pasien: rata kanan, latar biru tua #1F5C7A, teks putih 13, radius 16/16/4/16
        bubbleColor = ConsultationTheme.primary;
        textColor = Colors.white;
        bubbleBorder = null;
        hasTealBackground = true;
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        );
      } else {
        // Bubble dokter: rata kiri, latar putih, border krem #EFE3D0, teks #24435A, radius 16/16/16/4
        bubbleColor = Colors.white;
        textColor = const Color(0xFF24435A);
        bubbleBorder = Border.all(color: ConsultationTheme.cardBorder, width: 1);
        hasTealBackground = false;
        borderRadius = const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(16),
        );
      }
    }

    // Cek apakah ada lampiran gambar yang valid
    final hasValidImage = message.isImage &&
        message.attachmentUrl != null &&
        message.attachmentUrl!.trim().isNotEmpty;

    // Cek apakah ada lampiran file yang valid
    final hasValidFile = message.isFile &&
        ((message.attachmentUrl != null && message.attachmentUrl!.trim().isNotEmpty) ||
            (message.attachmentId != null && message.attachmentId!.trim().isNotEmpty));

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: isSelected
            ? ConsultationTheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar lawan bicara di kiri
            if (!isMe) ...[
              _buildPeerAvatar(),
              const SizedBox(width: 8),
            ],

            // Bubble konten (bebas bug tinggi besar, mainAxisSize: min)
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      border: bubbleBorder,
                      borderRadius: borderRadius,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0D1F5C7A),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: borderRadius,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Konten Lampiran Gambar ──
                          if (hasValidImage)
                            _buildImageAttachment(context),

                          // ── Konten Lampiran Dokumen PDF ──
                          if (hasValidFile)
                            _buildFileAttachment(context, hasTealBackground),

                          // ── Teks Pesan (atau Caption) ──
                          if (message.text.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Text(
                                message.text,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
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

                  // Waktu & Status di Bawah Bubble
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusText,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: ConsultationTheme.secondaryText,
                        ),
                      ),
                      if (!isMe &&
                          ConsultationConstants.kShowAutoReplyLabel &&
                          message.isAutoReply) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: ConsultationTheme.lightBlue,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Balasan otomatis',
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: ConsultationTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Avatar diri sendiri (hanya jika role dokter)
            if (isMe && currentUserRole == 'doctor') ...[
              const SizedBox(width: 8),
              _buildMeAvatar(isMe),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeerAvatar() {
    if (currentUserRole == 'patient') {
      return DoctorAvatar(
        photoUrl: peerPhotoUrl,
        size: 30,
        isCircle: true,
      );
    }
    return CircleAvatar(
      radius: 15,
      backgroundColor: ConsultationTheme.lightBlue,
      child: Text(
        peerInitials,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: ConsultationTheme.primary,
        ),
      ),
    );
  }

  Widget _buildMeAvatar(bool isMe) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: ConsultationTheme.primary.withValues(alpha: 0.12),
      child: const Icon(
        Icons.medical_services_rounded,
        size: 15,
        color: ConsultationTheme.primary,
      ),
    );
  }

  Widget _buildImageAttachment(BuildContext context) {
    final rawUrl = message.attachmentUrl ?? '';
    final url = rawUrl.trim();
    if (url.isEmpty) return const SizedBox.shrink();

    final isBase64 = url.startsWith('data:image');

    Widget imageWidget;
    if (isBase64) {
      try {
        final base64String = url.split(',').last;
        final bytes = base64Decode(base64String);
        imageWidget = Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: 180,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 140,
            color: Colors.black12,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      );
    } else {
      imageWidget = Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 180,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
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

  Widget _buildFileAttachment(BuildContext context, bool hasDarkBg) {
    final fileName = message.fileName ?? 'Dokumen.pdf';
    final fileSize = _formatFileSize(message.effectiveFileSize);

    return InkWell(
      onTap: () => _openDocument(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: hasDarkBg
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.04),
          border: Border(
            bottom: BorderSide(
              color: hasDarkBg ? Colors.white24 : Colors.black12,
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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: hasDarkBg
                          ? Colors.white
                          : ConsultationTheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fileSize,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: hasDarkBg
                          ? Colors.white70
                          : ConsultationTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new_rounded,
              size: 16,
              color: hasDarkBg ? Colors.white70 : ConsultationTheme.secondaryText,
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
    if (message.attachmentId != null && message.attachmentId!.isNotEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  SizedBox(width: 16),
                  Text('Memuat dokumen...', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        final data = await AttachmentService.instance.loadAttachment(
          patientUid: patientUid,
          consultationId: consultationId,
          attachmentId: message.attachmentId!,
        );

        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        if (data == null) {
          if (context.mounted) {
            showConsultationSnackBar(
              context,
              message: 'Dokumen tidak ditemukan atau telah dihapus.',
              isError: true,
            );
          }
          return;
        }

        if (!context.mounted) return;
        _showAttachmentDetailsSheet(context, data);
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          showConsultationSnackBar(
            context,
            message: 'Gagal memuat dokumen: $e',
            isError: true,
          );
        }
      }
      return;
    }

    final url = message.attachmentUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showAttachmentDetailsSheet(
      BuildContext context, AttachmentData data) {
    final fileName = data.fileName;
    final mimeType = data.mimeType;
    final sizeBytes = data.sizeBytes;
    final bytes = data.bytes;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9CDB8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded,
                      color: Color(0xFFD32F2F), size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: ConsultationTheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_formatFileSize(sizeBytes)} • $mimeType',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: ConsultationTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: ConsultationTheme.cardBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: ConsultationTheme.secondaryText,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Simpan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ConsultationTheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      if (bytes.isEmpty) return;
                      try {
                        final ext = fileName.split('.').last;
                        final savedPath = await FilePicker.platform.saveFile(
                          dialogTitle: 'Simpan $fileName',
                          fileName: fileName,
                          type: FileType.custom,
                          allowedExtensions: [ext],
                          bytes: bytes,
                        );
                        if (savedPath != null && context.mounted) {
                          showConsultationSnackBar(
                            context,
                            message: 'Berkas disimpan di $savedPath',
                            isSuccess: true,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showConsultationSnackBar(
                            context,
                            message: 'Gagal menyimpan berkas: $e',
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String url;
  final bool isBase64;

  const _FullScreenImageViewer({required this.url, required this.isBase64});

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (isBase64) {
      final base64String = url.split(',').last;
      img = Image.memory(base64Decode(base64String), fit: BoxFit.contain);
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      img = Image.network(url, fit: BoxFit.contain);
    } else {
      img = Image.asset(url, fit: BoxFit.contain);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(child: img),
      ),
    );
  }
}
