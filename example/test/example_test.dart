import 'dart:io';

import 'package:hybridge/hybridge.dart';
import 'package:hybridge_example/example.dart';

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
  MetaObject.add(ExampleObject, ExampleObjectMetaObject());
  Channel cp = Channel();
  cp.registerObject("test", ExampleObject());
  FakeTransport tp = FakeTransport();
  cp.connectTo(tp);
  Channel cr = Channel();
  FakeTransport tr = FakeTransport(another: tp);
  cr.connectTo(tr, response: (objmap) {
    var map = CMap.decode(objmap).proxyObjectMap();
    for (var e in map.entries) {
      stdout.writeln(e.key);
      //new ProxyTestObject(e.value).inc().then((value) {
      //  print("inc() -> ${value}");
      //});
    }
  });
}
