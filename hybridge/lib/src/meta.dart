import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';

/* MetaObject Callback */

typedef f_metaData = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef f_readProperty = IntPtr Function(Pointer<Handle> handle,
    Pointer<Handle> object, IntPtr propertyIndex, Pointer<Void> result);
typedef f_writeProperty = IntPtr Function(Pointer<Handle> handle,
    Pointer<Handle> object, IntPtr propertyIndex, Pointer<Void> value);
typedef f_invokeMethod = IntPtr Function(
    Pointer<Handle> handle,
    Pointer<Handle> object,
    IntPtr methodIndex,
    Pointer<Pointer<Void>> args,
    Pointer<Void> result);

class MetaObjectCallbackStub extends Struct {
  static final instance = MetaObjectCallbackStub();
  static final Map<Pointer<Handle>, MetaObject> metaObjs = Map();

  static Handle newCallback(MetaObject metaObject) {
    final callback = Handle.fromCallback(MetaObjectCallbackStub.instance);
    metaObjs[callback.addressOf] = metaObject;
    return callback;
  }

  static Pointer<Utf8> _metaData(Pointer<Handle> handle) {
    return metaObjs[handle].metaData;
  }

  static int _readProperty(Pointer<Handle> handle, Pointer<Handle> object,
      int propertyIndex, Pointer<Void> result) {
    return metaObjs[handle].readProperty(object, propertyIndex, result);
  }

  static int _writeProperty(Pointer<Handle> handle, Pointer<Handle> object,
      int propertyIndex, Pointer<Void> result) {
    return metaObjs[handle].writeProperty(object, propertyIndex, result);
  }

  static int _invokeMethod(Pointer<Handle> handle, Pointer<Handle> object,
      int methodIndex, Pointer<Pointer<Void>> args, Pointer<Void> result) {
    return metaObjs[handle].invokeMethod(object, methodIndex, args, result);
  }

  Pointer<NativeFunction<f_metaData>> metaData;
  Pointer<NativeFunction<f_readProperty>> readProperty;
  Pointer<NativeFunction<f_writeProperty>> writeProperty;
  Pointer<NativeFunction<f_invokeMethod>> invokeMethod;

  MetaObjectCallbackStub() {
    metaData = Pointer.fromFunction(_metaData);
    readProperty = Pointer.fromFunction(_readProperty, 0);
    writeProperty = Pointer.fromFunction(_writeProperty, 0);
    invokeMethod = Pointer.fromFunction(_invokeMethod, 0);
  }
}

/* impls */

abstract class MetaObject {
  static final Map<Type, MetaObject> metaObjs = Map();

  static add(Type type, MetaObject metaObj) {
    metaObjs[type] = metaObj;
  }

  static Pointer<Handle> get(Type type) {
    return metaObjs[type].callback.addressOf;
  }

  Handle callback;
  Pointer<Utf8> metaData;

  MetaObject(String meta) {
    callback = MetaObjectCallbackStub.newCallback(this);
    metaData = Utf8.toUtf8(meta);
  }

  int readProperty(
      Pointer<Handle> object, int propertyIndex, Pointer<Void> result);

  int writeProperty(
      Pointer<Handle> object, int propertyIndex, Pointer<Void> result);

  int invokeMethod(Pointer<Handle> object, int methodIndex,
      Pointer<Pointer<Void>> args, Pointer<Void> result);
}
