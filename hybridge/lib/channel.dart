import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'src/channels.dart';
import 'src/hybridge.dart';
import 'src/handleptr.dart';
import 'src/proxyobject.dart';
import 'src/meta.dart';
import 'transport.dart';

class Channel {
  static Pointer<ChannelStub> stub = Hybridge.channelStub;

  Pointer<Void> handle;
  Handle callback;

  int id;
  Pointer<Utf8> uuid;

  Channel() {
    callback = Hybridge.channels.alloc(this);
    handle = stub.ref.create.asFunction<d_createChannel>()(callback.addressOf);
  }

  void registerObject(String name, dynamic object) {
    stub.ref.registerObject.asFunction<d_registerObject>()(handle,
        Utf8.toUtf8(name), Hybridge.objects.alloc(object).addressOf.cast());
  }

  void deregisterObject(String name, dynamic object) {
    stub.ref.deregisterObject.asFunction<d_deregisterObject>()(
        handle, Hybridge.objects[object]);
  }

  bool blockUpdates() {
    return stub.ref.blockUpdates.asFunction<d_blockUpdates>()(handle) != 0;
  }

  void setBlockUpdates(bool block) {
    return stub.ref.setBlockUpdates.asFunction<d_setBlockUpdates>()(
        handle, block ? 1 : 0);
  }

  void connectTo(Transport transport, {OnResult response = null}) {
    stub.ref.connectTo.asFunction<d_connectTo>()(handle, transport.handle,
        response == null ? nullptr : Hybridge.responses.alloc(response));
  }

  void disconnectFrom(Transport transport) {
    stub.ref.disconnectFrom.asFunction<d_disconnectFrom>()(
        handle, transport.callback.addressOf.cast());
  }

  void timerEvent() {
    return stub.ref.timerEvent.asFunction<d_timerEvent>()(handle);
  }

  void freeChannel() {
    return stub.ref.free.asFunction<d_freeChannel>()(handle);
  }

  MetaObject metaObject(Object object) {
    return MetaObject.get(object.runtimeType);
  }

  String createUuid() {
    return "O${id++}";
  }

  ProxyObject createProxyObject(Pointer<Handle> object) {
    return ProxyObject(object);
  }

  void startTimer(int msec) {
    stdout.writeln("startTimer: ${msec}");
  }

  void stopTimer() {}
}
