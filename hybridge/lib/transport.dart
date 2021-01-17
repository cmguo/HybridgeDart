import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

import 'src/hybridge.dart';
import 'src/transports.dart';
import 'src/handleptr.dart';

class Transport {
  static Pointer<TransportStub> stub = Hybridge.transportStub;

  Pointer<void> handle;
  Handle callback;

  Transport() {
    callback = Hybridge.transports.alloc(this);
    handle =
        stub.ref.create.asFunction<d_createTransport>()(callback.addressOf);
  }

  void messageReceived(String message) {
    stub.ref.messageReceived.asFunction<d_messageReceived>()(
        handle, Utf8.toUtf8(message));
  }

  void sendMessage(String message) {
    stdout.writeln("sendMessage: ${message}");
  }
}
