import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:quickclix/models/upload_kind.dart';

class UploadPanel extends StatelessWidget {
  const UploadPanel({
    required this.uploadKind,
    required this.textController,
    required this.selectedFile,
    required this.uploading,
    required this.uploadError,
    required this.generatedPin,
    required this.expiresAt,
    required this.onSelectKind,
    required this.onPickFile,
    required this.onUpload,
    super.key,
  });

  final UploadKind uploadKind;
  final TextEditingController textController;
  final PlatformFile? selectedFile;
  final bool uploading;
  final String uploadError;
  final String generatedPin;
  final DateTime? expiresAt;
  final ValueChanged<UploadKind> onSelectKind;
  final VoidCallback onPickFile;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x1A122338)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload',
            style: TextStyle(
              color: Color(0xFF122338),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFD3E7F4),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _toggleButton(
                    label: 'Text',
                    selected: uploadKind == UploadKind.text,
                    onPressed: () => onSelectKind(UploadKind.text),
                  ),
                ),
                Expanded(
                  child: _toggleButton(
                    label: 'File',
                    selected: uploadKind == UploadKind.file,
                    onPressed: () => onSelectKind(UploadKind.file),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (uploadKind == UploadKind.text) ...[
            const Text(
              'Text snippet',
              style: TextStyle(color: Color(0xFF395069)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: textController,
              minLines: 6,
              maxLines: 10,
              maxLength: 20000,
              decoration: InputDecoration(
                hintText: 'Paste your note here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ] else ...[
            const Text(
              'Choose file',
              style: TextStyle(color: Color(0xFF395069)),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: onPickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(selectedFile?.name ?? 'Pick file'),
            ),
            const SizedBox(height: 4),
            const Text(
              'Max file size: 25MB.',
              style: TextStyle(color: Color(0xFF395069)),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B3D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: uploading ? null : onUpload,
              child: Text(uploading ? 'Uploading...' : 'Generate PIN'),
            ),
          ),
          if (uploadError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(uploadError, style: const TextStyle(color: Color(0xFFB92A2A))),
          ],
          if (generatedPin.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF7FD),
                border: Border.all(color: const Color(0xFFBFD8EA)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your one-time PIN',
                    style: TextStyle(
                      color: Color(0xFF395069),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    generatedPin,
                    style: const TextStyle(
                      color: Color(0xFF122338),
                      fontWeight: FontWeight.w800,
                      fontSize: 40,
                      letterSpacing: 2,
                    ),
                  ),
                  if (expiresAt != null)
                    Text(
                      'Expires at ${TimeOfDay.fromDateTime(expiresAt!).format(context)}',
                      style: const TextStyle(color: Color(0xFF395069)),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _toggleButton({
    required String label,
    required bool selected,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: selected ? Colors.white : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        foregroundColor: const Color(0xFF122338),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
