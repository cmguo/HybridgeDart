import 'dart:io' show Platform;
import 'dart:ffi';

import 'variant.dart';
import 'handleptr.dart';

typedef c_createChannel = Pointer<Handle> Function(Pointer<Handle> handle);
typedef c_createTransport = Pointer<Handle> Function(Pointer<Handle> handle);
typedef c_alloc = Pointer<Void> Function(IntPtr size);
typedef c_free = Void Function(Pointer<Void> ptr);
typedef c_allocBuffer = Pointer<Void> Function(IntPtr size);
typedef c_freeBuffer = Void Function(IntPtr type, Pointer<Void> buffer);

typedef d_createChannel = Pointer<Handle> Function(Pointer<Handle> handle);
typedef d_createTransport = Pointer<Handle> Function(Pointer<Handle> handle);
typedef d_alloc = Pointer<Void> Function(int size);
typedef d_free = void Function(Pointer<Void> ptr);
typedef d_allocBuffer = Pointer<Void> Function(int size);
typedef d_freeBuffer = void Function(int type, Pointer<Void> buffer);

class Hybridge {
  static final instance = Hybridge();
  static final lib = DynamicLibrary.open(libpath());

  static Pointer<NativeFunction<c_createChannel>> createChannel =
      lib.lookup("hybridgeCreateChannel");
  static Pointer<NativeFunction<c_createTransport>> createTransport =
      lib.lookup("hybridgeCreateTransport");
  static Pointer<NativeFunction> transportStub = lib.lookup("transportStub");
  static Pointer<NativeFunction<c_alloc>> _alloc = lib.lookup("hybridgeAlloc");
  static Pointer<NativeFunction<c_free>> _free = lib.lookup("hybridgeFree");
  static Pointer<NativeFunction<c_allocBuffer>> _allocBuffer =
      lib.lookup("allocBuffer");
  static Pointer<NativeFunction<c_freeBuffer>> _freeBuffer =
      lib.lookup("freeBuffer");

  static String libpath() {
    var path = 'libHybridgeC.so';
    if (Platform.isMacOS) path = 'libHybridgeC.dylib';
    if (Platform.isWindows) path = r'HybridgeCd.dll';
    return path;
  }

  static Pointer<T> alloc<T extends Struct>() {
    return _alloc.asFunction<d_alloc>()(sizeOf<T>()).cast();
  }

  static void free<T extends Struct>(Pointer<T> t) {
    _free.asFunction<d_free>()(t.cast());
  }

  static Pointer<Void> allocBuffer(int size) {
    return _allocBuffer.asFunction<d_allocBuffer>()(size);
  }

  static Pointer<T> allocArray<T extends NativeType>(int size) {
    return _allocBuffer.asFunction<d_allocBuffer>()(sizeOf<T>() * size).cast();
  }

  static Pointer<Pointer<T>> allocPointerList<T extends NativeType>(
      List<Pointer<T>> list) {
    Pointer<Pointer<T>> array = _allocBuffer
        .asFunction<d_allocBuffer>()(sizeOf<Pointer<T>>() * list.length)
        .cast();
    for (int i = 0; i < list.length; ++i) {
      array[i] = list.elementAt(i);
    }
    return array;
  }

  static Pointer<T> allocStruct<T extends Struct>() {
    return _allocBuffer.asFunction<d_allocBuffer>()(sizeOf<T>()).cast();
  }

  static Pointer<T> allocNumber<T extends NativeType>() {
    return _allocBuffer.asFunction<d_allocBuffer>()(sizeOf<T>()).cast();
  }

  static Pointer<Int32> allocInt32(int value) {
    var p = allocNumber<Int32>();
    p.value = value;
    return p;
  }

  static Pointer<Int64> allocInt64(int value) {
    var p = allocNumber<Int64>();
    p.value = value;
    return p;
  }

  static Pointer<IntPtr> allocIntPtr(int value) {
    var p = allocNumber<IntPtr>();
    p.value = value;
    return p;
  }

  static Pointer<Float> allocFloat(double value) {
    var p = allocNumber<Float>();
    p.value = value;
    return p;
  }

  static Pointer<Double> allocDouble(double value) {
    var p = allocNumber<Double>();
    p.value = value;
    return p;
  }

  static Pointer<Pointer<T>> allocPointer<T extends NativeType>(
      Pointer<T> value) {
    var p = _allocBuffer
        .asFunction<d_allocBuffer>()(sizeOf<Pointer<T>>())
        .cast<Pointer<T>>();
    p.value = value;
    return p;
  }

  static void freeBuffer(ValueType type, Pointer<void> buffer) {
    return _freeBuffer.asFunction<d_freeBuffer>()(type.index, buffer);
  }
}
