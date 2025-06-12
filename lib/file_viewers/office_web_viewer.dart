import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class OfficeWebViewer extends StatelessWidget {
  final String url;

  const OfficeWebViewer({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    // Convert to WebUri
    final viewUrl = WebUri(
        'https://view.officeapps.live.com/op/embed.aspx?src=${Uri.encodeFull(url)}');

    return Scaffold(
      appBar: AppBar(title: const Text("Document Viewer")),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: viewUrl),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          useShouldOverrideUrlLoading: true,
        ),
      ),
    );
  }
}
