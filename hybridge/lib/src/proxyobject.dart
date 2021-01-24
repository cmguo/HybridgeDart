import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'hybridgec.dart';
import 'variant.dart';

/* MetaObject Callback */

typedef c_metaData = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef c_readProperty = Pointer<Void> Function(
    Pointer<Handle> handle, Pointer<Utf8> property);
typedef c_writeProperty = IntPtr Function(
    Pointer<Handle> handle, Pointer<Utf8> property, Pointer<Void> value);
typedef c_invokeMethod = IntPtr Function(
    Pointer<Handle> handle,
    Pointer<Utf8> method,
    Pointer<Pointer<Void>> args,
    Pointer<Handle> response);
typedef c_connect = IntPtr Function(
    Pointer<Handle> handle, IntPtr signalIndex, Pointer<Handle> response);
typedef c_disconnect = IntPtr Function(
    Pointer<Handle> handle, IntPtr signalIndex, Pointer<Handle> response);

typedef d_metaData = Pointer<Utf8> Function(Pointer<Handle> handle);
typedef d_readProperty = Pointer<Void> Function(
    Pointer<Handle> handle, Pointer<Utf8> property);
typedef d_writeProperty = int Function(
    Pointer<Handle> handle, Pointer<Utf8> property, Pointer<Void> value);
typedef d_invokeMethod = int Function(
    Pointer<Handle> handle,
    Pointer<Utf8> method,
    Pointer<Pointer<Void>> args,
    Pointer<Handle> response);
typedef d_connect = int Function(
    Pointer<Handle> handle, int signalIndex, Pointer<Handle> response);
typedef d_disconnect = int Function(
    Pointer<Handle> handle, int signalIndex, Pointer<Handle> response);

class ProxyObjectStub extends Struct {
  Pointer<NativeFunction<c_metaData>> metaData;
  Pointer<NativeFunction<c_readProperty>> readProperty;
  Pointer<NativeFunction<c_writeProperty>> writeProperty;
  Pointer<NativeFunction<c_invokeMethod>> invokeMethod;
  Pointer<NativeFunction<c_connect>> connect;
  Pointer<NativeFunction<c_disconnect>> disconnect;
}

typedef c_onResult = Void Function(
    Pointer<Handle> handle, Pointer<Void> result);

typedef void d_onResult(Pointer<Void> result);

typedef void OnResult(Pointer<Void> result);

typedef T ResultMapper<T>(Pointer<Void> result);

class OnResultCallbackStub extends Struct {
  static void _apply(Pointer<Handle> handle, Pointer<Void> result) {
    return HandleSet.responses.free(handle)(result);
  }

  Pointer<NativeFunction<c_onResult>> apply;
  factory OnResultCallbackStub.alloc() {
    OnResultCallbackStub stub = Hybridge.alloc<OnResultCallbackStub>().ref;
    stub.apply = Pointer.fromFunction(_apply);
    return stub;
  }
}

typedef c_onSignal = Void Function(Pointer<Handle> handle,
    Pointer<Handle> object, IntPtr signalIndex, Pointer<Pointer<Void>> args);

typedef void d_onSignal(Pointer<Handle> handle, Pointer<Handle> object,
    int signalIndex, Pointer<Pointer<Void>> args);

typedef void OnSignal(
    ProxyObject object, int signalIndex, Pointer<Pointer<Void>> args);

class OnSignalCallbackStub extends Struct {
  static void _apply(Pointer<Handle> handle, Pointer<Handle> object,
      int signalIndex, Pointer<Pointer<Void>> args) {
    return HandleSet.signalHandlers[handle](
        HandleSet.proxyObjects[object], signalIndex, args);
  }

  Pointer<NativeFunction<c_onSignal>> apply;
  factory OnSignalCallbackStub.alloc() {
    OnSignalCallbackStub stub = Hybridge.alloc<OnSignalCallbackStub>().ref;
    stub.apply = Pointer.fromFunction(_apply);
    return stub;
  }
}

class ProxyObject {
  Pointer<Handle> handle;
  Pointer<ProxyObjectStub> stub;
  Map<String, dynamic> _meta;

  ProxyObject(this.handle) {
    HandleSet.proxyObjects[handle] = this;
    stub = handle.ref.callback.cast();
    var data = stub.ref.metaData.asFunction<d_metaData>()(handle);
    String metaData = Utf8.fromUtf8(data);
    _meta = jsonDecode(metaData);
    Hybridge.freeBuffer(ValueType.None, data.cast<Void>());
  }

  T readProperty<T>(String property) {
    List<dynamic> prop = (_meta["properties"] as List<dynamic>)
        .firstWhere((p) => p[0] == property);
    Pointer<Void> value = stub.ref.readProperty.asFunction<d_readProperty>()(
        handle, Utf8.toUtf8(property));
    T t = fromValue(ValueType.values[prop[2]], value);
    Hybridge.freeBuffer(ValueType.values[prop[2]], value);
    return t;
  }

  bool writeProperty(String property, dynamic value) {
    List<dynamic> prop = (_meta["properties"] as List<dynamic>)
        .firstWhere((p) => p[0] == property);
    Pointer<Void> t = toValue(ValueType.values[prop[2]], value);
    return 0 !=
        stub.ref.writeProperty.asFunction<d_writeProperty>()(
            handle, Utf8.toUtf8(property), t);
  }

  Future<T> invokeMethod<T>(String method, List<dynamic> args) {
    List<dynamic> mehd =
        (_meta["methods"] as List<dynamic>).firstWhere((p) => p[0] == method);
    List<Pointer<Void>> argv = (mehd[5] as List<dynamic>)
        .mapWithIndex((i, t) => toValue(ValueType.values[t], args[i]));
    var completer = Completer<T>();
    stub.ref.invokeMethod.asFunction<d_invokeMethod>()(
        handle, Utf8.toUtf8(method), Hybridge.allocPointerList(argv),
        HandleSet.responses.alloc((result) {
      completer.complete(fromValue(ValueType.values[mehd[4]], result));
    }));
    return completer.future;
  }

  bool connect(int signalIndex, OnSignal handler) {
    return 0 !=
        stub.ref.connect.asFunction<d_connect>()(
            handle, signalIndex, HandleSet.signalHandlers.alloc(handler));
  }

  bool disconnect(int signalIndex, OnSignal handler) {
    return 0 !=
        stub.ref.disconnect.asFunction<d_connect>()(
            handle, signalIndex, HandleSet.signalHandlers.freeObject(handler));
  }
}
