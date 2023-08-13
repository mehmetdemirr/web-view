import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class SharedPref {
  Future<List<Cookie>> getCookies() async {
    final prefs = await SharedPreferences.getInstance();
    final cookiesJson = prefs.getStringList(SharedKeyItem.cookies.str());
    return cookiesJson
            ?.map((cookie) => Cookie.fromSetCookieValue(cookie))
            .toList() ??
        [];
  }

  Future<void> saveCookies(List<Cookie> cookies) async {
    final prefs = await SharedPreferences.getInstance();
    final cookiesJson = cookies.map((cookie) => cookie.toString()).toList();
    await prefs.setStringList(SharedKeyItem.cookies.str(), cookiesJson);
  }
}

enum SharedKeyItem {
  cookies,
}

extension SharedKeyItems on SharedKeyItem {
  String str() {
    return switch (this) {
      SharedKeyItem.cookies => "app_cookies",
    };
  }
}
