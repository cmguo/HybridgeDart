import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:hybridge/hybridge.dart';

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
    return HandleSet.metaObjects[handle]._readProperty(object, propertyIndex);
  }

  static int _writeProperty(Pointer<Handle> handle, Pointer<Handle> object,
      int propertyIndex, Pointer<Void> result) {
    return HandleSet.metaObjects[handle]
            ._writeProperty(object, propertyIndex, result)
        ? 1
        : 0;
  }

  static Pointer<Void> _invokeMethod(Pointer<Handle> handle,
      Pointer<Handle> object, int methodIndex, Pointer<Pointer<Void>> args) {
    return HandleSet.metaObjects[handle]
        ._invokeMethod(object, methodIndex, args);
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
  Map<String, dynamic> _meta;

  MetaObject(Map<String, dynamic> meta) {
    callback = HandleSet.metaObjects.alloc(this);
    metaData = Utf8.toUtf8(jsonEncode(meta));
    _meta = meta;
  }

  Pointer<Void> _readProperty(Pointer<Handle> object, int propertyIndex) {
    List<dynamic> prop = (_meta["properties"] as List<List<dynamic>>)
        .firstWhere((p) => p[3] == propertyIndex);
    return toValue(ValueType.values[prop[2]],
        readProperty(HandleSet.nativeObjects[object], propertyIndex));
  }

  bool _writeProperty(
      Pointer<Handle> object, int propertyIndex, Pointer<Void> value) {
    List<dynamic> prop = (_meta["properties"] as List<List<dynamic>>)
        .firstWhere((p) => p[3] == propertyIndex);
    return writeProperty(HandleSet.nativeObjects[object], propertyIndex,
        fromValue(ValueType.values[prop[2]], value));
  }

  Pointer<Void> _invokeMethod(
      Pointer<Handle> object, int methodIndex, Pointer<Pointer<Void>> args) {
    List<dynamic> method = (_meta["methods"] as List<List<dynamic>>)
        .firstWhere((p) => p[2] == methodIndex);
    List<dynamic> argv = (method[5] as List<int>)
        .mapWithIndex((i, t) => fromValue(ValueType.values[t], args[i]))
        .toList();
    return toValue(ValueType.values[method[4]],
        invokeMethod(HandleSet.nativeObjects[object], methodIndex, argv));
  }

  dynamic readProperty(Object object, int propertyIndex);

  bool writeProperty(Object object, int propertyIndex, dynamic value);

  dynamic invokeMethod(Object object, int methodIndex, List<dynamic> args);
}
