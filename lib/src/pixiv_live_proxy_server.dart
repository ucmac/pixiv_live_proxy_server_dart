import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

class PixivLiveProxyServer {
  final String url;

  final int port;

  final String serverIp;

  PixivLiveProxyServer({
    required this.url,
    required this.port,
    required this.serverIp,
  });

  late final HttpServer server;

  late final String originalHost;

  Future<void> init() async {
    server = await HttpServer.bind('127.0.0.1', port);
    originalHost = Uri.parse(url).host;
  }

  final Dio _httpClient = Dio(BaseOptions(
    validateStatus: (status) => true,
  ));

  Uri replaceUri(Uri uri) {
    return Uri.parse(uri.toString().replaceFirst('${uri.host}:${uri.port}', serverIp).replaceFirst('http', 'https'));
  }

  String replaceM3u8(String m3u8) {
    return m3u8.replaceAll('https://$originalHost', 'http://127.0.0.1:$port');
  }

  void listen() {
    server.listen((HttpRequest request) async {
      final uri = request.requestedUri;
      final response = request.response;

      final newUri = replaceUri(uri);
      String content = await utf8.decoder.bind(request).join();

      final headers = <String, dynamic>{};
      request.headers.forEach((name, values) {
        headers[name] = values.first;
      });
      headers['host'] = originalHost;

      //请求newUri
      final Response newResponse;

      newResponse = await _httpClient.requestUri(
        newUri,
        data: content,
        options: Options(
          method: request.method,
          headers: headers,
          responseType: uri.pathSegments.last.contains('.m3u8') ? ResponseType.json : ResponseType.stream,
        ),
      );

      response.statusCode = newResponse.statusCode!;
      newResponse.headers.forEach((name, values) {
        response.headers.add(name, values);
      });

      if (uri.pathSegments.last.contains('.m3u8')) {
        final String m3u8Data = newResponse.data;
        final newData = replaceM3u8(m3u8Data);
        response.contentLength = newData.length;
        response.write(newData);
      } else {
        final ResponseBody responseBody = newResponse.data;
        await response.addStream(responseBody.stream);
      }

      response.close();
    });
  }
}
