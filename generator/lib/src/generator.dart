import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';
import 'package:source_gen/source_gen.dart';

import 'package:hybridge/hybridge.dart' as hybirdge;

class HybridgeOptions {
  final bool autoCastResponse;

  HybridgeOptions({this.autoCastResponse});

  HybridgeOptions.fromOptions([BuilderOptions options])
      : autoCastResponse =
            (options?.config['auto_cast_response']?.toString() ?? 'true') ==
                'true';
}

abstract class HybridgeGenerator<T> extends GeneratorForAnnotation<T> {
  TypeChecker _typeChecker(Type type) => TypeChecker.fromRuntime(type);

  hybirdge.ValueType _valueType(DartType type) {
    if (type.isDartCoreBool) return hybirdge.ValueType.Bool;
    if (type.isDartCoreInt) return hybirdge.ValueType.Long;
    if (type.isDartCoreDouble) return hybirdge.ValueType.Double;
    if (type.isDartCoreString) return hybirdge.ValueType.String;
    if (type.isDartCoreList) return hybirdge.ValueType.Array_;
    if (type.isDartCoreMap) return hybirdge.ValueType.Map_;
    return hybirdge.ValueType.Object_;
  }

  bool _isIgnore(Element member) {
    final annot = _typeChecker(hybirdge.Ignore)
        .firstAnnotationOf(member, throwOnUnresolved: false);
    return annot != null;
  }

  String _name(Element element) {
    final annot = _typeChecker(hybirdge.Name)
        .firstAnnotationOf(element, throwOnUnresolved: false);
    return annot == null
        ? element.name
        : ConstantReader(annot).peek("value").stringValue;
  }

  int _fieldType(FieldElement field) {
    final annot = _typeChecker(hybirdge.VType)
        .firstAnnotationOf(field, throwOnUnresolved: false);
    if (annot == null) return _valueType(field.type).index;
    return ConstantReader(annot)
        .peek("value")
        .objectValue
        .getField("index")
        .toIntValue();
  }

  int _methodReturnType(MethodElement method) {
    final annot = _typeChecker(hybirdge.VType)
        .firstAnnotationOf(method, throwOnUnresolved: false);
    if (annot == null) return _valueType(method.type.returnType).index;
    return (ConstantReader(annot).peek("value").objectValue
            as hybirdge.ValueType)
        .index;
  }

  List<int> _methodParameterTypes(MethodElement method) =>
      method.type.parameters.map((p) => _parameterType(p)).toList();

  int _parameterType(ParameterElement parameter) {
    final annot = _typeChecker(hybirdge.VType)
        .firstAnnotationOf(parameter, throwOnUnresolved: false);
    if (annot == null) return _valueType(parameter.type).index;
    return (ConstantReader(annot).peek("value").objectValue
            as hybirdge.ValueType)
        .index;
  }

  List<String> _methodParameterNames(MethodElement method) =>
      method.type.parameters.map((p) => _name(p)).toList();

  String _displayString(dynamic e) {
    try {
      return e.getDisplayString(withNullability: false);
    } catch (error) {
      if (error is TypeError) {
        return e.getDisplayString();
      } else {
        rethrow;
      }
    }
  }
}

class HybridgeExportGenerator extends HybridgeGenerator<hybirdge.Export> {
  /// Global options sepcefied in the `build.yaml`
  final HybridgeOptions globalOptions;

  HybridgeExportGenerator(this.globalOptions);

  String _className;
  Map<String, List<dynamic>> _properties;
  Map<String, List<dynamic>> _methods;

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      final name = element.displayName;
      throw InvalidGenerationSourceError(
        'Generator cannot target `$name`.',
        todo: 'Remove the [Export] annotation from `$name`.',
      );
    }
    return _implementClass(element, annotation);
  }

  String _implementClass(ClassElement element, ConstantReader annotation) {
    _className = element.name;
    final className =
        annotation?.peek('className')?.stringValue ?? element.name;
    _properties = _parseFileds(element);
    _methods = _parseMethods(element);
    var meta = {
      "class": className,
      "properties": _properties.values.toList(),
      "methods": _methods.values.toList()
    };
    final classBuilder = Class((c) {
      c
        ..name = '${_className}MetaObject'
        ..types.addAll(element.typeParameters.map((e) => refer(e.name)))
        ..extend = Reference("MetaObject");

      c.constructors.add(_generateConstructor(jsonEncode(meta)));

      if (!_properties.isEmpty) {
        c.methods.add(_generateReadPropertyMethod(_properties));
        c.methods.add(_generateWritePropertyMethod(_properties));
      }

      if (!_methods.isEmpty) {
        c.methods.add(_generateInvokeMethodMethod(_methods));
      }
    });
    final emitter = DartEmitter();
    return DartFormatter().format('${classBuilder.accept(emitter)}');
  }

  Map<String, List<dynamic>> _parseFileds(ClassElement element) =>
      Map.fromEntries(element.fields
          .where((f) =>
              !_isIgnore(f) && f.isPublic && !f.isAbstract && !f.isStatic)
          .mapWithIndex((i, f) => MapEntry(
              f.name, [_name(f), f.isConst ? 3 : 1, _fieldType(f), i, -1])));

  Map<String, List<dynamic>> _parseMethods(ClassElement element) =>
      Map.fromEntries(element.methods
          .where((m) =>
              !_isIgnore(m) && m.isPublic && !m.isAbstract && !m.isStatic)
          .mapWithIndex((i, m) => MapEntry(m.name, [
                _name(m),
                1,
                i,
                "",
                _methodReturnType(m),
                _methodParameterTypes(m),
                _methodParameterNames(m)
              ])));

  Constructor _generateConstructor(String meta) => Constructor((c) {
        c.initializers.add(Code("super('${meta}')"));
      });

  Method _generateReadPropertyMethod(Map<String, List<dynamic>> fields) =>
      Method((m) {
        m
          ..returns = refer("dynamic")
          ..name = "readProperty"
          ..annotations.add(CodeExpression(Code('override')))
          ..requiredParameters.add(Parameter((p) {
            p.name = "object";
            p.type = refer("Object");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "propertyIndex";
            p.type = refer("int");
          }))
          ..body = _generateReadPropertyBody(fields);
      });

  Code _generateReadPropertyBody(Map<String, List<dynamic>> fields) {
    final blocks = <Code>[];
    blocks.add(Code("${_className} o = object;"));
    fields.forEach((n, f) {
      blocks.add(Code("if (propertyIndex == ${f[3]}) { return o.${n}; }"));
    });
    blocks.add(Code("return null;"));
    return Block.of(blocks);
  }

  Method _generateWritePropertyMethod(Map<String, List<dynamic>> fields) =>
      Method((m) {
        m
          ..returns = refer("bool")
          ..name = "writeProperty"
          ..annotations.add(CodeExpression(Code('override')))
          ..requiredParameters.add(Parameter((p) {
            p.name = "object";
            p.type = refer("Object");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "propertyIndex";
            p.type = refer("int");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "value";
            p.type = refer("dynamic");
          }))
          ..body = _generateWritePropertyBody(fields);
      });

  Code _generateWritePropertyBody(Map<String, List<dynamic>> fields) {
    final blocks = <Code>[];
    blocks.add(Code("${_className} o = object;"));
    fields.forEach((n, f) {
      blocks.add(Code(
          "if (propertyIndex == ${f[3]}) { o.${n} = value; return true; }"));
    });
    blocks.add(Code("return false;"));
    return Block.of(blocks);
  }

  Method _generateInvokeMethodMethod(Map<String, List<dynamic>> methods) =>
      Method((m) {
        m
          ..returns = refer("dynamic")
          ..name = "invokeMethod"
          ..annotations.add(CodeExpression(Code('override')))
          ..requiredParameters.add(Parameter((p) {
            p.name = "object";
            p.type = refer("Object");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "methodIndex";
            p.type = refer("int");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "args";
            p.type = refer("List<dynamic>");
          }))
          ..body = _generateInvokeMethodBody(methods);
      });

  Code _generateInvokeMethodBody(Map<String, List<dynamic>> methods) {
    final blocks = <Code>[];
    blocks.add(Code("${_className} o = object;"));
    methods.forEach((n, m) {
      String args =
          (m[5] as List<int>).mapWithIndex((i, a) => "args[${i}]").join(", ");
      blocks.add(
          Code("if (propertyIndex == ${m[2]}) { return o.${n}(${args}); }"));
    });
    blocks.add(Code("return null;"));
    return Block.of(blocks);
  }
}

class HybridgeImportGenerator extends HybridgeGenerator<hybirdge.Import> {
  /// Global options sepcefied in the `build.yaml`
  final HybridgeOptions globalOptions;

  HybridgeImportGenerator(this.globalOptions);

  @override
  String generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement) {
      final name = element.displayName;
      throw InvalidGenerationSourceError(
        'Generator cannot target `$name`.',
        todo: 'Remove the [Export] annotation from `$name`.',
      );
    }
    return _implementClass(element, annotation);
  }

  String _implementClass(ClassElement element, ConstantReader annotation) {
    final _className = element.name;
    final className = annotation?.peek('className')?.stringValue ?? _className;
    final classBuilder = Class((c) {
      c
        ..name = '${_className}Proxy'
        ..types.addAll(element.typeParameters.map((e) => refer(e.name)))
        ..extend = Reference(_className);

      c.fields.add(Field((f) {
        f.type = Reference("ProxyObject");
        f.name = "proxy";
      }));

      c.constructors.add(_generateConstructor());

      element.methods
          .where(
              (m) => !_isIgnore(m) && m.isPublic && m.isAbstract && !m.isStatic)
          .forEach((m) {
        c.methods.add(_generateProxyMethod(m));
      });
    });

    final emitter = DartEmitter();
    return DartFormatter().format('${classBuilder.accept(emitter)}');
  }

  Constructor _generateConstructor() => Constructor((c) {
        c.requiredParameters.add(Parameter((p) {
          p.toThis = true;
          p.name = "proxy";
        }));
      });

  Method _generateReadPropertyMethod(Map<String, List<dynamic>> fields) =>
      Method((m) {
        m
          ..returns = refer("dynamic")
          ..name = "readProperty"
          ..annotations.add(CodeExpression(Code('override')))
          ..requiredParameters.add(Parameter((p) {
            p.name = "object";
            p.type = refer("Object");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "propertyIndex";
            p.type = refer("int");
          }))
          ..body = _generateReadPropertyBody(fields);
      });

  Code _generateReadPropertyBody(Map<String, List<dynamic>> fields) {
    final blocks = <Code>[];
    fields.forEach((n, f) {
      blocks.add(Code("if (propertyIndex == ${f[3]}) { return o.${n}; }"));
    });
    blocks.add(Code("return null;"));
    return Block.of(blocks);
  }

  Method _generateWritePropertyMethod(Map<String, List<dynamic>> fields) =>
      Method((m) {
        m
          ..returns = refer("bool")
          ..name = "writeProperty"
          ..annotations.add(CodeExpression(Code('override')))
          ..requiredParameters.add(Parameter((p) {
            p.name = "object";
            p.type = refer("Object");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "propertyIndex";
            p.type = refer("int");
          }))
          ..requiredParameters.add(Parameter((p) {
            p.name = "value";
            p.type = refer("dynamic");
          }))
          ..body = _generateWritePropertyBody(fields);
      });

  Code _generateWritePropertyBody(Map<String, List<dynamic>> fields) {
    final blocks = <Code>[];
    fields.forEach((n, f) {
      blocks.add(Code(
          "if (propertyIndex == ${f[3]}) { o.${n} = value; return true; }"));
    });
    blocks.add(Code("return false;"));
    return Block.of(blocks);
  }

  Method _generateProxyMethod(MethodElement method) => Method((m) {
        m
          ..returns = refer(_displayString(method.type.returnType))
          ..name = method.name
          ..annotations.add(CodeExpression(Code('override')))
          ..requiredParameters
              .addAll(method.type.parameters.map((p) => Parameter((p2) {
                    p2.name = p.name;
                    p2.type = refer(_displayString(p.type));
                  })))
          ..body = _generateProxyMethodBody(method);
      });

  Code _generateProxyMethodBody(MethodElement method) {
    final blocks = <Code>[];
    String name = _name(method);
    String args = method.type.parameters.map((p) => p.name).join(", ");
    blocks.add(Code('return proxy.invokeMethod("${name}", [${args}]);'));
    return Block.of(blocks);
  }
}

Builder generatorFactoryBuilder(BuilderOptions options) => SharedPartBuilder([
      HybridgeExportGenerator(HybridgeOptions.fromOptions(options)),
      HybridgeImportGenerator(HybridgeOptions.fromOptions(options))
    ], "hybridge");
