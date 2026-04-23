import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickclix/models/retrieve_result.dart';

class RetrievePanel extends StatelessWidget {
  const RetrievePanel({
    required this.pinController,
    required this.retrieving,
    required this.retrieveError,
    required this.retrieveResult,
    required this.copied,
    required this.downloadingFile,
    required this.onRetrieve,
    required this.onCopy,
    required this.onDownload,
    required this.formatMb,
    super.key,
  });

  final TextEditingController pinController;
  final bool retrieving;
  final String retrieveError;
  final RetrieveResult? retrieveResult;
  final bool copied;
  final bool downloadingFile;
  final VoidCallback onRetrieve;
  final VoidCallback onCopy;
  final VoidCallback onDownload;
  final String Function(int bytes) formatMb;

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
            'Retrieve',
            style: TextStyle(
              color: Color(0xFF122338),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text('4-digit PIN', style: TextStyle(color: Color(0xFF395069))),
          const SizedBox(height: 6),
          TextField(
            controller: pinController,
            maxLength: 4,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: '0000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              counterText: '',
            ),
          ),
          const SizedBox(height: 10),
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
              onPressed: retrieving ? null : onRetrieve,
              child: Text(retrieving ? 'Checking...' : 'Retrieve'),
            ),
          ),
          if (retrieveError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              retrieveError,
              style: const TextStyle(color: Color(0xFFB92A2A)),
            ),
          ],
          if (retrieveResult?.isText == true) ...[
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
                  Row(
                    children: [
                      const Text(
                        'Shared text',
                        style: TextStyle(
                          color: Color(0xFF395069),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: onCopy,
                        child: Text(
                          copied ? 'Copied' : 'Copy',
                          style: const TextStyle(
                            color: Color(0xFFDB4A1F),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFD4E3EF)),
                    ),
                    child: Text(
                      retrieveResult?.text ?? '',
                      style: const TextStyle(color: Color(0xFF122338)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (retrieveResult?.isFile == true) ...[
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
                    'File ready',
                    style: TextStyle(
                      color: Color(0xFF395069),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    retrieveResult?.fileName ?? '',
                    style: const TextStyle(
                      color: Color(0xFF122338),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${retrieveResult?.mimeType ?? ''} | ${formatMb(retrieveResult?.size ?? 0)} MB',
                    style: const TextStyle(color: Color(0xFF395069)),
                  ),
                  const SizedBox(height: 10),
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
                      onPressed: downloadingFile ? null : onDownload,
                      child: Text(
                        downloadingFile
                            ? 'Downloading...'
                            : 'Download (one-time)',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
