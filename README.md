# HybridgeDart
支持 dart 与其他开发语言相互调用的工具

通过 BasicMessageChannel 与 native （Android、iOS）通讯，可以实现 flutter 与 native 之间的相互调用。

举例，在 dart 中有 ExampleObject 这样一个类 (example.dart)
```dart
class ExampleObject {
  int x = 0;

  int inc() {
    return x++;
  }

  int add(int d) {
    return x += d;
  }
}
```
如果想被 native 使用，只要简单完成下列几步就 OK 了。
## 声明导出该类
```dart
part 'example.g.dart';

@Export()
class ExampleObject {
  ...
}
```
## 配置构建依赖，自动生成导出相关的代码
```
dev_dependencies:
  hybridge_generator: 1.0.0
  build_runner: ^1.4.0
```
## 在 Channel 中注册对象
```dart
  MetaObject.add(ExampleObject, ExampleObjectMetaObject());
  Channel cp = Channel();
  cp.registerObject("test", ExampleObject());
  cp.connectTo(FlutterTransport("com.test.transport"));
```
## 在 Native 端访问 dart 对象
  使用各平台自己的 Hybridge 库，通过相同名称的 FlutterTransport 来访问该 Channel 中的对象。
