// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

abstract class INetworkManager {
  Future<NetworkResult> checkNetworkFirstTime();
  void handlerNetworkChange(void Function(NetworkResult result) onChange);
  void dispose();
}

class NetworkChangeManager extends INetworkManager {
  late final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;
  NetworkChangeManager() {
    _connectivity = Connectivity();
  }
  @override
  Future<NetworkResult> checkNetworkFirstTime() async {
    final ConnectivityResult connectivityResult =
        await (_connectivity.checkConnectivity());
    return NetworkResult.checkConnectivityResult(connectivityResult);
  }

  @override
  void handlerNetworkChange(void Function(NetworkResult result) onChange) {
    _subscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      onChange.call(NetworkResult.checkConnectivityResult(result));
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
  }
}

enum NetworkResult {
  on,
  off;

  static NetworkResult checkConnectivityResult(ConnectivityResult result) {
    print(result.toString());
    switch (result) {
      case ConnectivityResult.bluetooth:
      case ConnectivityResult.wifi:
      case ConnectivityResult.ethernet:
      case ConnectivityResult.mobile:
        return NetworkResult.on;
      case ConnectivityResult.none:
        return NetworkResult.off;
      default:
        return NetworkResult.off;
    }
  }
}
