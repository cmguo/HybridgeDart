import 'dart:ffi';

import 'hybridgec.dart';

class ObjectCallbackStub extends Struct {
  Pointer<Void> unused;
  factory ObjectCallbackStub.alloc() {
    return Hybridge.alloc<ObjectCallbackStub>().ref;
  }
}
