import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'channels.dart';
import 'hybridgec.dart';
import 'handleptr.dart';
import 'proxyobject.dart';
import 'meta.dart';
import 'transport.dart';
import 'variant.dart';

class Channel {
  static Pointer<ChannelStub> stub = Hybridge.channelStub;

  Pointer<Void> handle;
  Pointer<Handle> callback;

  int id;
  Pointer<Utf8> uuid;

  Channel() {
    callback = HandleSet.channels.alloc(this);
    handle = stub.ref.create.asFunction<d_createChannel>()(callback);
  }

  void registerObject(String name, Object object) {
    stub.ref.registerObject.asFunction<d_registerObject>()(handle,
        Utf8.toUtf8(name), HandleSet.nativeObjects.alloc(object).cast());
  }

  void deregisterObject(String name, Object object) {
    stub.ref.deregisterObject.asFunction<d_deregisterObject>()(
        handle, HandleSet.nativeObjects.freeObject(object).cast());
  }

  bool blockUpdates() {
    return stub.ref.blockUpdates.asFunction<d_blockUpdates>()(handle) != 0;
  }

  void setBlockUpdates(bool block) {
    return stub.ref.setBlockUpdates.asFunction<d_setBlockUpdates>()(
        handle, block ? 1 : 0);
  }

  void connectTo(Transport transport,
      {void callback(Map<String, Object> objects) = null}) {
    OnResult response = callback == null
        ? null
        : (objmap) => callback(CMap.decode(objmap)
            .proxyObjectMap()
            .map((key, value) => MapEntry(key, value.toObject())));
    stub.ref.connectTo.asFunction<d_connectTo>()(handle, transport.handle,
        response == null ? nullptr : HandleSet.responses.alloc(response));
  }

  void disconnectFrom(Transport transport) {
    stub.ref.disconnectFrom.asFunction<d_disconnectFrom>()(
        handle, transport.handle);
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
