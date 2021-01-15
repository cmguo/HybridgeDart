import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'src/hybridgec.dart';
import 'src/transportc.dart';
import 'src/handleptr.dart';

class Transport {
  static Pointer<TransportStub> stub = Hybridge.instance.transportStub;

  Pointer<void> handle;
  Handle callback;

  Transport() {
    callback = TransportCallbackStub.newCallback(this);
    handle =
        stub.ref.create.asFunction<f_createTransport>()(callback.addressOf);
  }

  void sendMessage(Pointer<Utf8> message) {}
}
