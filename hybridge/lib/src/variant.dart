import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'proxyobject.dart';
import 'hybridgec.dart';

enum ValueType {
  None,
  Bool,
  Int,
  Long,
  Float,
  Double,
  String,
  Array_,
  Map_,
  Object_,
  NativeObject,
  ProxyObject,
}

class CHeader extends Struct {
  @Int32()
  int magic;
  @IntPtr()
  int size;
  Pointer<Void> block;
}

class CEntry {
  ValueType type;
  dynamic value;
  CEntry(this.type, this.value);
}

class CString {
  static int MAGIC = 0x525453; // LITTLE ENDIAN

  static String fromValue(Pointer<Void> value) {
    var h = value.cast<CHeader>().ref;
    assert(h.magic == MAGIC);
    return Utf8.fromUtf8(h.block.cast());
  }

  static Pointer<Void> toValue(String string) {
    var h = Hybridge.allocStruct<CHeader>().ref;
    h.magic = MAGIC;
    h.size = string.length + 1;
    h.block = Utf8.toUtf8(string).cast();
    return h.addressOf.cast();
  }
}

class CArrayEntry extends Struct {
  @Int32()
  int type;
  Pointer<Void> value;

  void fromEntry(CEntry e) {
    type = e.type.index;
    value = toValue(e.type, e.value);
  }

  CEntry toEntry() {
    return CEntry(
        ValueType.values[type], fromValue(ValueType.values[type], value));
  }
}

class CArray {
  static int MAGIC = 0x525241; // LITTLE ENDIAN

  static List<CEntry> decode(Pointer<Void> value) {
    var h = value.cast<CHeader>().ref;
    assert(h.magic == MAGIC);
    Pointer<CArrayEntry> array = h.block.cast();
    int n = (h.size / sizeOf<CArrayEntry>()).floor();
    var list = List<dynamic>();
    for (int i = 0; i < n; ++i) {
      CArrayEntry e = array.elementAt(i).ref;
      list.add(e.toEntry());
    }
    return list;
  }

  static Pointer<Void> encode(List<CEntry> list) {
    var h = Hybridge.allocStruct<CHeader>().ref;
    h.magic = MAGIC;
    h.size = sizeOf<CArrayEntry>() * list.length;
    h.block = Hybridge.allocBuffer(h.size);
    Pointer<CArrayEntry> array = h.block.cast();
    for (int i = 0; i < list.length; ++i) {
      array.elementAt(i).ref.fromEntry(list.elementAt(i));
    }
    return h.addressOf.cast();
  }
}

extension VariantList on List<CEntry> {
  List<T> nativeList<T>() {
    return map((e) => e.value);
  }

  List<Object> nativeObjectList() {
    return map((e) => HandleSet.nativeObjects[e.value]);
  }

  List<ProxyObject> proxyObjectList() {
    return map((e) => HandleSet.proxyObjects[e.value]);
  }
}

extension NativeList<T> on List<T> {
  List<CEntry> valueList(ValueType type) {
    return map((e) => CEntry(type, e));
  }
}

extension NativeObjectList on List<Object> {
  List<CEntry> variantList() {
    return map((e) =>
        CEntry(ValueType.Object_, HandleSet.nativeObjects.alloc(e).cast()));
  }
}

extension ProxyObjectList on List<ProxyObject> {
  List<CEntry> variantList() {
    return map((e) =>
        CEntry(ValueType.Object_, HandleSet.proxyObjects.alloc(e).cast()));
  }
}

class CMapEntry extends Struct {
  Pointer<Void> key; // String
  @Int32()
  int type;
  Pointer<Void> value;

  void fromEntry(CEntry e) {
    type = e.type.index;
    value = toValue(e.type, e.value);
  }

  CEntry toEntry() {
    return CEntry(
        ValueType.values[type], fromValue(ValueType.values[type], value));
  }
}

class CMap {
  static int MAGIC = 0x50414d; // LITTLE ENDIAN

  static Map<String, CEntry> decode(Pointer<Void> value) {
    var h = value.cast<CHeader>().ref;
    assert(h.magic == MAGIC);
    Pointer<CMapEntry> array = h.block.cast();
    int n = (h.size / sizeOf<CArrayEntry>()).floor();
    var map = Map<String, CEntry>();
    for (int i = 0; i < n; ++i) {
      CMapEntry e = array.elementAt(i).ref;
      map[Utf8.fromUtf8(e.key.cast())] = e.toEntry();
    }
    return map;
  }

  static Pointer<Void> encode(Map<String, CEntry> map) {
    var h = Hybridge.allocStruct<CHeader>().ref;
    h.magic = MAGIC;
    h.size = sizeOf<CMapEntry>() * map.length;
    h.block = Hybridge.allocBuffer(h.size);
    Pointer<CMapEntry> array = h.block.cast();
    for (int i = 0; i < map.length; ++i) {
      CMapEntry e = array.elementAt(i).ref;
      e.key = Utf8.toUtf8(map.keys.elementAt(i)).cast();
      e.fromEntry(map.values.elementAt(i));
    }
    return h.addressOf.cast();
  }
}

extension VariantMap on Map<String, CEntry> {
  Map<String, T> nativeMap<T>() {
    return map((k, v) => MapEntry(k, v.value));
  }

  Map<String, Object> nativeObjectMap() {
    return map((k, v) => MapEntry(k, HandleSet.nativeObjects[v.value]));
  }

  Map<String, ProxyObject> proxyObjectMap() {
    return map((k, v) => MapEntry(k, HandleSet.proxyObjects[v.value]));
  }
}

extension NativeMap<T> on Map<String, T> {
  Map<String, CEntry> variantMap(ValueType type) {
    return map((k, v) => MapEntry(k, CEntry(type, v)));
  }
}

extension NativeObjectMap on Map<String, Object> {
  Map<String, CEntry> variantMap() {
    return map((k, v) => MapEntry(
        k, CEntry(ValueType.Object_, HandleSet.nativeObjects.alloc(v).cast())));
  }
}

extension ProxyObjectMap on Map<String, ProxyObject> {
  Map<String, CEntry> variantMap() {
    return map((k, v) => MapEntry(
        k, CEntry(ValueType.Object_, HandleSet.proxyObjects.alloc(v).cast())));
  }
}

/* Converters */

abstract class Converter {
  dynamic fromValue(Pointer<Void> value);
  Pointer<Void> toValue(dynamic variant);
}

class BoolConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return value.cast<IntPtr>().value != 0;
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocIntPtr((variant as bool) ? 1 : 0).cast();
  }
}

class IntConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return value.cast<Int32>().value;
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocInt32(variant).cast();
  }
}

class LongConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return value.cast<Int64>().value;
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocInt64(variant).cast();
  }
}

class FloatConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return value.cast<Float>().value;
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocFloat(variant).cast();
  }
}

class DoubleConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return value.cast<Double>().value;
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocDouble(variant).cast();
  }
}

class StringConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return CString.fromValue(value);
  }

  @override
  Pointer<Void> toValue(variant) {
    return CString.toValue(variant);
  }
}

// convert from/to List<CEntry>
class ArrayConverter extends Converter {
  @override
  dynamic fromValue(Pointer<Void> value) {
    return CArray.decode(value);
  }

  @override
  Pointer<Void> toValue(dynamic variant) {
    return CArray.encode(variant);
  }
}

// convert from/to List<CEntry>
class MapConverter extends Converter {
  @override
  dynamic fromValue(Pointer<Void> value) {
    return CMap.decode(value);
  }

  @override
  Pointer<Void> toValue(variant) {
    return CMap.encode(variant);
  }
}

class ObjectConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return value.cast<Pointer<Handle>>().value;
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocPointer(variant as Pointer<Handle>).cast();
  }
}

class NativeObjectConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return HandleSet.nativeObjects[value.cast<Pointer<Handle>>().value];
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocPointer(HandleSet.nativeObjects.alloc(variant).cast())
        .cast();
  }
}

class ProxyObjectConverter extends Converter {
  @override
  fromValue(Pointer<Void> value) {
    return HandleSet.proxyObjects[value.cast<Pointer<Handle>>().value];
  }

  @override
  Pointer<Void> toValue(variant) {
    return Hybridge.allocPointer(HandleSet.proxyObjects.alloc(variant).cast())
        .cast();
  }
}

final converters = [
  null,
  BoolConverter(),
  IntConverter(),
  LongConverter(),
  FloatConverter(),
  DoubleConverter(),
  StringConverter(),
  ArrayConverter(),
  MapConverter(),
  ObjectConverter(),
  NativeObjectConverter(),
  ProxyObjectConverter()
];

dynamic fromValue(ValueType type, Pointer<Void> value) {
  Converter conv = converters[type.index];
  return conv.fromValue(value);
}

Pointer<Void> toValue(ValueType type, variant) {
  Converter conv = converters[type.index];
  return conv.toValue(variant);
}

class VariantArgs {
  Pointer<Pointer<Void>> args;

  VariantArgs(int count) {
    args = Hybridge.allocArray(count);
  }

  VariantArgs.fromArgs(this.args);

  void setArg(int index, ValueType type, variant) {
    args[0] = toValue(type, variant);
  }

  arg(int index, ValueType type) {
    return fromValue(type, args[index]);
  }
}

typedef T MappedWithIndex<S, T>(int index, S value);

class MappedWithIndexIterator<S, T> extends Iterator<T> {
  T _current;
  final Iterator<S> _iterator;
  final MappedWithIndex _f;
  int _index = 0;

  MappedWithIndexIterator(this._iterator, this._f);

  bool moveNext() {
    if (_iterator.moveNext()) {
      _current = _f(_index++, _iterator.current);
      return true;
    }
    _current = null;
    return false;
  }

  T get current {
    final cur = _current;
    return (cur != null) ? cur : cur as T;
  }
}

class MappedWithIndexIterable<S, T> extends Iterable<T> {
  final Iterable<S> _iterable;
  final MappedWithIndex _f;

  factory MappedWithIndexIterable(
      Iterable<S> iterable, MappedWithIndex function) {
    return new MappedWithIndexIterable<S, T>._(iterable, function);
  }

  MappedWithIndexIterable._(this._iterable, this._f);

  Iterator<T> get iterator =>
      new MappedWithIndexIterator<S, T>(_iterable.iterator, _f);

  // Length related functions are independent of the mapping.
  int get length => _iterable.length;
  bool get isEmpty => _iterable.isEmpty;

  // Index based lookup can be done before transforming.
  T get first => _f(0, _iterable.first);
  T get last => _f(_iterable.length - 1, _iterable.last);
  T get single => _f(0, _iterable.single);
  T elementAt(int index) => _f(index, _iterable.elementAt(index));
}

extension ListMapWithIndex<T> on Iterable<T> {
  Iterable<R> mapWithIndex<R>(R f(int, T)) {
    return MappedWithIndexIterable<T, R>(this, f);
  }
}
