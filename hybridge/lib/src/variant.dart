import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'hybridge.dart';

class CHeader extends Struct {
  @IntPtr()
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
    var h = Hybridge.allocBuffer2<CHeader>();
    h.magic = MAGIC;
    h.size = string.length + 1;
    h.block = Utf8.toUtf8(string).cast();
  }
}

class CArrayEntry extends Struct {
  @IntPtr()
  int type;
  Pointer<Void> value;
}

class CArray {
  static int MAGIC = 0x525241; // LITTLE ENDIAN

  static List<Pointer<Void>> fromValue(Pointer<Void> value, VaueType type) {
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

  static Pointer<Void> toValue(List<Pointer<Void>> list, VaueType type) {
    var h = Hybridge.allocBuffer2<CHeader>();
    h.magic = MAGIC;
    h.size = sizeOf<CArrayEntry>() * list.length;
    h.block = Hybridge.allocBuffer(h.size);
    Pointer<CArrayEntry> array = h.block.cast();
    for (int i = 0; i < list.length; ++i) {
      CArrayEntry e = array.elementAt(i).ref;
      e.type = type.index;
      e.value = list.elementAt(i);
    }
  }
}

extension VariantList on List<Pointer<Void>> {
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
}

class CMapEntry extends Struct {
  Pointer<Void> key; // String
  @IntPtr()
  int type;
  Pointer<Void> value;
}

class CMap {
  static int MAGIC = 0x50414d; // LITTLE ENDIAN

  static Map<String, Pointer<Void>> fromValue(
      Pointer<Void> value, VaueType type) {
    var h = value.cast<CHeader>().ref;
    assert(h.magic == MAGIC);
    Pointer<CMapEntry> array = h.block.cast();
    int n = (h.size / sizeOf<CArrayEntry>()).floor();
    var map = Map<String, Pointer<Void>>();
    for (int i = 0; i < n; ++i) {
      CMapEntry e = array.elementAt(i).ref;
      assert(e.type == type.index);
      map[CString.fromValue(e.key)] = e.value;
    }
    return map;
  }

  static Pointer<Void> toValue(Map<String, Pointer<Void>> map, VaueType type) {
    var h = Hybridge.allocBuffer2<CHeader>();
    h.magic = MAGIC;
    h.size = sizeOf<CMapEntry>() * map.length;
    h.block = Hybridge.allocBuffer(h.size);
    Pointer<CMapEntry> array = h.block.cast();
    for (int i = 0; i < map.length; ++i) {
      CMapEntry e = array.elementAt(i).ref;
      e.key = CString.toValue(map.keys.elementAt(i));
      e.type = type.index;
      e.value = map.values.elementAt(i);
    }
  }
}

extension VariantMap on Map<String, Pointer<Void>> {
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

  Map<String, String> objectMap() {
    return map((k, v) => MapEntry(k, Hybridge.));
  }
}
