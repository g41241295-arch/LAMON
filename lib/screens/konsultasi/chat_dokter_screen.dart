import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/consultation_constants.dart';
import '../../models/consultation_model.dart';
import '../../services/attachment_service.dart';
import '../../services/consultation_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_date_formatter.dart';
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
  final bool readOnly;

  const ChatDokterScreen({
    super.key,
    required this.consultationId,
    this.isDoctor = false,
    this.patientUid,
    this.initialConsultation,
    this.readOnly = false,
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
  Stream<List<ChatMessage>>? _messagesStream;
  String? _currentStreamPatientUid;
  bool _isSending = false;
  bool _isUploading = false;
  bool _isCompleting = false;
  bool _hasLoadedConsultation = false;
  int _previousMessageCount = 0;
  bool _hasShownPatientPopup = false;

  // Status kirim lampiran gagal & tombol coba lagi (Revisi 12 Bagian B.2.5)
  Map<String, dynamic>? _failedAttachment;

  Future<void> _retryFailedAttachment() async {
    if (_failedAttachment == null) return;
    final failed = Map<String, dynamic>.from(_failedAttachment!);
    setState(() {
      _attachmentBytes = failed['bytes'] as Uint8List?;
      _attachmentName = failed['name'] as String?;
      _attachmentType = failed['type'] as String?;
      _attachmentMimeType = failed['mime'] as String?;
      _attachmentSize = failed['size'] as int?;
      _inputController.text = failed['text'] as String? ?? '';
      _failedAttachment = null;
    });
    await _sendMessage();
  }

  // Selected & Edit Message state (Bagian C)
  ChatMessage? _selectedMessage;
  ChatMessage? _editingMessage;
  String? _editingOriginalText;
  List<ChatMessage> _lastVisibleMessages = [];
  List<ChatMessage> _getVisibleMessages() => _lastVisibleMessages;

  /// Template pesan cepat untuk pasien (Bagian B)
  static const List<String> _patientTemplates = [
    'Dokter, saya merasakan nyeri di bagian perut atas sejak beberapa hari.',
    'Apakah gejala yang saya alami ini berbahaya?',
    'Saya sudah minum obat yang diresepkan, tapi belum membaik.',
    'Terima kasih dok, saya akan mengikuti sarannya.',
    'Apakah ada pantangan makanan yang perlu saya hindari?',
    'Kapan sebaiknya saya kembali periksa, dok?',
  ];

  // Selected attachment state
  Uint8List? _attachmentBytes;
  String? _attachmentName;
  String? _attachmentType; // 'image' | 'file'
  String? _attachmentMimeType;
  int? _attachmentSize;

  bool _isMyMessage(ChatMessage msg) {
    if (widget.isDoctor) {
      return msg.isDoctor;
    } else {
      return msg.isPatient;
    }
  }

  bool _isConsultationActiveOrWaiting() {
    final c = _consultation;
    if (c == null) return false;
    return c.isActive || c.isWaiting;
  }

  bool _canEdit(ChatMessage msg) {
    if (msg.type == 'consultation_summary') return false;
    if (msg.deletedForEveryone) return false;
    if (msg.type != 'text') return false;
    if (!_isMyMessage(msg)) return false;
    if (!_isConsultationActiveOrWaiting()) return false;
    final elapsed = DateTime.now().difference(msg.sentAt);
    return elapsed <= ConsultationConstants.kEditWindow;
  }

  bool _canDeleteForEveryone(ChatMessage msg) {
    if (msg.type == 'consultation_summary') return false;
    if (msg.deletedForEveryone) return false;
    if (!_isMyMessage(msg)) return false;
    if (!_isConsultationActiveOrWaiting()) return false;
    final elapsed = DateTime.now().difference(msg.sentAt);
    return elapsed <= ConsultationConstants.kDeleteForEveryoneWindow;
  }

  bool _canHideForMe(ChatMessage msg) {
    if (msg.type == 'consultation_summary') return false;
    if (msg.deletedForEveryone) return false;
    if (!_isConsultationActiveOrWaiting()) return false;
    return true;
  }

  bool _canDelete(ChatMessage msg) {
    return _canHideForMe(msg) || _canDeleteForEveryone(msg);
  }

  void _copySelectedMessage() {
    final msg = _selectedMessage;
    if (msg == null) return;
    if (msg.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: msg.text));
      _showAppSnackBar('Teks disalin ke papan klip', isSuccess: true);
    }
    setState(() => _selectedMessage = null);
  }

  void _startEditSelectedMessage() {
    final msg = _selectedMessage;
    if (msg == null) return;
    setState(() {
      _editingMessage = msg;
      _editingOriginalText = msg.text;
      _inputController.text = msg.text;
      _inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: msg.text.length),
      );
      _selectedMessage = null;
    });
    _focusNode.requestFocus();
  }

  void _cancelEdit() {
    setState(() {
      _editingMessage = null;
      _editingOriginalText = null;
      _inputController.clear();
    });
  }

  Future<void> _saveEditedMessage(List<ChatMessage> visibleMessages) async {
    final msg = _editingMessage;
    if (msg == null) return;

    final newText = _inputController.text.trim();
    if (newText.isEmpty) {
      _showAppSnackBar('Pesan tidak boleh kosong.', isError: true);
      return;
    }

    if (newText == _editingOriginalText) {
      _cancelEdit();
      return;
    }

    final isLast = visibleMessages.isNotEmpty && visibleMessages.last.id == msg.id;

    try {
      await _consultationService.editMessage(
        consultationId: widget.consultationId,
        messageId: msg.id,
        newText: newText,
        patientUid: _effectivePatientUid,
        isLastMessage: isLast,
      );
      _showAppSnackBar('Pesan berhasil diedit', isSuccess: true);
    } catch (e) {
      _showAppSnackBar('Gagal mengedit pesan: $e', isError: true);
    } finally {
      _cancelEdit();
    }
  }

  Future<void> _showDeleteMessageDialog(List<ChatMessage> visibleMessages) async {
    final msg = _selectedMessage;
    if (msg == null) return;

    final canDeleteEveryone = _canDeleteForEveryone(msg);
    final isLast = visibleMessages.isNotEmpty && visibleMessages.last.id == msg.id;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Hapus pesan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          canDeleteEveryone
              ? 'Anda dapat menghapus pesan ini hanya untuk Anda, atau untuk semua orang di obrolan ini.'
              : 'Pesan ini akan dihapus dari obrolan di perangkat Anda saja.',
          style: const TextStyle(fontSize: 13, color: AppColors.primaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _selectedMessage = null);
              final myUid = _consultationService.currentUid ?? '';
              try {
                await _consultationService.hideMessageForMe(
                  consultationId: widget.consultationId,
                  messageId: msg.id,
                  myUid: myUid,
                  patientUid: _effectivePatientUid,
                );
              } catch (e) {
                _showAppSnackBar('Gagal menghapus pesan: $e', isError: true);
              }
            },
            child: const Text('Hapus untuk saya', style: TextStyle(color: Colors.red)),
          ),
          if (canDeleteEveryone)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _selectedMessage = null);
                try {
                  await _consultationService.deleteMessageForEveryone(
                    consultationId: widget.consultationId,
                    messageId: msg.id,
                    patientUid: _effectivePatientUid,
                    isLastMessage: isLast,
                  );
                } catch (e) {
                  _showAppSnackBar('Gagal menghapus pesan: $e', isError: true);
                }
              },
              child: const Text('Hapus untuk semua orang'),
            ),
        ],
      ),
    );
  }

  void _showAppSnackBar(String message, {bool isError = false, bool isSuccess = false}) {
    if (!mounted) return;
    final color = isError
        ? Colors.red
        : (isSuccess ? AppColors.successGreen : AppColors.primary);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    ChatInAppNotificationService.instance.currentActiveConsultationId =
        widget.consultationId;
    _consultation = widget.initialConsultation;
    if (_consultation != null) {
      _hasLoadedConsultation = true;
      _checkAndShowPatientCompletionPopup(_consultation!);
    }

    _initMessagesStream();
    _listenConsultation();
    _loadInitialConsultation();

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

  void _initMessagesStream() {
    final pUid = _effectivePatientUid;
    final resolvedUid = (pUid != null && pUid.isNotEmpty)
        ? pUid
        : (!widget.isDoctor ? _consultationService.currentUid : null);

    if (resolvedUid != null && resolvedUid.isNotEmpty) {
      if (_messagesStream == null || _currentStreamPatientUid != resolvedUid) {
        _currentStreamPatientUid = resolvedUid;
        _messagesStream = _consultationService.watchMessages(
          widget.consultationId,
          patientUid: resolvedUid,
        );
      }
    }
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
          _initMessagesStream();
        });
        _listenConsultation();
        _markRead();
        _checkAndShowPatientCompletionPopup(data);
      }
    }
  }

  String? get _effectivePatientUid =>
      widget.patientUid ?? _consultation?.patientUid;

  void _listenConsultation() {
    _consultationSub?.cancel();
    _consultationSub = _consultationService
        .watchConsultation(widget.consultationId,
            patientUid: _effectivePatientUid)
        .listen((c) {
      if (mounted && c != null) {
        setState(() {
          _consultation = c;
          _hasLoadedConsultation = true;
          _initMessagesStream();
        });
        _checkAndShowPatientCompletionPopup(c);
      }
    }, onError: (e) {
      debugPrint('[ChatDokterScreen] watchConsultation error: $e');
    });
  }

  void _markRead() {
    if (widget.readOnly) return;
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
        _showAppSnackBar('Ukuran gambar maksimal 5 MB.', isError: true);
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
      _showAppSnackBar('Gagal memilih gambar: $e', isError: true);
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

      if (bytes.lengthInBytes > ConsultationConstants.kMaxAttachmentBytes) {
        _showAppSnackBar(
          'Ukuran file melebihi 700 KB. Kompres atau kirim file yang lebih kecil.',
          isError: true,
        );
        return;
      }

      setState(() {
        _attachmentBytes = bytes;
        _attachmentName = file.name;
        _attachmentType = 'file';
        _attachmentMimeType = 'application/pdf';
        _attachmentSize = bytes.lengthInBytes;
        _failedAttachment = null;
      });
    } catch (e) {
      _showAppSnackBar('Gagal memilih dokumen: $e', isError: true);
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
    String? attachmentId;
    final attachBytes = _attachmentBytes;
    String? attachName = _attachmentName;
    final attachType = _attachmentType ?? 'text';
    String attachMime = _attachmentMimeType ?? 'text/plain';
    int? attachSize = _attachmentSize;

    if (hasAttachment && attachBytes != null) {
      if (attachType == 'image') {
        // Alur gambar tetap base64 data URL seperti sebelumnya
        final base64Data = base64Encode(attachBytes);
        uploadedUrl = 'data:$attachMime;base64,$base64Data';
      } else {
        // Alur dokumen PDF: simpan berkas di Firestore via AttachmentService (tanpa Firebase Storage)
        try {
          final meta = await AttachmentService.instance.saveAttachment(
            patientUid: _effectivePatientUid!,
            consultationId: widget.consultationId,
            bytes: attachBytes,
            fileName: attachName ?? 'Dokumen.pdf',
            mimeType: attachMime,
            senderType: widget.isDoctor ? 'doctor' : 'patient',
          );
          attachmentId = meta.attachmentId;
          attachName = meta.fileName;
          attachMime = meta.mimeType;
          attachSize = meta.sizeBytes;
        } on AttachmentSizeException catch (sizeErr) {
          _showAppSnackBar(sizeErr.message, isError: true);
          setState(() {
            _isSending = false;
            _isUploading = false;
          });
          return;
        } catch (e) {
          debugPrint('[ChatDokterScreen] Upload dokumen Firestore gagal: $e');
          setState(() {
            _isSending = false;
            _isUploading = false;
            _failedAttachment = {
              'bytes': attachBytes,
              'name': attachName,
              'type': attachType,
              'mime': attachMime,
              'size': attachSize,
              'text': text,
              'error': e.toString(),
            };
          });
          _showAppSnackBar('Gagal mengirim file. Coba lagi.', isError: true);
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
        attachmentId: attachmentId,
        fileName: attachName,
        fileSize: attachSize,
        sizeBytes: attachSize,
        mimeType: attachMime,
        doctorId: _consultation?.doctorId,
      );
      setState(() {
        _failedAttachment = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (hasAttachment) {
        setState(() {
          _failedAttachment = {
            'bytes': attachBytes,
            'name': attachName,
            'type': attachType,
            'mime': attachMime,
            'size': attachSize,
            'text': text,
            'error': e.toString(),
          };
        });
        _showAppSnackBar('Gagal mengirim file. Coba lagi.', isError: true);
      } else {
        _showAppSnackBar('Gagal mengirim pesan: $e', isError: true);
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
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    final patientName = _consultation?.displayPatientName ?? 'Pasien';
    final doctorId =
        _consultation?.doctorId ?? _consultationService.currentUid ?? '';

    final success = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SelesaikanKonsultasiDialog(
        patientName: patientName,
        onConfirm: (recommendation) async {
          await _consultationService.completeConsultationWithRecommendation(
            consultationId: widget.consultationId,
            recommendation: recommendation,
            doctorId: doctorId,
            patientUid: _effectivePatientUid,
          );
        },
      ),
    );

    if (mounted) {
      setState(() => _isCompleting = false);
    }

    if (success == true && mounted) {
      _showAppSnackBar('Konsultasi diselesaikan', isSuccess: true);
      // D.3: Setelah sukses: tutup pop-up, snackbar, kembali ke daftar Pesan (pindah ke tab Selesai)
      Navigator.pop(context);
    }
  }

  void _checkAndShowPatientCompletionPopup(ConsultationModel c) {
    if (widget.isDoctor) return;
    if (!c.isCompleted) return;
    if (c.completionSeenByPatient) return;
    if (_hasShownPatientPopup) return;

    _hasShownPatientPopup = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showPatientCompletionPopup(c);
    });
  }

  Future<void> _showPatientCompletionPopup(ConsultationModel c) async {
    final rec = c.doctorRecommendation?.trim() ?? '';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.successGreen, size: 24),
            SizedBox(width: 8),
            Text(
              'Konsultasi Selesai',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dokter telah menyelesaikan sesi konsultasi ini.',
              style: TextStyle(fontSize: 13, color: AppColors.primaryText),
            ),
            if (rec.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.assignment_turned_in_rounded,
                            size: 14, color: AppColors.successGreen),
                        SizedBox(width: 6),
                        Text(
                          'Rekomendasi Dokter',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rec,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF15803D),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );

    _consultationService.markCompletionSeenByPatient(
      consultationId: widget.consultationId,
      patientUid: _effectivePatientUid,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    if (widget.isDoctor) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE9E2D3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            AppDateFormatter.formatChatDateSeparator(date),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B8190),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2ECF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          AppDateFormatter.formatChatDateSeparator(date),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeaderAvatar() {
    final photoUrl = _consultation?.patientPhotoUrl?.trim() ?? '';
    if (photoUrl.isNotEmpty && (photoUrl.startsWith('http://') || photoUrl.startsWith('https://'))) {
      return CircleAvatar(
        radius: 19,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(photoUrl),
        onBackgroundImageError: (_, _) {},
      );
    }
    return CircleAvatar(
      radius: 19,
      backgroundColor: Colors.white,
      child: Text(
        _consultation?.patientInitials ?? 'P',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F5C7A),
        ),
      ),
    );
  }

  Widget _buildCompletedBar() {
    final completedAt = _consultation?.completedAt;
    final timeStr = completedAt != null
        ? AppDateFormatter.formatFullDateTime(completedAt)
        : '';
    final text = timeStr.isNotEmpty
        ? 'Konsultasi telah selesai pada $timeStr'
        : 'Konsultasi telah selesai';

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
            Flexible(
              child: Text(
                text,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
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
    final isCompleted = widget.readOnly || (_consultation?.isCompleted ?? false);
    final String statusLabel;
    final Color statusColor;
    if (isCompleted) {
      statusLabel = 'Konsultasi Selesai';
      statusColor = AppColors.neutralGray;
    } else if (isWaiting) {
      statusLabel = 'Menunggu Konfirmasi';
      statusColor = AppColors.warningYellow;
    } else {
      statusLabel = 'Konsultasi Berlangsung';
      statusColor = AppColors.successGreen;
    }

    final schedStr = AppDateFormatter.formatScheduledDateTime(
      _consultation?.effectiveScheduledDate,
      _consultation?.scheduledTime,
    );
    final subtitleText = schedStr.isNotEmpty
        ? '$statusLabel • $schedStr'
        : statusLabel;

    final Widget chatContent = Stack(
      fit: StackFit.expand,
      children: [
        // ── Background Chat: Solid krem/off-white untuk Dokter, atau pola untuk Pasien ──
        Positioned.fill(
          child: widget.isDoctor
              ? Container(
                  color: const Color(0xFFFAF6F0),
                )
              : Image.asset(
                  'assets/images/Background Chat Konsultasi Dokter.png',
                  fit: BoxFit.cover,
                ),
        ),

        // ── Layar Chat Transparan di atas Background ──
        Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.transparent,
          appBar: _selectedMessage != null
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 1,
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.primaryText),
                    onPressed: () => setState(() => _selectedMessage = null),
                    tooltip: 'Batal seleksi',
                  ),
                  title: const Text(
                    '1 pesan dipilih',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  actions: [
                    if (!_selectedMessage!.deletedForEveryone &&
                        _selectedMessage!.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.copy_rounded,
                            color: AppColors.primaryText),
                        tooltip: 'Salin',
                        onPressed: _copySelectedMessage,
                      ),
                    if (_canEdit(_selectedMessage!))
                      IconButton(
                        icon: const Icon(Icons.edit_rounded,
                            color: AppColors.primaryText),
                        tooltip: 'Edit pesan',
                        onPressed: _startEditSelectedMessage,
                      ),
                    if (_canDelete(_selectedMessage!))
                      Builder(
                        builder: (btnCtx) => IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.primaryText),
                          tooltip: 'Hapus pesan',
                          onPressed: () =>
                              _showDeleteMessageDialog(_getVisibleMessages()),
                        ),
                      ),
                    const SizedBox(width: 8),
                  ],
                )
              : (widget.isDoctor
                  ? AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      toolbarHeight: 74,
                      flexibleSpace: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1F5C7A), Color(0xFF2E85A8)],
                          ),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(28),
                          ),
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Kembali',
                      ),
                      titleSpacing: 0,
                      title: Row(
                        children: [
                          _buildPatientHeaderAvatar(),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  titleName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '• Sedang online',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        if (!widget.readOnly &&
                            (_consultation?.isActive ?? false))
                          Padding(
                            padding: const EdgeInsets.only(right: 14),
                            child: GestureDetector(
                              onTap: _isCompleting
                                  ? null
                                  : _showSelesaikanKonsultasiDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isCompleting)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    else
                                      Text(
                                        '✓ Selesai',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : AppBar(
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
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
                                    Flexible(
                                      child: Text(
                                        subtitleText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: statusColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
          body: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: Column(
              children: [
                // ── Banner Menunggu Konfirmasi Dokter ──
                if (!isCompleted && isWaiting)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: widget.isDoctor
                          ? const Color(0xFFFCFBF7)
                          : const Color(0xFFFFFBEA),
                      border: Border(
                        bottom: BorderSide(
                          color: widget.isDoctor
                              ? const Color(0xFFEBE3D0)
                              : AppColors.warningYellow.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.hourglass_top_rounded,
                          size: 16,
                          color: widget.isDoctor
                              ? const Color(0xFF9E652B)
                              : const Color(0xFFB45309),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isDoctor
                                ? 'Permintaan konsultasi ini belum dikonfirmasi aktif.'
                                : 'Menunggu konfirmasi dokter. Anda tetap dapat mengirim pesan.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: widget.isDoctor
                                  ? const Color(0xFF9E652B)
                                  : const Color(0xFFB45309),
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
                          stream: _messagesStream ??
                              _consultationService.watchMessages(
                                widget.consultationId,
                                patientUid: _effectivePatientUid,
                              ),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              debugPrint('[ChatDokterScreen] watchMessages error: ${snapshot.error}');
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
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _initMessagesStream();
                                          });
                                        },
                                        icon: const Icon(Icons.refresh_rounded, size: 16),
                                        label: const Text('Coba Lagi'),
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

                            final allMessages = snapshot.data ?? [];
                            final myUid = _consultationService.currentUid ?? '';
                            final visibleMessages = allMessages
                                .where((m) => !m.hiddenFor.contains(myUid))
                                .toList();
                            _lastVisibleMessages = visibleMessages;

                            // Auto-scroll ke pesan terbaru:
                            // 1. Saat pertama kali chat dibuka / pesan dimuat
                            // 2. Saat pesan baru masuk dan user sedang berada di dekat bagian bawah
                            if (visibleMessages.isNotEmpty) {
                              if (_previousMessageCount == 0) {
                                _previousMessageCount = visibleMessages.length;
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) => _scrollToBottom());
                              } else if (visibleMessages.length > _previousMessageCount) {
                                final isNearBottom = !_scrollController.hasClients ||
                                    (_scrollController.position.maxScrollExtent -
                                            _scrollController.offset <=
                                        120);
                                _previousMessageCount = visibleMessages.length;
                                if (isNearBottom) {
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) => _scrollToBottom());
                                }
                              } else {
                                _previousMessageCount = visibleMessages.length;
                              }
                            }

                            if (visibleMessages.isEmpty) {
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
                              itemCount: visibleMessages.length,
                              itemBuilder: (_, i) {
                                final msg = visibleMessages[i];
                                final showDateSeparator = i == 0 ||
                                    !_isSameDay(visibleMessages[i - 1].createdAt,
                                        msg.createdAt);

                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (showDateSeparator)
                                      _buildDateSeparator(msg.createdAt),
                                    ChatBubble(
                                      message: msg,
                                      consultationId: widget.consultationId,
                                      patientUid: _effectivePatientUid ?? '',
                                      currentUserRole: widget.isDoctor
                                          ? 'doctor'
                                          : 'patient',
                                      peerPhotoUrl: peerPhoto,
                                      peerInitials:
                                          _consultation?.patientInitials ?? 'P',
                                      lastReadByPeerAt: widget.isDoctor
                                          ? _consultation?.lastReadByPatientAt
                                          : _consultation?.lastReadByDoctorAt,
                                      isSelected: _selectedMessage?.id == msg.id,
                                      onLongPress: () {
                                        if (msg.type == 'consultation_summary' || isCompleted) return;
                                        setState(() => _selectedMessage = msg);
                                      },
                                      onTap: () {
                                        if (_selectedMessage != null) {
                                          setState(() => _selectedMessage = null);
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                ),

                // ── Indikator Upload Lampiran (Revisi 12 Bagian B.2.5) ──
                if (_isUploading) _buildUploadingIndicatorBar(),

                // ── Banner Gagal Kirim Lampiran & Tombol Coba Lagi (Revisi 12 Bagian B.2.5) ──
                if (_failedAttachment != null) _buildFailedAttachmentBar(),

                // ── Bar Pratinjau Lampiran (jika ada yang dipilih) ──
                if (_attachmentBytes != null) _buildAttachmentPreviewBar(),

                // ── Banner Mengedit Pesan (Bagian C.2) ──
                if (_editingMessage != null) _buildEditingBanner(),

                // ── Template Pesan Cepat Langsung Tampil Tanpa Tombol Petir (Bagian B) ──
                if (!isCompleted &&
                    !widget.isDoctor &&
                    _editingMessage == null &&
                    (isWaiting || (_consultation?.isActive ?? false)))
                  _buildTemplateSuggestions(),

                // ── Kolom Input Bar Menempel di atas Keyboard / Bar Selesai ──
                if (isCompleted)
                  _buildCompletedBar()
                else
                  _buildInputBar(context, _lastVisibleMessages),
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
              ? constraints.maxHeight
              : 860.0;
          return Scaffold(
            backgroundColor: AppColors.desktopBackground,
            resizeToAvoidBottomInset: false,
            body: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: maxH,
                ),
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
            ),
          );
        }
        return chatContent;
      },
    );
  }

  Widget _buildUploadingIndicatorBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mengirim file...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailedAttachmentBar() {
    final fileName = _failedAttachment?['name'] as String? ?? 'Berkas';
    final errStr = _failedAttachment?['error'] as String? ?? '';
    final shortErr = errStr.length > 50 ? '${errStr.substring(0, 50)}...' : errStr;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.red.shade50,
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Gagal mengirim $fileName. Coba lagi.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade900,
                  ),
                ),
                if (shortErr.isNotEmpty)
                  Text(
                    shortErr,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red.shade700,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _retryFailedAttachment,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          IconButton(
            onPressed: () => setState(() => _failedAttachment = null),
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: Colors.red.shade700,
          ),
        ],
      ),
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

  Widget _buildEditingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Mengedit pesan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  _editingOriginalText ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF64748B)),
            onPressed: _cancelEdit,
            tooltip: 'Batal edit',
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorQuickActionChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
      alignment: Alignment.centerLeft,
      color: Colors.transparent,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildDoctorChip(
              label: 'Jadwalkan kontrol',
              templateText:
                  'Silakan jadwalkan konsultasi kontrol kembali dalam 3-5 hari ke depan.',
            ),
            const SizedBox(width: 8),
            _buildDoctorChip(
              label: 'Saran makanan',
              templateText:
                  'Disarankan untuk mengonsumsi makanan yang mudah dicerna, rendah lemak, dan hindari makanan pedas serta asam.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorChip({
    required String label,
    required String templateText,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _inputController.text = templateText;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        });
        _focusNode.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFBFD9E6), width: 1.2),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F5C7A),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, List<ChatMessage> visibleMessages) {
    final isEditing = _editingMessage != null;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isDoctor && !isEditing && !widget.readOnly)
            _buildDoctorQuickActionChips(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDoctor ? const Color(0xFFFAF6F0) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Tombol Lampiran (+)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    color: isEditing
                        ? AppColors.neutralGray
                        : (widget.isDoctor
                            ? const Color(0xFF1F5C7A)
                            : AppColors.primary),
                    size: 26,
                  ),
                  onPressed: (_isSending || _isUploading || isEditing)
                      ? null
                      : _showAttachmentOptions,
                  tooltip: isEditing
                      ? 'Tidak dapat melampirkan saat mengedit'
                      : 'Lampirkan file atau foto',
                ),
                const SizedBox(width: 4),

                // Input Teks
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: widget.isDoctor
                            ? const Color(0xFFEFE3D0)
                            : const Color(0xFFE2EDF3),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: widget.isDoctor
                            ? const Color(0xFF24435A)
                            : AppColors.primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Edit pesan...' : 'Tulis pesan...',
                        hintStyle: GoogleFonts.poppins(
                          color: widget.isDoctor
                              ? const Color(0xFF6B8190)
                              : AppColors.neutralGray,
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Kirim / Simpan Perubahan (46px bulat biru tua untuk dokter)
                Container(
                  width: widget.isDoctor ? 46 : 42,
                  height: widget.isDoctor ? 46 : 42,
                  decoration: BoxDecoration(
                    color: isEditing
                        ? AppColors.successGreen
                        : (widget.isDoctor
                            ? const Color(0xFF1F5C7A)
                            : AppColors.primary),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending || _isUploading
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            isEditing ? Icons.check_rounded : Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: isEditing
                              ? () => _saveEditedMessage(visibleMessages)
                              : _sendMessage,
                          tooltip: isEditing ? 'Simpan perubahan' : 'Kirim pesan',
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget strip template pesan cepat (Bagian B - Chip melayang tanpa latar rectangle di belakang)
  Widget _buildTemplateSuggestions() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: _patientTemplates.length,
        itemBuilder: (context, index) {
          final template = _patientTemplates[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                _inputController.text = template;
                _inputController.selection = TextSelection.fromPosition(
                  TextPosition(offset: template.length),
                );
                _focusNode.requestFocus();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  template.length > 40
                      ? '${template.substring(0, 38)}…'
                      : template,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Dialog Pop-up Penyelesaian Konsultasi oleh Dokter (Bagian D).
class _SelesaikanKonsultasiDialog extends StatefulWidget {
  final String patientName;
  final Future<void> Function(String recommendation) onConfirm;

  const _SelesaikanKonsultasiDialog({
    required this.patientName,
    required this.onConfirm,
  });

  @override
  State<_SelesaikanKonsultasiDialog> createState() =>
      _SelesaikanKonsultasiDialogState();
}

class _SelesaikanKonsultasiDialogState
    extends State<_SelesaikanKonsultasiDialog> {
  final TextEditingController _recommendationController =
      TextEditingController();
  bool _isSubmitting = false;
  String? _validationError;
  String? _saveErrorMessage;
  String? _saveErrorCode;

  @override
  void dispose() {
    _recommendationController.dispose();
    super.dispose();
  }

  void _validate(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      setState(() => _validationError = 'Rekomendasi dokter wajib diisi.');
    } else if (trimmed.length < 10) {
      setState(() => _validationError =
          'Rekomendasi dokter minimal 10 karakter (saat ini ${trimmed.length}).');
    } else if (trimmed.length > 500) {
      setState(() => _validationError =
          'Rekomendasi dokter maksimal 500 karakter (saat ini ${trimmed.length}).');
    } else {
      if (_validationError != null) {
        setState(() => _validationError = null);
      }
    }
  }

  Future<void> _submit() async {
    _validate(_recommendationController.text);
    if (_validationError != null) return;

    setState(() {
      _isSubmitting = true;
      _saveErrorMessage = null;
      _saveErrorCode = null;
    });

    try {
      await widget.onConfirm(_recommendationController.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _saveErrorMessage = 'Gagal menyimpan rekomendasi. Coba lagi.';
          _saveErrorCode = e.toString().replaceAll('Exception: ', '').trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Selesaikan Konsultasi',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konsultasi dengan ${widget.patientName} akan ditandai selesai dan chat tidak bisa dibalas lagi.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rekomendasi dokter',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _recommendationController,
              enabled: !_isSubmitting,
              maxLines: 4,
              maxLength: 500,
              onChanged: _validate,
              decoration: InputDecoration(
                hintText:
                    'Tulis saran untuk pasien, mis. pola makan atau kapan perlu kontrol',
                hintStyle: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutralGray,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.all(12),
                counterText: '',
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _recommendationController,
              builder: (_, val, _) {
                final len = val.text.trim().length;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_validationError != null)
                        Expanded(
                          child: Text(
                            _validationError!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      Text(
                        '$len/500',
                        style: TextStyle(
                          fontSize: 11,
                          color: len > 500 ? Colors.red : AppColors.neutralGray,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            if (_saveErrorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            size: 15, color: Colors.red),
                        const SizedBox(width: 6),
                        Text(
                          _saveErrorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    if (_saveErrorCode != null && _saveErrorCode!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 21),
                        child: Text(
                          _saveErrorCode!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF991B1B),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: const Text('Batal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.successGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Selesaikan'),
        ),
      ],
    );
  }
}
