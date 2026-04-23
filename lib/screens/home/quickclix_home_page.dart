import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quickclix/models/retrieve_result.dart';
import 'package:quickclix/models/upload_kind.dart';
import 'package:quickclix/services/clipboard_api_service.dart';
import 'package:quickclix/widgets/footer_card.dart';
import 'package:quickclix/widgets/hero_card.dart';
import 'package:quickclix/widgets/retrieve_panel.dart';
import 'package:quickclix/widgets/upload_panel.dart';
import 'package:url_launcher/url_launcher.dart';

class QuickclixHomePage extends StatefulWidget {
  const QuickclixHomePage({super.key});

  @override
  State<QuickclixHomePage> createState() => _QuickclixHomePageState();
}

class _QuickclixHomePageState extends State<QuickclixHomePage> {
  final ClipboardApiService _apiService = ClipboardApiService();
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

      final receipt = await _apiService.upload(
        kind: _uploadKind,
        text: _textController.text,
        file: _selectedFile,
      );

      setState(() {
        _generatedPin = receipt.pin;
        _expiresAt = receipt.expiresAt;
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

      final result = await _apiService.retrieve(normalized);
      setState(() {
        _retrieveResult = result;
      });
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
    if (result == null || !result.isFile || result.downloadPath == null) {
      return;
    }

    try {
      setState(() {
        _downloadingFile = true;
      });

      final bytes = await _apiService.downloadByPath(result.downloadPath!);
      final directory = await getApplicationDocumentsDirectory();
      final fileName = (result.fileName ?? 'download.bin').replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(bytes, flush: true);

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
                      FooterCard(
                        showContacts: _showContacts,
                        onToggleContacts: () {
                          setState(() {
                            _showContacts = !_showContacts;
                          });
                        },
                        onTapLink: _openLink,
                      ),
                      const SizedBox(height: 12),
                      const HeroCard(),
                      const SizedBox(height: 12),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: UploadPanel(
                                uploadKind: _uploadKind,
                                textController: _textController,
                                selectedFile: _selectedFile,
                                uploading: _uploading,
                                uploadError: _uploadError,
                                generatedPin: _generatedPin,
                                expiresAt: _expiresAt,
                                onSelectKind: (kind) {
                                  setState(() {
                                    _uploadKind = kind;
                                  });
                                },
                                onPickFile: _pickFile,
                                onUpload: _handleUpload,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RetrievePanel(
                                pinController: _pinController,
                                retrieving: _retrieving,
                                retrieveError: _retrieveError,
                                retrieveResult: _retrieveResult,
                                copied: _copied,
                                downloadingFile: _downloadingFile,
                                onRetrieve: _handleRetrieve,
                                onCopy: _copyText,
                                onDownload: _downloadFile,
                                formatMb: _formatMb,
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            UploadPanel(
                              uploadKind: _uploadKind,
                              textController: _textController,
                              selectedFile: _selectedFile,
                              uploading: _uploading,
                              uploadError: _uploadError,
                              generatedPin: _generatedPin,
                              expiresAt: _expiresAt,
                              onSelectKind: (kind) {
                                setState(() {
                                  _uploadKind = kind;
                                });
                              },
                              onPickFile: _pickFile,
                              onUpload: _handleUpload,
                            ),
                            const SizedBox(height: 12),
                            RetrievePanel(
                              pinController: _pinController,
                              retrieving: _retrieving,
                              retrieveError: _retrieveError,
                              retrieveResult: _retrieveResult,
                              copied: _copied,
                              downloadingFile: _downloadingFile,
                              onRetrieve: _handleRetrieve,
                              onCopy: _copyText,
                              onDownload: _downloadFile,
                              formatMb: _formatMb,
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
}
