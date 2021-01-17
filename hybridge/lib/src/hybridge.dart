import 'dart:io' show Platform;
import 'dart:ffi';

import 'proxyobject.dart';
import 'handleptr.dart';
import 'channels.dart';
import 'transports.dart';
import 'objects.dart';
import 'meta.dart';
import '../channel.dart';
import '../transport.dart';

typedef c_alloc = Pointer<Void> Function(IntPtr size);
typedef c_free = Void Function(Pointer<Void> ptr);
typedef c_allocBuffer = Pointer<Void> Function(IntPtr size);
typedef c_resetBuffer = Void Function();

typedef d_alloc = Pointer<Void> Function(int size);
typedef d_free = void Function(Pointer<Void> ptr);
typedef d_allocBuffer = Pointer<Void> Function(int size);
typedef d_resetBuffer = void Function();

enum VaueType {
  Bool,
  Int,
  Long,
  Float,
  Double,
  String,
  Array_,
  Map_,
  Object_,
  None
}

class Hybridge {
  static final instance = Hybridge();
  static final lib = DynamicLibrary.open(libpath());

  static Pointer<ChannelStub> channelStub = lib.lookup("channelStub");
  static Pointer<TransportStub> transportStub = lib.lookup("transportStub");
  static Pointer<NativeFunction<c_alloc>> _alloc = lib.lookup("hybridgeAlloc");
  static Pointer<NativeFunction<c_free>> _free = lib.lookup("hybridgeFree");
  static Pointer<NativeFunction<c_allocBuffer>> _allocBuffer =
      lib.lookup("allocBuffer");
  static Pointer<NativeFunction<c_resetBuffer>> _resetBuffer =
      lib.lookup("resetBuffer");

  static final channels =
      HandleSet<Channel, ChannelCallbackStub>(ChannelCallbackStub.alloc());

  static final transports = HandleSet<Transport, TransportCallbackStub>(
      TransportCallbackStub.alloc());

  static final metaObjects = HandleSet<MetaObject, MetaObjectCallbackStub>(
      MetaObjectCallbackStub.alloc());

  static final objects =
      HandleSet<Object, ObjectCallbackStub>(ObjectCallbackStub.alloc());

  static final proxyObject = HandleSet<ProxyObject, OnSignalCallbackStub>(
      OnSignalCallbackStub.alloc());

  static final responses =
      HandleSet<OnResult, OnResultCallbackStub>(OnResultCallbackStub.alloc());

  static final signalHandlers =
      HandleSet<OnSignal, OnSignalCallbackStub>(OnSignalCallbackStub.alloc());

  static String libpath() {
    var path = 'libHybridgeC.so';
    if (Platform.isMacOS) path = 'libHybridgeC.dylib';
    if (Platform.isWindows) path = r'HybridgeCd.dll';
    return path;
  }

  static T alloc<T extends Struct>() {
    return _alloc.asFunction<d_alloc>()(sizeOf<T>()).cast<T>().ref;
  }

  static void free<T extends Struct>(T t) {
    _free.asFunction<d_free>()(t.addressOf.cast());
  }

  static Pointer<Void> allocBuffer(int size) {
    return _allocBuffer.asFunction<d_allocBuffer>()(size);
  }

  static T allocBuffer2<T extends Struct>() {
    return _allocBuffer.asFunction<d_allocBuffer>()(sizeOf<T>()).cast<T>().ref;
  }

  static void resetBuffer() {
    return _resetBuffer.asFunction<d_resetBuffer>()();
  }
}
