import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:takipz_web_view/network_control/network_change_manager.dart';

class NoNetworkWidget extends StatefulWidget {
  const NoNetworkWidget({super.key});
  @override
  State<NoNetworkWidget> createState() => _NoNetworkWidgetState();
}

class _NoNetworkWidgetState extends State<NoNetworkWidget> {
  late final INetworkManager _networkChange;
  NetworkResult? _networkResult;
  @override
  void initState() {
    super.initState();
    _networkChange = NetworkChangeManager();
    fetchFirstResult();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _networkChange.handlerNetworkChange((result) {
        _updateView(result);
      });
    });
  }

  Future<void> fetchFirstResult() async {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _networkResult = await _networkChange.checkNetworkFirstTime();
    });
  }

  void _updateView(NetworkResult result) {
    setState(() {
      _networkResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: deneme(context),
      secondChild: const SizedBox(),
      crossFadeState: _networkResult == NetworkResult.off
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 175),
    );
  }
}

Container deneme(BuildContext context) {
  return Container(
    color: Colors.black26,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.sizeOf(context).width / 1.5,
              child: Lottie.asset('assets/lottie_network.json'),
            ),
            Text(
              "Lütfen İnternet Bağlantınızı Kontrol Edin !",
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}
