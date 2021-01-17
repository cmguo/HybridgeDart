import 'dart:ffi';
import 'dart:io';

import '../lib/channel.dart';
import '../lib/transport.dart';
import '../lib/src/handleptr.dart';
import '../lib/src/meta.dart';
import '../lib/src/hybridge.dart';
import '../lib/src/variant.dart';

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
    var map = CMap.fromValue(objmap, VaueType.Object_).objectMap();
  });
  tr.sendMessage('{"id":0,"type":3}');
  tr.sendMessage('{"type":4}');
  cp.timerEvent();
  tr.sendMessage(
      '{"id":1,"type":6, "object": "test", "method": 1, "args": []}');
  tr.messageReceived(
      '{"id":1,"type":6, "object": "test", "method": 2, "args": [4]}');
}
