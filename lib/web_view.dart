import 'dart:io';

import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:open_share_plus/open.dart';
import 'package:takipz_web_view/cache/shared_pref.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_cookie_manager/webview_cookie_manager.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});
  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController controller;
  final cookieManager = WebviewCookieManager();
  String phoneNumber = "";
  var cookies = <Cookie>[];
  final String siteLoginUrl = "https://takip.ztakip.com/login.php";
  final String siteHomeUrl = "https://takip.ztakip.com";
  String siteUrl = "https://takip.ztakip.com";
  final sitePdfUrl = 'https://takip.ztakip.com/yazdir.pdf'; // PDF dosya URL'si

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      cookies = await SharedPref().getCookies();
      if (cookies.isEmpty) {
        cookies = await getCookies();
        await SharedPref().saveCookies(cookies);
        await setCookiesInWebView(cookies, siteLoginUrl);
        siteUrl = siteLoginUrl;
      } else {
        await setCookiesInWebView(cookies, siteHomeUrl);
        siteUrl = siteHomeUrl;
      }
    });

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
                request.url.startsWith('whatsapp://') ||
                request.url.startsWith('https://www.google.com.tr/maps') ||
                request.url.startsWith('https://takip.ztakip.com/yazdir.pdf')) {
              // "sms:" veya "tel:" şemaları ile başlayan link tıklandığında
              List<String> parts = request.url.split(':');
              if (parts.length > 1) {
                String phoneNumber = parts[1]; // Numara kısmı
                if (request.url.startsWith('sms:')) {
                  // SMS gönderme işlemi
                  String mesaj = "Merhaba";
                  var list = (request.url).split("&");
                  if (list.length == 2) {
                    var listYeni = list[1].split("=");
                    mesaj = Uri.decodeFull(listYeni[1]); //listYeni[1];
                  }
                  final Uri smsLaunchUri = Uri(
                    scheme: 'sms',
                    path: phoneNumber,
                    queryParameters: <String, String>{
                      'body': mesaj, // SMS içeriği
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
                  //https://wa.me/+905412913344/?text=Merhabalar.%20%C4%B0yi%20g%C3%BCnler.
                  var list = request.url.split("/");
                  var mesaj = Uri.decodeFull(list[4].split("=")[1]);
                  bool value = await Open.whatsApp(
                      whatsAppNumber: phoneNumber, text: mesaj);
                  if (!value) {
                    final Uri smsLaunchUri = Uri(
                      scheme: 'sms',
                      path: phoneNumber,
                      queryParameters: <String, String>{
                        'body': mesaj, // SMS içeriği
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
                } else if (request.url
                    .startsWith('https://www.google.com.tr/maps')) {
                  // Google Haritalar linki
                  var ayir = (request.url).split("/");
                  var konum = ayir[5];
                  var list = konum.split("?");
                  await MapsLauncher.launchQuery(list[0]);
                  //https://www.google.com.tr/maps/search/Sancaktepe?hl=tr&entry=ttu
                  // await showDialog(
                  //   context: context,
                  //   builder: (BuildContext context) {
                  //     return AlertDialog(
                  //       title: const Text('Open Maps'),
                  //       content:
                  //           const Text('Do you want to open Google Maps app?'),
                  //       actions: <Widget>[
                  //         TextButton(
                  //           onPressed: () {
                  //             Navigator.of(context).pop();
                  //           },
                  //           child: const Text('İptal'),
                  //         ),
                  //         TextButton(
                  //           onPressed: () async {
                  //             // Google Haritalar linki
                  //             var ayir = (request.url).split("/");
                  //             var konum = ayir[5];
                  //             var list = konum.split("?");
                  //             await MapsLauncher.launchQuery(list[0]);
                  //             Navigator.of(context).pop();
                  //           },
                  //           child: const Text('Aç'),
                  //         ),
                  //       ],
                  //     );
                  //   },
                  // );
                } else if (request.url.startsWith(sitePdfUrl)) {
                  //pdf göster
                  await openPDF(sitePdfUrl);
                }
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(siteUrl));
  }

  Future<List<Cookie>> getCookies() async {
    final currentUrl = await controller.currentUrl();
    final cookies = await cookieManager.getCookies(currentUrl);
    for (var item in cookies) {
      print(item);
    }
    return cookies;
  }

  Future<void> setCookiesInWebView(List<Cookie> cookies, String site) async {
    cookieManager.setCookies(cookies, origin: site);
  }

  Future<void> openPDF(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> openMapsApp(
      double latitude, double longitude, String label) async {
    final uri = Uri.parse("geo:$latitude,$longitude?q=$label");
    if (await canLaunch(uri.toString())) {
      await launch(uri.toString());
    } else {
      throw 'Could not launch maps app';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          controller.goBack();
          return false;
        } else {
          return false;
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            await controller.reload();
          },
          child: SafeArea(
            child: WebViewWidget(controller: controller),
          ),
        ),
      ),
    );
  }
}
