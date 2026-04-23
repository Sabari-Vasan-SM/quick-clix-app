import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const QuickclixApp());
}

const String _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://quick-clix-server.onrender.com',
);

final Uri _uploadUri = Uri.parse('$_apiBaseUrl/api/clipboard');
final Uri _retrieveUri = Uri.parse('$_apiBaseUrl/api/clipboard/retrieve');

typedef LinkOpener = Future<void> Function(String url);

class QuickclixApp extends StatelessWidget {
  const QuickclixApp({super.key});

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF122338);
    const paper = Color(0xFFFBF8F3);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quick Clix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ink, surface: paper),
        scaffoldBackgroundColor: paper,
        fontFamily: 'sans-serif',
        useMaterial3: true,
      ),
      home: const QuickclixHomePage(),
    );
  }
}

enum UploadKind { text, file }

class RetrieveResult {
  const RetrieveResult.text({required this.text})
    : kind = 'text',
      fileName = null,
      mimeType = null,
      size = null,
      downloadPath = null;

  const RetrieveResult.file({
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.downloadPath,
  }) : kind = 'file',
       text = null;

  final String kind;
  final String? text;
  final String? fileName;
  final String? mimeType;
  final int? size;
  final String? downloadPath;
}

class QuickclixHomePage extends StatefulWidget {
  const QuickclixHomePage({super.key});

  @override
  State<QuickclixHomePage> createState() => _QuickclixHomePageState();
}

class _QuickclixHomePageState extends State<QuickclixHomePage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  UploadKind _uploadKind = UploadKind.text;
  PlatformFile? _selectedFile;

  bool _uploading = false;
  String _uploadError = '';
  String _generatedPin = '';
  DateTime? _expiresAt;

  bool _retrieving = false;
  String _retrieveError = '';
  RetrieveResult? _retrieveResult;
  bool _copied = false;
  bool _showContacts = false;
  bool _downloadingFile = false;

  @override
  void dispose() {
    _textController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _parseResponse(http.Response response) async {
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final message = response.body.trim().isEmpty
        ? '${response.statusCode} ${response.reasonPhrase ?? ''}'.trim()
        : response.body.trim();
    return {'message': message};
  }

  Future<void> _handleUpload() async {
    setState(() {
      _uploadError = '';
      _generatedPin = '';
      _expiresAt = null;
    });

    if (_uploadKind == UploadKind.text && _textController.text.trim().isEmpty) {
      setState(() {
        _uploadError = 'Please enter text to share.';
      });
      return;
    }

    if (_uploadKind == UploadKind.file && _selectedFile == null) {
      setState(() {
        _uploadError = 'Please choose a file to upload.';
      });
      return;
    }

    try {
      setState(() {
        _uploading = true;
      });

      final request = http.MultipartRequest('POST', _uploadUri);
      if (_uploadKind == UploadKind.text) {
        request.fields['text'] = _textController.text.trim();
      } else {
        final file = _selectedFile!;
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'file',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'file',
              file.path!,
              filename: file.name,
            ),
          );
        } else {
          throw Exception('Unable to read selected file.');
        }
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final payload = await _parseResponse(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(payload['message'] ?? 'Upload failed.');
      }

      setState(() {
        _generatedPin = payload['pin']?.toString() ?? '';
        final rawExpiresAt = payload['expiresAt'];
        if (rawExpiresAt is int) {
          _expiresAt = DateTime.fromMillisecondsSinceEpoch(rawExpiresAt);
        }
        if (_uploadKind == UploadKind.text) {
          _textController.clear();
        } else {
          _selectedFile = null;
        }
      });
    } catch (error) {
      setState(() {
        _uploadError = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Upload failed.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(withData: true);
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    setState(() {
      _selectedFile = picked.files.first;
    });
  }

  Future<void> _handleRetrieve() async {
    setState(() {
      _retrieveError = '';
      _retrieveResult = null;
      _copied = false;
    });

    final digitsOnly = _pinController.text.replaceAll(RegExp(r'\D'), '');
    final normalized = digitsOnly.length > 4
        ? digitsOnly.substring(0, 4)
        : digitsOnly;
    if (normalized.length != 4) {
      setState(() {
        _retrieveError = 'Enter a valid 4-digit PIN.';
      });
      return;
    }

    try {
      setState(() {
        _retrieving = true;
      });

      final response = await http.post(
        _retrieveUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pin': normalized}),
      );
      final payload = await _parseResponse(response);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(payload['message'] ?? 'Could not retrieve content.');
      }

      final kind = payload['kind']?.toString();
      if (kind == 'text') {
        setState(() {
          _retrieveResult = RetrieveResult.text(
            text: payload['text']?.toString() ?? '',
          );
        });
      } else if (kind == 'file') {
        setState(() {
          _retrieveResult = RetrieveResult.file(
            fileName: payload['fileName']?.toString() ?? 'download.bin',
            mimeType:
                payload['mimeType']?.toString() ?? 'application/octet-stream',
            size: (payload['size'] as num?)?.toInt() ?? 0,
            downloadPath: payload['downloadPath']?.toString() ?? '',
          );
        });
      } else {
        throw Exception('Unknown response type.');
      }
    } catch (error) {
      setState(() {
        _retrieveError = error is Exception
            ? error.toString().replaceFirst('Exception: ', '')
            : 'Could not retrieve content.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _retrieving = false;
        });
      }
    }
  }

  Future<void> _copyText() async {
    final text = _retrieveResult?.text;
    if (text == null) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() {
      _copied = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _copied = false;
      });
    });
  }

  Future<void> _downloadFile() async {
    final result = _retrieveResult;
    if (result == null ||
        result.kind != 'file' ||
        result.downloadPath == null) {
      return;
    }

    try {
      setState(() {
        _downloadingFile = true;
      });

      final url = Uri.parse('$_apiBaseUrl${result.downloadPath!}');
      final response = await http.get(url);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final payload = await _parseResponse(response);
        throw Exception(payload['message'] ?? 'Download failed.');
      }

      final directory = await getApplicationDocumentsDirectory();
      final fileName = (result.fileName ?? 'download.bin').replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);

      await OpenFilex.open(file.path);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is Exception
                  ? error.toString().replaceFirst('Exception: ', '')
                  : 'Download failed.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloadingFile = false;
        });
      }
    }
  }

  Future<void> _openLink(String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open link.')));
    }
  }

  String _formatMb(int bytes) {
    return (bytes / (1024 * 1024)).toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF122338);
    const inkSoft = Color(0xFF395069);
    const accent = Color(0xFFFF6B3D);
    const accentStrong = Color(0xFFDB4A1F);
    const mist = Color(0xFFD3E7F4);
    const panel = Color(0xCCFFFFFF);
    const border = Color(0x1A122338);

    final isWide = MediaQuery.sizeOf(context).width >= 920;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(1.05, -1.05),
            radius: 1.2,
            colors: [Color(0xFFFFD8AC), Color(0xFFFBF8F3)],
            stops: [0, 0.6],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-1.0, 1.1),
              radius: 1.25,
              colors: [Color(0xFFC4E8FF), Color(0x00C4E8FF)],
              stops: [0, 0.62],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFooterCard(
                        panel,
                        border,
                        ink,
                        inkSoft,
                        accent,
                        onTapLink: _openLink,
                      ),
                      const SizedBox(height: 12),
                      _buildHeroCard(panel, border, ink, inkSoft, accentStrong),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildUploadCard(
                                panel,
                                border,
                                ink,
                                inkSoft,
                                mist,
                                accent,
                                accentStrong,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildRetrieveCard(
                                panel,
                                border,
                                ink,
                                inkSoft,
                                accent,
                                accentStrong,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _buildUploadCard(
                              panel,
                              border,
                              ink,
                              inkSoft,
                              mist,
                              accent,
                              accentStrong,
                            ),
                            const SizedBox(height: 12),
                            _buildRetrieveCard(
                              panel,
                              border,
                              ink,
                              inkSoft,
                              accent,
                              accentStrong,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterCard(
    Color panel,
    Color border,
    Color ink,
    Color inkSoft,
    Color accent, {
    required LinkOpener onTapLink,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(
                  'https://avatars.githubusercontent.com/u/144119741?v=4',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Designed and developed by Sabarivasan',
                  style: TextStyle(color: inkSoft, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEAF3FA),
              foregroundColor: ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            onPressed: () {
              setState(() {
                _showContacts = !_showContacts;
              });
            },
            child: Text(
              _showContacts ? 'Hide Developer Contact' : 'Developer Contact',
            ),
          ),
          if (_showContacts) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _linkChip('Portfolio', accent, () {
                  onTapLink('https://portfolio.vasan.tech/');
                }),
                _linkChip('LinkedIn', accent, () {
                  onTapLink(
                    'https://www.linkedin.com/in/sabarivasan-s-m-b10229255/',
                  );
                }),
                _linkChip('GitHub', accent, () {
                  onTapLink('https://github.com/Sabari-Vasan-SM');
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _linkChip(String label, Color accent, VoidCallback onPressed) {
    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFBFD8EA)),
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      avatar: Icon(Icons.open_in_new, size: 16, color: accent),
    );
  }

  Widget _buildHeroCard(
    Color panel,
    Color border,
    Color ink,
    Color inkSoft,
    Color accentStrong,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temporary Universal Clipboard',
            style: TextStyle(
              color: accentStrong,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Quick Clix',
            style: TextStyle(
              color: ink,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share text or files instantly with a one-time 4-digit PIN. Content stays available for 15 minutes and self-destructs after retrieval.',
            style: TextStyle(color: inkSoft, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(
    Color panel,
    Color border,
    Color ink,
    Color inkSoft,
    Color mist,
    Color accent,
    Color accentStrong,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload',
            style: TextStyle(
              color: ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: mist,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _toggleButton(
                    label: 'Text',
                    selected: _uploadKind == UploadKind.text,
                    onPressed: () {
                      setState(() {
                        _uploadKind = UploadKind.text;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: _toggleButton(
                    label: 'File',
                    selected: _uploadKind == UploadKind.file,
                    onPressed: () {
                      setState(() {
                        _uploadKind = UploadKind.file;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_uploadKind == UploadKind.text) ...[
            Text('Text snippet', style: TextStyle(color: inkSoft)),
            const SizedBox(height: 6),
            TextField(
              controller: _textController,
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
            Text('Choose file', style: TextStyle(color: inkSoft)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(_selectedFile?.name ?? 'Pick file'),
            ),
            const SizedBox(height: 4),
            Text('Max file size: 25MB.', style: TextStyle(color: inkSoft)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _uploading ? null : _handleUpload,
              child: Text(_uploading ? 'Uploading...' : 'Generate PIN'),
            ),
          ),
          if (_uploadError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _uploadError,
              style: const TextStyle(color: Color(0xFFB92A2A)),
            ),
          ],
          if (_generatedPin.isNotEmpty) ...[
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
                  Text(
                    'Your one-time PIN',
                    style: TextStyle(
                      color: inkSoft,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _generatedPin,
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 40,
                      letterSpacing: 2,
                    ),
                  ),
                  if (_expiresAt != null)
                    Text(
                      'Expires at ${TimeOfDay.fromDateTime(_expiresAt!).format(context)}',
                      style: TextStyle(color: inkSoft),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRetrieveCard(
    Color panel,
    Color border,
    Color ink,
    Color inkSoft,
    Color accent,
    Color accentStrong,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Retrieve',
            style: TextStyle(
              color: ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text('4-digit PIN', style: TextStyle(color: inkSoft)),
          const SizedBox(height: 6),
          TextField(
            controller: _pinController,
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
                backgroundColor: accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: _retrieving ? null : _handleRetrieve,
              child: Text(_retrieving ? 'Checking...' : 'Retrieve'),
            ),
          ),
          if (_retrieveError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _retrieveError,
              style: const TextStyle(color: Color(0xFFB92A2A)),
            ),
          ],
          if (_retrieveResult?.kind == 'text') ...[
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
                      Text(
                        'Shared text',
                        style: TextStyle(
                          color: inkSoft,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _copyText,
                        child: Text(
                          _copied ? 'Copied' : 'Copy',
                          style: TextStyle(
                            color: accentStrong,
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
                      _retrieveResult?.text ?? '',
                      style: TextStyle(color: ink),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_retrieveResult?.kind == 'file') ...[
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
                  Text(
                    'File ready',
                    style: TextStyle(
                      color: inkSoft,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _retrieveResult?.fileName ?? '',
                    style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_retrieveResult?.mimeType ?? ''} | ${_formatMb(_retrieveResult?.size ?? 0)} MB',
                    style: TextStyle(color: inkSoft),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _downloadingFile ? null : _downloadFile,
                      child: Text(
                        _downloadingFile
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
