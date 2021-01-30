import 'package:flutter/services.dart';

import 'transport.dart';

class FlutterTransport extends Transport {
  BasicMessageChannel channel;

  FlutterTransport({String name = "com.tal.hybridge.FlutterTransport"}) {
    channel = BasicMessageChannel(name, StandardMessageCodec());
    channel.setMessageHandler((message) {
      super.messageReceived(message);
      return null;
    });
  }

  void sendMessage(String message) {
    channel.send(message);
  }
}
