import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'hybridgec.dart';
import 'transports.dart';
import 'handleptr.dart';

class Transport {
  Pointer<Handle> handle;
  Pointer<TransportStub> stub;
  Pointer<Handle> callback;

  Transport() {
    callback = HandleSet.transports.alloc(this);
    handle = Hybridge.createTransport.asFunction<d_createTransport>()(callback);
    stub = handle.ref.callback.cast();
  }

  void messageReceived(String message) {
    stub.ref.messageReceived.asFunction<d_messageReceived>()(
        handle, Utf8.toUtf8(message));
  }

  void sendMessage(String message) {
    stdout.writeln("sendMessage: $message");
  }
}
