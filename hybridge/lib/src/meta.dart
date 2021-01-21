import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'hybridgec.dart';

/* MetaObject Callback */

typedef f_metaData = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef f_readProperty = Pointer<Void> Function(
    Pointer<Handle> handle, Pointer<Handle> object, IntPtr propertyIndex);
typedef f_writeProperty = IntPtr Function(Pointer<Handle> handle,
    Pointer<Handle> object, IntPtr propertyIndex, Pointer<Void> value);
typedef f_invokeMethod = Pointer<Void> Function(Pointer<Handle> handle,
    Pointer<Handle> object, IntPtr methodIndex, Pointer<Pointer<Void>> args);

class MetaObjectCallbackStub extends Struct {
  static Pointer<Utf8> _metaData(Pointer<Handle> handle) {
    return HandleSet.metaObjects[handle].metaData;
  }

  static Pointer<Void> _readProperty(
      Pointer<Handle> handle, Pointer<Handle> object, int propertyIndex) {
    return HandleSet.metaObjects[handle].readProperty(object, propertyIndex);
  }

  static int _writeProperty(Pointer<Handle> handle, Pointer<Handle> object,
      int propertyIndex, Pointer<Void> result) {
    return HandleSet.metaObjects[handle]
        .writeProperty(object, propertyIndex, result);
  }

  static Pointer<Void> _invokeMethod(Pointer<Handle> handle,
      Pointer<Handle> object, int methodIndex, Pointer<Pointer<Void>> args) {
    return HandleSet.metaObjects[handle]
        .invokeMethod(object, methodIndex, args);
  }

  Pointer<NativeFunction<f_metaData>> metaData;
  Pointer<NativeFunction<f_readProperty>> readProperty;
  Pointer<NativeFunction<f_writeProperty>> writeProperty;
  Pointer<NativeFunction<f_invokeMethod>> invokeMethod;

  factory MetaObjectCallbackStub.alloc() {
    MetaObjectCallbackStub stub = Hybridge.alloc<MetaObjectCallbackStub>().ref;
    stub.metaData = Pointer.fromFunction(_metaData);
    stub.readProperty = Pointer.fromFunction(_readProperty);
    stub.writeProperty = Pointer.fromFunction(_writeProperty, 0);
    stub.invokeMethod = Pointer.fromFunction(_invokeMethod);
    return stub;
  }
}

/* impls */

abstract class MetaObject {
  static final Map<Type, MetaObject> metaObjs = Map();

  static add(Type type, MetaObject metaObj) {
    metaObjs[type] = metaObj;
  }

  static MetaObject get(Type type) {
    return metaObjs[type];
  }

  Pointer<Handle> callback;
  Pointer<Utf8> metaData;

  MetaObject(String meta) {
    callback = HandleSet.metaObjects.alloc(this);
    metaData = Utf8.toUtf8(meta);
  }

  Pointer<Void> readProperty(Pointer<Handle> object, int propertyIndex);

  int writeProperty(
      Pointer<Handle> object, int propertyIndex, Pointer<Void> result);

  Pointer<Void> invokeMethod(
      Pointer<Handle> object, int methodIndex, Pointer<Pointer<Void>> args);
}
