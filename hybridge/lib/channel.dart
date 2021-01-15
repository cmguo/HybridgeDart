import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'src/channelc.dart';
import 'src/hybridgec.dart';
import 'src/handleptr.dart';
import 'src/objects.dart';
import 'src/meta.dart';
import 'transport.dart';

class Channel {
  static Pointer<ChannelStub> stub = Hybridge.instance.channelStub;

  Pointer<Void> handle;
  Handle callback;

  int id;
  Pointer<Utf8> uuid;

  Channel() {
    callback = ChannelCallbackStub.newCallback(this);
    handle = stub.ref.create.asFunction<d_createChannel>()(callback.addressOf);
  }

  void registerObject(String name, dynamic object) {
    stub.ref.registerObject.asFunction<d_registerObject>()(
        handle, Utf8.toUtf8(name), Objects.get(object).cast<Void>());
  }

  void deregisterObject(String name, dynamic object) {
    stub.ref.deregisterObject.asFunction<d_deregisterObject>()(
        handle, Objects.get(object).cast());
  }

  bool blockUpdates() {
    return stub.ref.blockUpdates.asFunction<d_blockUpdates>()(handle) != 0;
  }

  void setBlockUpdates(bool block) {
    return stub.ref.setBlockUpdates.asFunction<d_setBlockUpdates>()(
        handle, block ? 1 : 0);
  }

  void connectTo(Transport transport, Handle response) {
    stub.ref.connectTo.asFunction<d_connectTo>()(
        handle, transport.callback.addressOf.cast(), response.addressOf);
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

  Pointer<Handle> metaObject(Pointer<Handle> object) {
    Object o = Objects.find(object);
    return MetaObject.get(o.runtimeType);
  }

  Pointer<Utf8> createUuid() {
    uuid = Utf8.toUtf8("O${id++}");
    return uuid;
  }

  Pointer<Handle> createProxyObject(Pointer<Handle> object) {}

  void startTimer(int msec) {}

  void stopTimer() {}
}
