import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import '../transport.dart';

/* Callback */

typedef f_sendMessage = Void Function(
    Pointer<Handle> handle, Pointer<Utf8> message);

class TransportCallbackStub extends Struct {
  static final instance = TransportCallbackStub();
  static final Map<Pointer<Handle>, Transport> transports = Map();

  static Handle newCallback(Transport Transport) {
    final callback = Handle.fromCallback(TransportCallbackStub.instance);
    transports[callback.addressOf] = Transport;
    return callback;
  }

  static void freeCallback(Handle callback) {
    transports.remove(callback.addressOf);
  }

  static void _sendMessage(Pointer<Handle> handle, Pointer<Utf8> message) {
    return transports[handle].sendMessage(message);
  }

  Pointer<NativeFunction<f_sendMessage>> sendMessage;

  TransportCallbackStub() {
    sendMessage = Pointer.fromFunction(_sendMessage);
  }
}

/* Transport */

typedef f_createTransport = Pointer<Void> Function(Pointer<Handle> handle);
typedef f_messageReceived = Void Function(
    Pointer<Void> Transport, Pointer<Utf8> message);
typedef f_freeTransport = Void Function(Pointer<Void> Transport);

class TransportStub extends Struct {
  Pointer<NativeFunction<f_createTransport>> create;
  Pointer<NativeFunction<f_messageReceived>> timerEvent;
  Pointer<NativeFunction<f_freeTransport>> free;
}
