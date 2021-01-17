import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'hybridge.dart';

/* MetaObject Callback */

typedef c_metaData = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef c_readProperty = IntPtr Function(Pointer<Handle> handle,
    Pointer<Handle> object, Pointer<Utf8> property, Pointer<Void> result);
typedef c_writeProperty = IntPtr Function(Pointer<Handle> handle,
    Pointer<Handle> object, Pointer<Utf8> property, Pointer<Void> value);
typedef c_invokeMethod = IntPtr Function(
    Pointer<Handle> handle,
    Pointer<Handle> object,
    Pointer<Utf8> method,
    Pointer<Pointer<Void>> args,
    Pointer<Void> result);

typedef d_metaData = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef d_readProperty = int Function(Pointer<Handle> handle,
    Pointer<Handle> object, int propertyIndex, Pointer<Void> result);
typedef d_writeProperty = int Function(Pointer<Handle> handle,
    Pointer<Handle> object, int propertyIndex, Pointer<Void> value);
typedef d_invokeMethod = int Function(
    Pointer<Handle> handle,
    Pointer<Handle> object,
    int methodIndex,
    Pointer<Pointer<Void>> args,
    Pointer<Void> result);

class ProxyObjectStub extends Struct {
  Pointer<NativeFunction<c_readProperty>> readProperty;
  Pointer<NativeFunction<c_writeProperty>> writeProperty;
  Pointer<NativeFunction<c_invokeMethod>> invokeMethod;
}

typedef c_onResult = Void Function(
    Pointer<Handle> handle, Pointer<Void> result);

typedef void d_onResult(Pointer<Void> result);

typedef void OnResult(Pointer<Void> result);

class OnResultCallbackStub extends Struct {
  static void _apply(Pointer<Handle> handle, Pointer<Void> result) {
    return Hybridge.responses[handle](result);
  }

  Pointer<NativeFunction<c_onResult>> apply;
  factory OnResultCallbackStub.alloc() {
    OnResultCallbackStub stub = Hybridge.alloc<OnResultCallbackStub>();
    stub.apply = Pointer.fromFunction(_apply);
    return stub;
  }
}

typedef c_onSignal = Void Function(Pointer<Handle> handle,
    Pointer<Handle> object, int signalIndex, Pointer<Pointer<Void>> args);

typedef void d_onSignal(Pointer<Handle> handle, Pointer<Handle> object,
    int signalIndex, Pointer<Pointer<Void>> args);

typedef void OnSignal(
    ProxyObject object, int signalIndex, Pointer<Pointer<Void>> args);

class OnSignalCallbackStub extends Struct {
  static void _apply(Pointer<Handle> handle, Pointer<Handle> object,
      int signalIndex, Pointer<Pointer<Void>> args) {
    return Hybridge.signalHandlers[handle](
        Hybridge.objects[object] as ProxyObject, signalIndex, args);
  }

  Pointer<NativeFunction<c_onSignal>> apply;
  factory OnSignalCallbackStub.alloc() {
    OnSignalCallbackStub stub = Hybridge.alloc<OnSignalCallbackStub>();
    stub.apply = Pointer.fromFunction(_apply);
    return stub;
  }
}

class ProxyObject {
  Pointer<Handle> handle;
  Pointer<ProxyObjectStub> stub;

  ProxyObject(this.handle) {
    stub = handle.ref.callback.cast();
  }

  bool invokeMethod(String name, Pointer<Pointer<Void>> args, OnSignal resp) {
    return false;
  }
}
