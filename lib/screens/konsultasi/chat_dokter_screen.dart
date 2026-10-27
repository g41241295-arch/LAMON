import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import '../../services/notification_service.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/doctor_avatar.dart';

/// Layar Chat Interaktif (dipakai bersama oleh Pasien maupun Dokter).
///
/// Menggunakan StreamBuilder dari Firestore untuk tampilan pesan real-time.
/// Mematuhi spesifikasi:
/// - Subjudul menampilkan status konsultasi ("Konsultasi Berlangsung" / "Menunggu Konfirmasi" / "Konsultasi Selesai"), tanpa status kehadiran palsu.
/// - Banner peringatan jika konsultasi masih menunggu konfirmasi.
/// - Read receipt ("Dibaca" / "Terkirim") sinkron antara kedua belah pihak.
class ChatDokterScreen extends StatefulWidget {
  final String consultationId;
  final bool isDoctor;
  final String? patientUid;
  final ConsultationModel? initialConsultation;

  const ChatDokterScreen({
    super.key,
    required this.consultationId,
    this.isDoctor = false,
    this.patientUid,
    this.initialConsultation,
  });

  @override
  State<ChatDokterScreen> createState() => _ChatDokterScreenState();
}

class _ChatDokterScreenState extends State<ChatDokterScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  ConsultationModel? _consultation;
  StreamSubscription<ConsultationModel?>? _consultationSub;
  bool _isSending = false;
  bool _isUploading = false;
  bool _hasLoadedConsultation = false;

  // Selected attachment state
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  String? _attachmentType; // 'image' | 'file'
  String? _attachmentMimeType;
  int? _attachmentSize;

  @override
  void initState() {
    super.initState();
    ChatInAppNotificationService.instance.currentActiveConsultationId =
        widget.consultationId;
    _consultation = widget.initialConsultation;
    if (_consultation != null) {
      _hasLoadedConsultation = true;
    }

    // Mulai listen dengan patientUid yang tersedia saat ini.
    // Jika initialConsultation sudah ada, patientUid sudah tersedia.
    _listenConsultation();

    // Muat data awal jika belum ada, lalu re-listen dengan patientUid yang benar.
    _loadInitialConsultation();

    // Reset unread segera setelah widget ter-build (via addPostFrameCallback)
    // agar badge hilang begitu dokter membuka layar chat.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markRead();
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    if (ChatInAppNotificationService.instance.currentActiveConsultationId ==
        widget.consultationId) {
      ChatInAppNotificationService.instance.currentActiveConsultationId = null;
    }
    _consultationSub?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadInitialConsultation() async {
    if (_consultation == null) {
      final data = await _consultationService.fetchById(
        widget.consultationId,
        patientUid: widget.patientUid,
      );
      if (mounted && data != null) {
        setState(() {
          _consultation = data;
          _hasLoadedConsultation = true;
        });
        // Re-listen dengan patientUid yang kini sudah tersedia.
        _listenConsultation();
        _markRead();
      }
    }
  }

  String? get _effectivePatientUid =>
      widget.patientUid ?? _consultation?.patientUid;

  void _listenConsultation() {
    _consultationSub = _consultationService
        .watchConsultation(widget.consultationId,
            patientUid: _effectivePatientUid)
        .listen((c) {
      if (mounted && c != null) {
        setState(() {
          _consultation = c;
          _hasLoadedConsultation = true;
        });
      }
    }, onError: (e) {
      debugPrint('[ChatDokterScreen] watchConsultation error: $e');
    });
  }

  void _markRead() {
    _consultationService.markChatAsRead(
      consultationId: widget.consultationId,
      role: widget.isDoctor ? 'doctor' : 'patient',
      patientUid: _effectivePatientUid,
    );
  }

  void _clearAttachment() {
    setState(() {
      _attachmentBytes = null;
      _attachmentName = null;
      _attachmentType = null;
      _attachmentMimeType = null;
      _attachmentSize = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 70,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran gambar maksimal 5 MB.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() {
        _attachmentBytes = bytes;
        _attachmentName = picked.name;
        _attachmentType = 'image';
        _attachmentMimeType = 'image/jpeg';
        _attachmentSize = bytes.lengthInBytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _pickDocument() async {
    try {
            final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      if (bytes.lengthInBytes > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ukuran dokumen maksimal 5 MB.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      setState(() {
        _attachmentBytes = bytes;
        _attachmentName = file.name;
        _attachmentType = 'file';
        _attachmentMimeType = 'application/pdf';
        _attachmentSize = bytes.lengthInBytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih dokumen: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Pilih Lampiran',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppColors.primary),
                  ),
                  title: const Text('Kamera',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Ambil foto langsung',
                      style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.photo_library_rounded,
                        color: AppColors.primary),
                  ),
                  title: const Text('Galeri',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Pilih gambar dari galeri HP',
                      style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded,
                        color: Color(0xFFD32F2F)),
                  ),
                  title: const Text('Dokumen (PDF)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Lampirkan hasil lab / berkas medis',
                      style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDocument();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    final hasAttachment = _attachmentBytes != null;

    if ((text.isEmpty && !hasAttachment) || _isSending || _isUploading) return;

    setState(() {
      _isSending = true;
      if (hasAttachment) _isUploading = true;
    });

    String? uploadedUrl;
    final attachBytes = _attachmentBytes;
    final attachName = _attachmentName;
    final attachType = _attachmentType ?? 'text';
    final attachMime = _attachmentMimeType ?? 'text/plain';
    final attachSize = _attachmentSize;

    if (hasAttachment && attachBytes != null) {
      try {
        uploadedUrl = await _consultationService.uploadAttachment(
          consultationId: widget.consultationId,
          bytes: attachBytes,
          fileName: attachName ?? 'file',
          mimeType: attachMime,
          patientUid: _effectivePatientUid,
        );
      } catch (e) {
        debugPrint('[ChatDokterScreen] Upload Storage gagal: $e');
        if (attachType == 'image') {
          final base64Data = base64Encode(attachBytes);
          uploadedUrl = 'data:$attachMime;base64,$base64Data';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Penyimpanan dokumen PDF membutuhkan Firebase Storage aktif: $e'),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          setState(() {
            _isSending = false;
            _isUploading = false;
          });
          return;
        }
      }
    }

    _inputController.clear();
    _clearAttachment();

    try {
      await _consultationService.sendMessage(
        consultationId: widget.consultationId,
        senderType: widget.isDoctor ? 'doctor' : 'patient',
        text: text,
        patientUid: _effectivePatientUid,
        type: hasAttachment ? attachType : 'text',
        attachmentUrl: uploadedUrl,
        fileName: attachName,
        fileSize: attachSize,
        mimeType: attachMime,
        doctorId: _consultation?.doctorId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pesan: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _isUploading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showSelesaikanKonsultasiDialog() async {
    final shouldComplete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Selesaikan Konsultasi?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Apakah Anda yakin ingin menyelesaikan sesi konsultasi ini? Setelah diselesaikan, percakapan akan ditutup dan masuk ke riwayat konsultasi pasien.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (shouldComplete == true) {
      try {
        await _consultationService.completeConsultation(
          consultationId: widget.consultationId,
          patientUid: _effectivePatientUid,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sesi konsultasi telah diselesaikan.'),
              backgroundColor: AppColors.successGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyelesaikan konsultasi: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildPatientHeaderAvatar() {
    final photoUrl = _consultation?.patientPhotoUrl?.trim() ?? '';
    if (photoUrl.isNotEmpty && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, _) {},
      );
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        _consultation?.patientInitials ?? 'P',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildCompletedBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.successGreen, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Konsultasi telah selesai',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleName = widget.isDoctor
        ? (_consultation?.displayPatientName ?? 'Pasien')
        : (_consultation?.doctorName ?? 'Dokter');

    final isWaiting = _consultation?.isWaiting ?? false;
    final isCompleted = _consultation?.isCompleted ?? false;
    final String statusLabel;
    final Color statusColor;
    if (isWaiting) {
      statusLabel = 'Menunggu Konfirmasi';
      statusColor = AppColors.warningYellow;
    } else if (isCompleted) {
      statusLabel = 'Konsultasi Selesai';
      statusColor = AppColors.neutralGray;
    } else {
      statusLabel = 'Konsultasi Berlangsung';
      statusColor = AppColors.successGreen;
    }

    final Widget chatContent = Stack(
      fit: StackFit.expand,
      children: [
        // ── Background Pola Khusus Chat Konsultasi Dokter (Full Cover) ──
        Positioned.fill(
          child: Image.asset(
            'assets/images/Background Chat Konsultasi Dokter.png',
            fit: BoxFit.cover,
          ),
        ),

        // ── Layar Chat Transparan di atas Background ──
        Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.94),
            elevation: 0.5,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primaryText),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Kembali',
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                if (widget.isDoctor)
                  _buildPatientHeaderAvatar()
                else
                  DoctorAvatar(
                    photoUrl: _consultation?.effectiveDoctorPhotoUrl ?? '',
                    doctorId: _consultation?.doctorId,
                    doctorName: _consultation?.doctorName,
                    size: 36,
                    borderRadius: 10,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        titleName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (widget.isDoctor && (_consultation?.isActive ?? false))
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor:
                          AppColors.successGreen.withValues(alpha: 0.12),
                      foregroundColor: AppColors.successGreen,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: _showSelesaikanKonsultasiDialog,
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 16),
                    label: const Text(
                      'Selesai',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // ── Banner Menunggu Konfirmasi Dokter (Sisi Pasien) ──
                if (isWaiting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEA),
                      border: Border(
                        bottom: BorderSide(color: AppColors.warningYellow.withValues(alpha: 0.4)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isDoctor
                                ? 'Permintaan konsultasi ini belum dikonfirmasi aktif.'
                                : 'Menunggu konfirmasi dokter. Anda tetap dapat mengirim pesan.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Area Chat Pesan ──
                Expanded(
                  child: !_hasLoadedConsultation
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: AppColors.primary))
                      : StreamBuilder<List<ChatMessage>>(
                          stream: _consultationService.watchMessages(
                            widget.consultationId,
                            patientUid: _effectivePatientUid,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.error_outline_rounded,
                                          size: 40, color: Colors.red.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Gagal memuat pesan: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.neutralGray),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              );
                            }

                            final messages = snapshot.data ?? [];

                            // Scroll ke bawah saat ada pesan baru
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) => _scrollToBottom());

                            if (messages.isEmpty) {
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  return SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          minHeight: constraints.maxHeight),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 20),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: const Color(0xFFE2ECF2),
                                                width: 1.2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.04),
                                                  blurRadius: 10,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.chat_bubble_outline_rounded,
                                                  size: 52,
                                                  color: AppColors.primary
                                                      .withValues(alpha: 0.75),
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  widget.isDoctor
                                                      ? 'Belum ada pesan dengan pasien ini'
                                                      : 'Mulai percakapan dengan dokter',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.primaryText,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }

                            final peerPhoto = widget.isDoctor
                                ? (_consultation?.patientPhotoUrl ?? '')
                                : (_consultation?.effectiveDoctorPhotoUrl ?? '');

                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              itemCount: messages.length,
                              itemBuilder: (_, i) => ChatBubble(
                                message: messages[i],
                                currentUserRole: widget.isDoctor ? 'doctor' : 'patient',
                                peerPhotoUrl: peerPhoto,
                                peerInitials: _consultation?.patientInitials ?? 'P',
                                lastReadByPeerAt: widget.isDoctor
                                    ? _consultation?.lastReadByPatientAt
                                    : _consultation?.lastReadByDoctorAt,
                              ),
                            );
                          },
                        ),
                ),

                // ── Bar Pratinjau Lampiran (jika ada yang dipilih) ──
                if (_attachmentBytes != null) _buildAttachmentPreviewBar(),

                // ── Kolom Input Bar Menempel di atas Keyboard / Bar Selesai ──
                if (isCompleted)
                  _buildCompletedBar()
                else
                  _buildInputBar(context),
              ],
            ),
          ),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 520;
        if (isLargeScreen) {
          final maxH = constraints.maxHeight.isFinite
              ? constraints.maxHeight.clamp(0.0, 880.0)
              : 860.0;
          return Scaffold(
            backgroundColor: AppColors.desktopBackground,
            body: Center(
              child: Container(
                width: 420,
                height: maxH,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.12),
                    width: 3,
                  ),
                ),
                child: chatContent,
              ),
            ),
          );
        }
        return chatContent;
      },
    );
  }

  Widget _buildAttachmentPreviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          if (_attachmentType == 'image')
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                _attachmentBytes!,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Color(0xFFD32F2F),
                size: 28,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _attachmentName ?? 'Lampiran',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _attachmentSize != null
                      ? '${(_attachmentSize! / 1024).toStringAsFixed(1)} KB'
                      : '',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutralGray,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 20, color: AppColors.neutralGray),
            onPressed: _clearAttachment,
            tooltip: 'Hapus lampiran',
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Tombol Lampiran (+)
            IconButton(
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primary,
                size: 26,
              ),
              onPressed: (_isSending || _isUploading)
                  ? null
                  : _showAttachmentOptions,
              tooltip: 'Lampirkan file atau foto',
            ),

            // Input Teks
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Tulis pesan...',
                    hintStyle: TextStyle(
                      color: AppColors.neutralGray,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Tombol Kirim
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: _isSending || _isUploading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _sendMessage,
                      tooltip: 'Kirim pesan',
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
