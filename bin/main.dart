import 'dart:convert';
import 'dart:io';
import 'cctv_signaller.dart';
import 'webSocket_manager.dart';

void main(List<String> arguments) => server();

var manager = PubSubManager();
var _address = InternetAddress.anyIPv4;
int _port = 8086;
void server() async {

  final requests =
      await HttpServer.bindSecure(_address, _port, getSecurityContext());
  print('Server running https://localhost:8888');
  await for (final request in requests) {
    processRequest(request);
  }
}

void processRequest(HttpRequest request) async {
  final response = request.response;
  switch (request.uri.path) {
    case '/ws':
      try {
        var socket = await WebSocketTransformer.upgrade(request);
        manager.init(socket);
      } catch (e) {
        request.response.close();
      }
      break;
    case '/api/turn':
      {
        response
          ..headers.contentType = ContentType("application", "json")
          ..write(json.encoder.convert({
            "username": "1584195784:mbzrxpgjys",
            "password": "isyl6FF6nqMTB9/ig5MrMRUXqZg",
            "ttl": 86400,
            "uris": ["turn:127.0.0.1:19302?transport=udp"]
          }));
        response.close();
      }
      break;
    case '/':
      {
        response..headers.contentType = ContentType.html;
        await response
          ..write(File('web/index.html').readAsStringSync());
        response.close();
      }
      break;
    default:
      var path = request.uri.path;

      {
        bool isJavaScript = path.toString().contains("js");
        if (isJavaScript) {
          await response
            ..headers.add("Content-type", "application/javascript")
            ..write(File('web' + path).readAsStringSync());
        }
        if (!isJavaScript) {
          response..headers.contentType = ContentType.binary;
          try {
            await response.addStream(File('web' + path).openRead());
          } catch (e) {
            print(e.toString());
          }
        }

        response.close();
      }
      break;
  }
}

SecurityContext getSecurityContext() {
  final chain = Platform.script.resolve('../config/cert.pem').toFilePath();
  final key = Platform.script.resolve('../config/key.pem').toFilePath();

  return SecurityContext()
    ..useCertificateChain(chain)
    ..usePrivateKey(key, password: 'aapgap');
}
