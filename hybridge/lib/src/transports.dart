import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'hybridge.dart';
import '../transport.dart';

/* Callback */

typedef f_sendMessage = Void Function(
    Pointer<Handle> handle, Pointer<Utf8> message);

class TransportCallbackStub extends Struct {
  static void _sendMessage(Pointer<Handle> handle, Pointer<Utf8> message) {
    return Hybridge.transports[handle].sendMessage(Utf8.fromUtf8(message));
  }

  Pointer<NativeFunction<f_sendMessage>> sendMessage;

  factory TransportCallbackStub.alloc() {
    TransportCallbackStub stub = Hybridge.alloc<TransportCallbackStub>();
    stub.sendMessage = Pointer.fromFunction(_sendMessage);
    return stub;
  }
}

/* Transport */

typedef c_createTransport = Pointer<Void> Function(Pointer<Handle> handle);
typedef c_messageReceived = Void Function(
    Pointer<Void> Transport, Pointer<Utf8> message);
typedef c_freeTransport = Void Function(Pointer<Void> Transport);

typedef d_createTransport = Pointer<Void> Function(Pointer<Handle> handle);
typedef d_messageReceived = void Function(
    Pointer<Void> Transport, Pointer<Utf8> message);
typedef d_freeTransport = void Function(Pointer<Void> Transport);

class TransportStub extends Struct {
  Pointer<NativeFunction<c_createTransport>> create;
  Pointer<NativeFunction<c_messageReceived>> messageReceived;
  Pointer<NativeFunction<c_freeTransport>> free;
}
