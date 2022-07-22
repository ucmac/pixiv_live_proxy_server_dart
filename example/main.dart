import 'dart:io';

import 'package:pixiv_live_proxy_server/pixiv_live_proxy_server.dart';

void main() async {
  HttpOverrides.global = _MyHttpOverrides();
  final server = PixivLiveProxyServer(
    url: 'https://hlse8.pixivsketch.net/2022072220/1658489550840747562eda32645fb1d07d9ab48713951da1104/index.m3u8',
    port: 44444,
    serverIp: '210.140.92.212'
  );
  await server.init();
  //应该新开一个isolate
  final subscription = server.listen();
  //访问 http://127.0.0.1:44444/2022072220/1658489550840747562eda32645fb1d07d9ab48713951da1104/index.m3u8
}

class _MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
