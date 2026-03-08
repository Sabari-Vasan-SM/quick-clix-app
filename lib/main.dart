import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse('https://quickclix.vasan.tech/'));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: WebViewWidget(controller: _controller));
  }
}
