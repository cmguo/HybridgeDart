import 'package:source_gen_test/annotations.dart';
import 'package:hybridge/hybridge.dart';

@ShouldGenerate(r'''
class EmptyObjectMetaObject extends MetaObject {
  EmptyObjectMetaObject()
      : super({"class": "EmptyObject", "properties": [], "methods": []});
}
''', contains: true)
@Export()
class EmptyObject {}

@ShouldGenerate(r'''
class RenameEmptyObjectMetaObject extends MetaObject {
  RenameEmptyObjectMetaObject()
      : super({"class": "xxx", "properties": [], "methods": []});
}
''', contains: true)
@Export(className: "xxx")
class RenameEmptyObject {}

@ShouldGenerate(
  r'''
      : super({
          "class": "PropertyObject",
          "properties": [
            ["x", 1, 3, 0, -1]
          ],
          "methods": []
        });
''',
  contains: true,
)
@Export()
class PropertyObject {
  int x;
}

@ShouldGenerate(
  r'''
  @override
  dynamic readProperty(Object object, int propertyIndex) {
    PropertyObject2 o = object;
    if (propertyIndex == 0) {
      return o.x;
    }
    return null;
  }

  @override
  bool writeProperty(Object object, int propertyIndex, dynamic value) {
    PropertyObject2 o = object;
    if (propertyIndex == 0) {
      o.x = value;
      return true;
    }
    return false;
  }''',
  contains: true,
)
@Export()
class PropertyObject2 {
  int x;
}

@ShouldGenerate(
  r'''
      : super({
          "class": "RenamePropertyObject",
          "properties": [
            ["xxx", 1, 3, 0, -1]
          ],
          "methods": []
        });
''',
  contains: true,
)
@Export()
class RenamePropertyObject {
  @Name("xxx")
  int x;
}

@ShouldGenerate(
  r'''
  @override
  dynamic readProperty(Object object, int propertyIndex) {
    RenamePropertyObject2 o = object;
    if (propertyIndex == 0) {
      return o.x;
    }
    return null;
  }
''',
  contains: true,
)
@Export()
class RenamePropertyObject2 {
  @Name("xxx")
  int x;
}

@ShouldGenerate(
  r'''
      : super({
          "class": "PropertyTypeObject",
          "properties": [
            ["xxx", 1, 2, 0, -1]
          ],
          "methods": []
        });
''',
  contains: true,
)
@Export()
class PropertyTypeObject {
  @Name("xxx")
  @VType(ValueType.Int)
  int x;
}

@ShouldGenerate(
  r'''
      : super({
          "class": "MethodObject",
          "properties": [],
          "methods": [
            ["x", 1, 0, "", 3, [], []]
          ]
        });
''',
  contains: true,
)
@Export()
class MethodObject {
  int x() {
    return 0;
  }
}

@ShouldGenerate(
  r'''
  @override
  dynamic invokeMethod(Object object, int methodIndex, List<dynamic> args) {
    MethodObject2 o = object;
    if (methodIndex == 0) {
      return o.x();
    }
    return null;
  }
''',
  contains: true,
)
@Export()
class MethodObject2 {
  int x() {
    return 0;
  }
}

@ShouldGenerate(
  r'''
      : super({
          "class": "MethodArgsObject",
          "properties": [],
          "methods": [
            [
              "x",
              1,
              0,
              "",
              3,
              [3, 3],
              ["a", "b"]
            ]
          ]
        });
''',
  contains: true,
)
@Export()
class MethodArgsObject {
  int x(int a, int b) {
    return 0;
  }
}

@ShouldGenerate(
  r'''
  @override
  dynamic invokeMethod(Object object, int methodIndex, List<dynamic> args) {
    MethodArgsObject2 o = object;
    if (methodIndex == 0) {
      return o.x(args[0], args[1]);
    }
    return null;
  }
''',
  contains: true,
)
@Export()
class MethodArgsObject2 {
  int x(int a, int b) {
    return 0;
  }
}
