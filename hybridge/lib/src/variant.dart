import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'handleptr.dart';
import 'proxyobject.dart';
import 'hybridgec.dart';

enum ValueType {
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

class CHeader extends Struct {
  @Int32()
  int magic;
  @IntPtr()
  int size;
  Pointer<Void> block;
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
  }
}

class CArrayEntry extends Struct {
  @Int32()
  int type;
  Pointer<Void> value;
}

class CArray {
  static int MAGIC = 0x525241; // LITTLE ENDIAN

  static List<Pointer<Void>> fromValue(Pointer<Void> value, ValueType type) {
    var h = value.cast<CHeader>().ref;
    assert(h.magic == MAGIC);
    Pointer<CArrayEntry> array = h.block.cast();
    int n = (h.size / sizeOf<CArrayEntry>()).floor();
    var list = List<Pointer<Void>>();
    for (int i = 0; i < n; ++i) {
      CArrayEntry e = array.elementAt(i).ref;
      assert(e.type == type.index);
      list.add(e.value);
    }
    return list;
  }

  static Pointer<Void> toValue(List<Pointer<Void>> list, ValueType type) {
    var h = Hybridge.allocStruct<CHeader>().ref;
    h.magic = MAGIC;
    h.size = sizeOf<CArrayEntry>() * list.length;
    h.block = Hybridge.allocBuffer(h.size);
    Pointer<CArrayEntry> array = h.block.cast();
    for (int i = 0; i < list.length; ++i) {
      var e = array.elementAt(i).ref;
      e.type = type.index;
      e.value = list.elementAt(i);
    }
  }
}

extension ConverterList on List<Pointer<Void>> {
  List<bool> boolList() {
    return map((e) => e.cast<Int8>().value != 0);
  }

  List<int> int32List() {
    return map((e) => e.cast<Int32>().value);
  }

  List<int> int64List() {
    return map((e) => e.cast<Int64>().value);
  }

  List<double> floatList() {
    return map((e) => e.cast<Float>().value);
  }

  List<double> doubleList() {
    return map((e) => e.cast<Double>().value);
  }

  List<String> stringList() {
    return map((e) => CString.fromValue(e));
  }

  List<Object> nativeObjectList() {
    return map((e) => HandleSet.nativeObjects[e.cast<Pointer<Handle>>().value]);
  }

  List<ProxyObject> proxyObjectList() {
    return map((e) => HandleSet.proxyObjects[e.cast<Pointer<Handle>>().value]);
  }

  List<ProxyObject> dynamicList(List<ValueType> types) {
    return map((e) => fromValue(types, e));
  }
}

extension BoolList on List<bool> {
  List<Pointer<Void>> variantList() {
    return map((e) => Hybridge.allocIntPtr(e ? 1 : 0).cast());
  }
}

extension IntList on List<int> {
  List<Pointer<Void>> variantList(ValueType type) {
    switch (type) {
      case ValueType.Int:
        return map((e) => Hybridge.allocInt32(e).cast());
      case ValueType.Long:
        return map((e) => Hybridge.allocInt64(e).cast());
      default:
        return map((e) => Hybridge.allocIntPtr(e).cast());
    }
  }
}

extension DoubleList on List<double> {
  List<Pointer<Void>> variantList(ValueType type) {
    switch (type) {
      case ValueType.Float:
        return map((e) => Hybridge.allocFloat(e).cast());
      case ValueType.Double:
        return map((e) => Hybridge.allocDouble(e).cast());
      default:
        assert(false);
    }
  }
}

extension StringList on List<String> {
  List<Pointer<Void>> variantList() {
    return map((e) => CString.toValue(e));
  }
}

extension NativeObjectList on List<Object> {
  List<Pointer<Void>> variantList() {
    return map((e) => HandleSet.nativeObjects.alloc(e).cast());
  }
}

extension ProxyObjectList on List<ProxyObject> {
  List<Pointer<Void>> variantList() {
    return map((e) => HandleSet.proxyObjects.alloc(e).cast());
  }
}

extension DynamicList on List<dynamic> {
  List<Pointer<Void>> variantList(List<ValueType> types) {
    return map((e) => toValue(types, e));
  }
}

class CMapEntry extends Struct {
  Pointer<Void> key; // String
  @Int32()
  int type;
  Pointer<Void> value;
}

class CMap {
  static int MAGIC = 0x50414d; // LITTLE ENDIAN

  static Map<String, Pointer<Void>> fromValue(
      Pointer<Void> value, ValueType type) {
    var h = value.cast<CHeader>().ref;
    assert(h.magic == MAGIC);
    Pointer<CMapEntry> array = h.block.cast();
    int n = (h.size / sizeOf<CArrayEntry>()).floor();
    var map = Map<String, Pointer<Void>>();
    for (int i = 0; i < n; ++i) {
      CMapEntry e = array.elementAt(i).ref;
      assert(e.type == type.index);
      map[Utf8.fromUtf8(e.key.cast())] = e.value;
    }
    return map;
  }

  static Pointer<Void> toValue(Map<String, Pointer<Void>> map, ValueType type) {
    var h = Hybridge.allocStruct<CHeader>().ref;
    h.magic = MAGIC;
    h.size = sizeOf<CMapEntry>() * map.length;
    h.block = Hybridge.allocBuffer(h.size);
    Pointer<CMapEntry> array = h.block.cast();
    for (int i = 0; i < map.length; ++i) {
      CMapEntry e = array.elementAt(i).ref;
      e.key = Utf8.toUtf8(map.keys.elementAt(i)).cast();
      e.type = type.index;
      e.value = map.values.elementAt(i);
    }
  }
}

extension ConverterMap on Map<String, Pointer<Void>> {
  Map<String, bool> boolMap() {
    return map((k, v) => MapEntry(k, v.cast<Int8>().value != 0));
  }

  Map<String, int> int32Map() {
    return map((k, v) => MapEntry(k, v.cast<Int32>().value));
  }

  Map<String, int> int64Map() {
    return map((k, v) => MapEntry(k, v.cast<Int64>().value));
  }

  Map<String, double> floatMap() {
    return map((k, v) => MapEntry(k, v.cast<Float>().value));
  }

  Map<String, double> doubleMap() {
    return map((k, v) => MapEntry(k, v.cast<Double>().value));
  }

  Map<String, String> stringMap() {
    return map((k, v) => MapEntry(k, CString.fromValue(v)));
  }

  Map<String, Object> nativeObjectMap() {
    return map((k, v) =>
        MapEntry(k, HandleSet.nativeObjects[v.cast<Pointer<Handle>>().value]));
  }

  Map<String, ProxyObject> proxyObjectMap() {
    return map((k, v) =>
        MapEntry(k, HandleSet.proxyObjects[v.cast<Pointer<Handle>>().value]));
  }

  Map<String, ProxyObject> dynamicMap(List<ValueType> types) {
    return map((k, v) => MapEntry(k, fromValue(types, v)));
  }
}

extension BoolMap on Map<String, bool> {
  Map<String, Pointer<Void>> variantMap() {
    return map((k, v) => MapEntry(k, Hybridge.allocIntPtr(v ? 1 : 0).cast()));
  }
}

extension IntMap on Map<String, int> {
  Map<String, Pointer<Void>> variantMap(ValueType type) {
    switch (type) {
      case ValueType.Int:
        return map((k, v) => MapEntry(k, Hybridge.allocInt32(v).cast()));
      case ValueType.Long:
        return map((k, v) => MapEntry(k, Hybridge.allocInt64(v).cast()));
      default:
        return map((k, v) => MapEntry(k, Hybridge.allocIntPtr(v).cast()));
    }
  }
}

extension DoubleMap on Map<String, double> {
  Map<String, Pointer<Void>> variantMap(ValueType type) {
    switch (type) {
      case ValueType.Float:
        return map((k, v) => MapEntry(k, Hybridge.allocFloat(v).cast()));
      case ValueType.Double:
        return map((k, v) => MapEntry(k, Hybridge.allocDouble(v).cast()));
      default:
        assert(false);
        return {};
    }
  }
}

extension StringMap on Map<String, String> {
  Map<String, Pointer<Void>> variantMap() {
    return map((k, v) => MapEntry(k, CString.toValue(v)));
  }
}

extension NativeObjectMap on Map<String, Object> {
  Map<String, Pointer<Void>> variantMap() {
    return map((k, v) => MapEntry(k, HandleSet.nativeObjects.alloc(v).cast()));
  }
}

extension ProxyObjectMap on Map<String, ProxyObject> {
  Map<String, Pointer<Void>> variantMap() {
    return map((k, v) => MapEntry(k, HandleSet.proxyObjects.alloc(v).cast()));
  }
}

extension DynamicMap on Map<String, dynamic> {
  Map<String, Pointer<Void>> variantMap(List<ValueType> types) {
    return map((k, v) => MapEntry(k, toValue(types, v)));
  }
}

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

abstract class CollectionConverter extends Converter {
  List<ValueType> elementTypes;
}

class ArrayConverter extends CollectionConverter {
  @override
  fromValue(Pointer<Void> value) {
    return CArray.fromValue(value, elementTypes.first)
        .dynamicList(elementTypes);
  }

  @override
  Pointer<Void> toValue(variant) {
    return CArray.toValue(
        DynamicList(variant).variantList(elementTypes), elementTypes.first);
  }
}

class MapConverter extends CollectionConverter {
  @override
  fromValue(Pointer<Void> value) {
    return CMap.fromValue(value, elementTypes.first).dynamicMap(elementTypes);
  }

  @override
  Pointer<Void> toValue(variant) {
    return CMap.toValue(
        DynamicMap(variant).variantMap(elementTypes), elementTypes.first);
  }
}

final converters = [
  BoolConverter(),
  IntConverter(),
  LongConverter(),
  FloatConverter(),
  DoubleConverter(),
  StringConverter(),
  ArrayConverter(),
  MapConverter(),
  NativeObjectConverter()
];

dynamic fromValue(List<ValueType> types, Pointer<Void> value) {
  ValueType type = types.first;
  Converter conv = converters[type.index];
  if (conv is CollectionConverter) {
    conv.elementTypes = types.sublist(1);
  }
  return conv.fromValue(value);
}

Pointer<Void> toValue(List<ValueType> types, variant) {
  ValueType type = types.first;
  Converter conv = converters[type.index];
  if (conv is CollectionConverter) {
    conv.elementTypes = types.sublist(1);
  }
  return conv.toValue(variant);
}

class VariantArgs {
  Pointer<Pointer<Void>> args;

  VariantArgs(int count) {
    args = Hybridge.allocArray(count);
  }

  VariantArgs.fromArgs(this.args);

  void setArg(int index, List<ValueType> types, variant) {
    args[0] = toValue(types, variant);
  }

  arg(int index, List<ValueType> types) {
    return fromValue(types, args[index]);
  }
}
