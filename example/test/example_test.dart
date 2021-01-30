import 'dart:io';

import 'package:hybridge/hybridge.dart';
import 'package:hybridge_example/example.dart';

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
  ExampleObjectMetaObject.register();
  IExampleObjectProxy.register();
  Channel cp = Channel();
  cp.registerObject("test", ExampleObject());
  FakeTransport tp = FakeTransport();
  cp.connectTo(tp);
  Channel cr = Channel();
  FakeTransport tr = FakeTransport(another: tp);
  cr.connectTo(tr, callback: (objmap) {
    for (var e in objmap.entries) {
      stdout.writeln("${e.key}: ${e.value.runtimeType.toString()}");
      //new ProxyTestObject(e.value).inc().then((value) {
      //  print("inc() -> ${value}");
      //});
    }
  });
}
