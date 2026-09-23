import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/consultation_model.dart';
import '../../services/consultation_service.dart';
import 'widgets/chat_bubble.dart';

/// Layar Chat dengan Dokter.
/// Menggunakan StreamBuilder dari Firestore untuk tampilan pesan real-time.
///
/// Balasan dokter bersifat SIMULASI (auto-reply setelah 3 detik).
/// TODO(chat-realtime): Ganti simulasi ini dengan sistem notifikasi push
/// (Firebase Cloud Messaging) dan halaman khusus dokter agar dokter
/// sungguhan dapat menerima dan membalas pesan dari perangkat mereka.
class ChatDokterScreen extends StatefulWidget {
  final String consultationId;

  const ChatDokterScreen({super.key, required this.consultationId});

  @override
  State<ChatDokterScreen> createState() => _ChatDokterScreenState();
}

class _ChatDokterScreenState extends State<ChatDokterScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  ConsultationModel? _consultation;
  bool _isSending = false;
  bool _hasLoadedConsultation = false;

  @override
  void initState() {
    super.initState();
    _loadConsultation();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConsultation() async {
    final c = await _consultationService.fetchById(widget.consultationId);
    if (mounted) {
      setState(() {
        _consultation = c;
        _hasLoadedConsultation = true;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputController.clear();

    try {
      await _consultationService.sendPatientMessage(
        consultationId: widget.consultationId,
        text: text,
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
      if (mounted) setState(() => _isSending = false);
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

  @override
  Widget build(BuildContext context) {
    final doctorName = _consultation?.doctorName ?? 'Dokter';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Kembali',
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Avatar dokter kecil
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.lightGray,
              child: const Icon(
                Icons.person_rounded,
                size: 22,
                color: AppColors.neutralGray,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  doctorName,
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
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Area chat ──
          Expanded(
            child: !_hasLoadedConsultation
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : StreamBuilder<List<ChatMessage>>(
                    stream: _consultationService
                        .watchMessages(widget.consultationId),
                    builder: (context, snapshot) {
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
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 56,
                                color: AppColors.neutralGray
                                    .withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Mulai percakapan dengan dokter',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.neutralGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        itemCount: messages.length,
                        itemBuilder: (_, i) =>
                            ChatBubble(message: messages[i]),
                      );
                    },
                  ),
          ),

          // ── Input area ──
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 12),
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
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Ikon lampiran (placeholder, tidak aktif dalam scope ini)
            IconButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur lampiran belum tersedia.'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.attach_file_rounded,
                  color: AppColors.neutralGray),
              tooltip: 'Lampiran',
            ),

            // Input teks
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 42),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Ketik pesan...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.neutralGray,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Tombol kirim
            Semantics(
              label: 'Kirim pesan',
              button: true,
              child: GestureDetector(
                onTap: _isSending ? null : _sendMessage,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSending
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const Padding(
                          padding: EdgeInsets.all(10),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
