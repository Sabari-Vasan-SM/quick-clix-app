import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
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
  late final WebViewController _controller;
  bool _isFirstPageLoaded = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (!mounted || _isFirstPageLoaded) {
              return;
            }
            setState(() {
              _isFirstPageLoaded = true;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      );

    // Render an instant first frame, then start network work.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadRequest(_homeUri);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          WebViewWidget(controller: _controller),
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
