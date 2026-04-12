import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.storage.request();

  // Setup Android flutter_downloader
  await FlutterDownloader.initialize(debug: true, ignoreSsl: true);

  runApp(const QuickclixApp());
}

class QuickclixApp extends StatelessWidget {
  const QuickclixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quickclix',
      home: QuickclixBrowserPage(),
    );
  }
}

class QuickclixBrowserPage extends StatefulWidget {
  const QuickclixBrowserPage({super.key});

  @override
  State<QuickclixBrowserPage> createState() => _QuickclixBrowserPageState();
}

class _QuickclixBrowserPageState extends State<QuickclixBrowserPage> {
  static final Uri _homeUri = Uri.parse('https://quickclix.vasan.tech/');
  InAppWebViewController? _controller;
  bool _isFirstPageLoaded = false;

  late InAppWebViewSettings settings;

  @override
  void initState() {
    super.initState();
    settings = InAppWebViewSettings(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
      useOnDownloadStart: true,
      builtInZoomControls: false, // Blocks Android zoom capability
      displayZoomControls: false,
      supportZoom: false, // Blocks zoom
      hardwareAcceleration: true, // Butter smooth rendering
      disableContextMenu: true, // Block selection and zoom popups often
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri.uri(_homeUri)),
            initialSettings: settings,
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStop: (controller, url) async {
              if (!mounted) return;
              setState(() {
                _isFirstPageLoaded = true;
              });
              // Inject meta tag to forcefully block zooming on the website front end natively.
              await controller.evaluateJavascript(
                source: """
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                var head = document.getElementsByTagName('head')[0];
                head.appendChild(meta);
              """,
              );
            },
            onDownloadStartRequest: (controller, downloadRequest) async {
              // Ask user for permission for older Androids
              var status = await Permission.storage.request();
              if (status.isGranted) {
                String? savedDir;
                if (Platform.isAndroid) {
                  savedDir = (await getExternalStorageDirectory())?.path;
                } else if (Platform.isIOS) {
                  savedDir = (await getApplicationDocumentsDirectory()).path;
                }

                if (savedDir != null) {
                  // Using FlutterDownloader to download it locally within the app
                  final taskId = await FlutterDownloader.enqueue(
                    url: downloadRequest.url.toString(),
                    savedDir: savedDir,
                    showNotification: true,
                    openFileFromNotification: true,
                    saveInPublicStorage: true,
                  );

                  if (mounted && taskId != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Downloading file...')),
                    );
                  }
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Storage permission is required to download files.',
                      ),
                    ),
                  );
                }
              }
            },
          ),
          if (!_isFirstPageLoaded)
            const ColoredBox(
              color: Colors.white,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Quick Clix\nDesigned and developed by Sabarivasan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
