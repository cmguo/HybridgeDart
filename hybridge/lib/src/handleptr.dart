import 'dart:ffi';

import 'hybridgec.dart';
import 'proxyobject.dart';
import 'channels.dart';
import 'transports.dart';
import 'objects.dart';
import 'meta.dart';
import 'channel.dart';
import 'transport.dart';

class Handle extends Struct {
  Pointer<Void> callback;

  Handle(Pointer<Void> c) {
    callback = c;
  }

  static Pointer<Handle> alloc<C extends Struct>(C callback) {
    Pointer<Handle> h = Hybridge.alloc<Handle>();
    h.ref.callback = callback.addressOf.cast();
    return h;
  }

  static void free(Pointer<Handle> handle) {
    Hybridge.free(handle);
  }
}

class HandleSet<T, C extends Struct> {
  final Map<Pointer<Handle>, T> objects = Map();
  final Map<T, Pointer<Handle>> handles = Map();
  final C callback;

  HandleSet(this.callback);

  Pointer<Handle> alloc(T object) {
    if (handles.containsKey(object)) {
      return handles[object];
    }
    final handle = Handle.alloc(callback);
    objects[handle] = object;
    handles[object] = handle;
    return handle;
  }

  T free(Pointer<Handle> handle) {
    T object = objects.remove(handle);
    handles.remove(object);
    Handle.free(handle);
    return object;
  }

  Pointer<Handle> freeObject(T object) {
    Pointer<Handle> handle = handles.remove(object);
    objects.remove(handle);
    Handle.free(handle); // TODO: may crash
    return handle;
  }

  T operator [](Pointer<Handle> handle) {
    return objects[handle];
  }

  void operator []=(Pointer<Handle> handle, T object) {
    objects[handle] = object;
    handles[object] = handle;
  }

  static final channels =
      HandleSet<Channel, ChannelCallbackStub>(ChannelCallbackStub.alloc());

  static final transports = HandleSet<Transport, TransportCallbackStub>(
      TransportCallbackStub.alloc());

  static final metaObjects = HandleSet<MetaObject, MetaObjectCallbackStub>(
      MetaObjectCallbackStub.alloc());

  static final nativeObjects =
      HandleSet<Object, ObjectCallbackStub>(ObjectCallbackStub.alloc());

  static final proxyObjects = HandleSet<ProxyObject, ProxyObjectStub>(
      Hybridge.alloc<ProxyObjectStub>().ref);

  static final responses =
      HandleSet<OnResult, OnResultCallbackStub>(OnResultCallbackStub.alloc());

  static final signalHandlers =
      HandleSet<OnSignal, OnSignalCallbackStub>(OnSignalCallbackStub.alloc());
}
