import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import '../channel.dart';

/* Callback */

typedef c_metaObject = Pointer<Handle> Function(
    Pointer<Handle> handle, Pointer<Handle> object);
typedef c_createUuid = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef c_createProxyObject = Pointer<Handle> Function(
    Pointer<Handle> handle, Pointer<Handle> object);
typedef c_startTimer = Void Function(Pointer<Handle> handle, IntPtr msec);
typedef c_stopTimer = Void Function(Pointer<Handle> handle);

class ChannelCallbackStub extends Struct {
  static final instance = ChannelCallbackStub();
  static final Map<Pointer<Handle>, Channel> channels = Map();

  static Handle newCallback(Channel channel) {
    final callback = Handle.fromCallback(ChannelCallbackStub.instance);
    channels[callback.addressOf] = channel;
    return callback;
  }

  static void freeCallback(Handle callback) {
    channels.remove(callback.addressOf);
  }

  static Pointer<Handle> _metaObject(
      Pointer<Handle> handle, Pointer<Handle> object) {
    return channels[handle].metaObject(object);
  }

  static Pointer<Utf8> _createUuid(Pointer<Handle> handle) {
    return channels[handle].createUuid();
  }

  static Pointer<Handle> _createProxyObject(
      Pointer<Handle> handle, Pointer<Handle> object) {
    return channels[handle].createProxyObject(object);
  }

  static void _startTimer(Pointer<Handle> handle, int msec) {
    return channels[handle].startTimer(msec);
  }

  static void _stopTimer(Pointer<Handle> handle) {
    return channels[handle].stopTimer();
  }

  Pointer<NativeFunction<c_metaObject>> metaObject;
  Pointer<NativeFunction<c_createUuid>> createUuid;
  Pointer<NativeFunction<c_createProxyObject>> createProxyObject;
  Pointer<NativeFunction<c_startTimer>> startTimer;
  Pointer<NativeFunction<c_stopTimer>> stopTimer;

  ChannelCallbackStub() {
    metaObject = Pointer.fromFunction(_metaObject);
    createUuid = Pointer.fromFunction(_createUuid);
    createProxyObject = Pointer.fromFunction(_createProxyObject);
    startTimer = Pointer.fromFunction(_startTimer);
    stopTimer = Pointer.fromFunction(_stopTimer);
  }
}

/* Channel */

typedef c_createChannel = Pointer<Void> Function(Pointer<Handle> handle);
typedef c_registerObject = Void Function(
    Pointer<Void> channel, Pointer<Utf8> name, Pointer<Void> object);
typedef c_deregisterObject = Void Function(
    Pointer<Void> channel, Pointer<Void> object);
typedef c_blockUpdates = IntPtr Function(Pointer<Void> channel);
typedef c_setBlockUpdates = Void Function(Pointer<Void> channel, IntPtr block);
typedef c_connectTo = Void Function(
    Pointer<Void> channel, Pointer<Void> transport, Pointer<Handle> response);
typedef c_disconnectFrom = Void Function(
    Pointer<Void> channel, Pointer<Void> transport);
typedef c_timerEvent = Void Function(Pointer<Void> channel);
typedef c_freeChannel = Void Function(Pointer<Void> channel);

typedef d_createChannel = Pointer<Void> Function(Pointer<Handle> handle);
typedef d_registerObject = void Function(
    Pointer<Void> channel, Pointer<Utf8> name, Pointer<Void> object);
typedef d_deregisterObject = void Function(
    Pointer<Void> channel, Pointer<Void> object);
typedef d_blockUpdates = int Function(Pointer<Void> channel);
typedef d_setBlockUpdates = void Function(Pointer<Void> channel, int block);
typedef d_connectTo = void Function(
    Pointer<Void> channel, Pointer<Void> transport, Pointer<Handle> response);
typedef d_disconnectFrom = void Function(
    Pointer<Void> channel, Pointer<Void> transport);
typedef d_timerEvent = void Function(Pointer<Void> channel);
typedef d_freeChannel = void Function(Pointer<Void> channel);

class ChannelStub extends Struct {
  Pointer<NativeFunction<c_createChannel>> create;
  Pointer<NativeFunction<c_registerObject>> registerObject;
  Pointer<NativeFunction<c_deregisterObject>> deregisterObject;
  Pointer<NativeFunction<c_blockUpdates>> blockUpdates;
  Pointer<NativeFunction<c_setBlockUpdates>> setBlockUpdates;
  Pointer<NativeFunction<c_connectTo>> connectTo;
  Pointer<NativeFunction<c_disconnectFrom>> disconnectFrom;
  Pointer<NativeFunction<c_timerEvent>> timerEvent;
  Pointer<NativeFunction<c_freeChannel>> free;
}
