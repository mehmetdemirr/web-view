import 'package:flutter/material.dart';
import 'package:open_share_plus/open.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
// Import for Android features.
// Import for iOS features.

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController controller;
  String phoneNumber = "";
  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) async {
            if (request.url.startsWith('sms:') ||
                request.url.startsWith('tel:') ||
                request.url.startsWith('https://wa.me/') ||
                request.url.startsWith('whatsapp://')) {
              // "sms:" veya "tel:" şemaları ile başlayan link tıklandığında
              List<String> parts = request.url.split(':');
              if (parts.length > 1) {
                String phoneNumber = parts[1]; // Numara kısmı
                print('Tıklanan Numara: $phoneNumber');

                if (request.url.startsWith('sms:')) {
                  // SMS gönderme işlemi
                  final Uri smsLaunchUri = Uri(
                    scheme: 'sms',
                    path: phoneNumber,
                    queryParameters: <String, String>{
                      'body': 'Merhaba , iyi geceler', // SMS içeriği
                    },
                  );
                  try {
                    if (await canLaunch(smsLaunchUri.toString())) {
                      await launch(smsLaunchUri.toString());
                    } else {
                      throw 'SMS gönderilemedi';
                    }
                  } catch (e) {
                    print('Hata: $e');
                  }
                } else if (request.url.startsWith('tel:')) {
                  // Arama işlemi
                  final Uri telLaunchUri = Uri(
                    scheme: 'tel',
                    path: phoneNumber,
                  );
                  try {
                    if (await canLaunch(telLaunchUri.toString())) {
                      await launch(telLaunchUri.toString());
                    } else {
                      throw 'Arama başlatılamadı';
                    }
                  } catch (e) {
                    print('Hata: $e');
                  }
                } else if (request.url.startsWith('https://wa.me/') ||
                    request.url.startsWith('whatsapp://')) {
                  bool value = await Open.whatsApp(
                      whatsAppNumber: phoneNumber,
                      text: "Merhaba , iyi geceler");
                  if (!value) {
                    final Uri smsLaunchUri = Uri(
                      scheme: 'sms',
                      path: phoneNumber,
                      queryParameters: <String, String>{
                        'body': 'Merhaba , iyi geceler', // SMS içeriği
                      },
                    );
                    try {
                      if (await canLaunch(smsLaunchUri.toString())) {
                        await launch(smsLaunchUri.toString());
                      } else {
                        throw 'SMS gönderilemedi';
                      }
                    } catch (e) {
                      print('Hata: $e');
                    }
                  }
                }

                return NavigationDecision.prevent;
              }
            }

            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse('https://takip.ztakip.com/login.php'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: controller),
      ),
    );
  }
}
