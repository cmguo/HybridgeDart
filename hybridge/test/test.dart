import 'dart:ffi';
import 'dart:io';

import 'package:hybridge/hybridge.dart';

part 'test.g.dart';

class TestObject {
  int x = 0;

  int inc() {
    return x++;
  }

  int add(int d) {
    return x += d;
  }
}

abstract class ITestObject {
  int get x;
  set x(int value);
  Future<int> inc();
  Future<int> add(int d);
}

class PairTransport extends Transport {
  Transport another;
  PairTransport({PairTransport another}) {
    this.another = another;
    if (another != null) another.another = this;
  }
  void sendMessage(String message) {
    another.messageReceived(message);
  }
}

void main() {
  MetaObject.add(TestObject, TestObjectMetaObject());
  Channel cp = Channel();
  cp.registerObject("test", TestObject());
  // FlutterTransport
  cp.connectTo(FlutterTransport());
  // WebSocketTransport
  //   you can test in http://coolaf.com/tool/chattest
  //   with ws://127.0.0.1:8090/hybridge
  WebSocketTransport.listen(cp);
  Channel cr = Channel();
  // PairTransport
  PairTransport tp = PairTransport();
  cp.connectTo(tp);
  PairTransport tr = PairTransport(another: tp);
  cr.connectTo(tr, response: (objmap) {
    var map = CMap.decode(objmap).proxyObjectMap();
    for (var e in map.entries) {
      stdout.writeln(e.key);
      ITestObject po = new ProxyTestObject(e.value);
      po.inc().then((value) {
        print("inc() -> $value");
        print("x: ${po.x}");
      });
    }
  });
  //tr.sendMessage('{"id":0,"type":3}');
  //tr.sendMessage('{"type":4}');
  cp.timerEvent();
  // tr.sendMessage(
  //     '{"id":1,"type":6, "object": "test", "method": 1, "args": []}');
  // tr.messageReceived(
  //     '{"id":1,"type":6, "object": "test", "method": 2, "args": [4]}');
}
