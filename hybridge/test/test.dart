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

class FakeTransport extends Transport {
  Transport another;
  FakeTransport({FakeTransport another}) {
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
  FakeTransport tp = FakeTransport();
  cp.connectTo(tp);
  Channel cr = Channel();
  FakeTransport tr = FakeTransport(another: tp);
  cr.connectTo(tr, response: (objmap) {
    var map = CMap.decode(objmap).proxyObjectMap();
    for (var e in map.entries) {
      stdout.writeln(e.key);
      new ProxyTestObject(e.value).inc().then((value) {
        print("inc() -> ${value}");
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
