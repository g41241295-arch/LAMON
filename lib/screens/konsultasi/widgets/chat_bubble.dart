import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../models/consultation_model.dart';

/// Widget bubble pesan chat.
/// Pasien (patient) tampil di kanan dengan warna biru-teal.
/// Dokter tampil di kiri dengan warna abu terang.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isPatient = message.isPatient;
    final timeStr = _formatTime(message.sentAt);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isPatient ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar dokter (kiri)
          if (!isPatient) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.lightGray,
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.neutralGray,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble konten
          Flexible(
            child: Column(
              crossAxisAlignment: isPatient
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isPatient
                        ? AppColors.primary
                        : const Color(0xFFF0F4F7),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isPatient ? 18 : 4),
                      bottomRight: Radius.circular(isPatient ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isPatient ? Colors.white : AppColors.primaryText,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.neutralGray,
                  ),
                ),
              ],
            ),
          ),

          // Avatar pasien (kanan)
          if (isPatient) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.25),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }
}
