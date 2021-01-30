import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hybridge/hybridge.dart';

class WebSocketTransport extends Transport {
  static void listen(Channel channel, {int listenPort = 8090}) {
    runZoned(() async {
      var server = await HttpServer.bind('127.0.0.1', 8090);
      server.listen((HttpRequest req) {
        if (req.uri.path == '/hybridge') {
          WebSocketTransformer.upgrade(req).then((socket) {
            final transport = WebSocketTransport(socket);
            channel.connectTo(transport);
            socket.handleError((Object error) {
              socket.close();
              channel.disconnectFrom(transport);
            });
          });
        }
      });
    }, onError: (e) => print("An error occurred."));
  }

  WebSocket socket;

  WebSocketTransport(this.socket) {
    socket.listen((message) {
      messageReceived(message);
    });
  }

  void sendMessage(String message) {
    socket.add(message);
  }
}
