import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';

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

abstract class OnResult
{
    void apply(Pointer<Void> result);
}

abstract class SignalHandler
{
    void apply(ProxyObject object, int signalIndex, Pointer<Pointer<Void>> args);
}

class ProxyObject {

  Pointer<Handle> handle;
  Pointer<ProxyObjectStub> stub;

  bool invokeMethod(String name, Pointer<Pointer<Void>> args, SignalHandler resp)
}
