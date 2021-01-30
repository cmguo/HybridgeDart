import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'hybridgec.dart';
import 'transports.dart';
import 'handleptr.dart';

class Transport {
  static Pointer<TransportStub> stub = Hybridge.transportStub;

  Pointer<void> handle;
  Pointer<Handle> callback;

  Transport() {
    callback = HandleSet.transports.alloc(this);
    handle = stub.ref.create.asFunction<d_createTransport>()(callback);
  }

  void messageReceived(String message) {
    stub.ref.messageReceived.asFunction<d_messageReceived>()(
        handle, Utf8.toUtf8(message));
  }

  void sendMessage(String message) {
    stdout.writeln("sendMessage: $message");
  }
}
