import 'dart:ffi';

import 'hybridge.dart';

class ObjectCallbackStub extends Struct {
  Pointer<Void> unused;
  factory ObjectCallbackStub.alloc() {
    return Hybridge.alloc<ObjectCallbackStub>();
  }
}
