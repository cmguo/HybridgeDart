import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'hybridgec.dart';

/* Callback */

typedef f_sendMessage = Void Function(
    Pointer<Handle> handle, Pointer<Utf8> message);

class TransportCallbackStub extends Struct {
  static void _sendMessage(Pointer<Handle> handle, Pointer<Utf8> message) {
    return HandleSet.transports[handle].sendMessage(Utf8.fromUtf8(message));
  }

  Pointer<NativeFunction<f_sendMessage>> sendMessage;

  factory TransportCallbackStub.alloc() {
    TransportCallbackStub stub = Hybridge.alloc<TransportCallbackStub>().ref;
    stub.sendMessage = Pointer.fromFunction(_sendMessage);
    return stub;
  }
}

/* Transport */

typedef c_messageReceived = Void Function(
    Pointer<Handle> Transport, Pointer<Utf8> message);
typedef c_freeTransport = Void Function(Pointer<Handle> transport);

typedef d_messageReceived = void Function(
    Pointer<Handle> Transport, Pointer<Utf8> message);
typedef d_freeTransport = void Function(Pointer<Handle> transport);

class TransportStub extends Struct {
  Pointer<NativeFunction<c_messageReceived>> messageReceived;
  Pointer<NativeFunction<c_freeTransport>> free;
}
