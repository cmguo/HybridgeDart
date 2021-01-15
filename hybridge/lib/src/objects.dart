import 'dart:ffi';

import 'handleptr.dart';

class ObjectCallbackStub extends Struct {
  static final instance = ObjectCallbackStub();
}

class Objects extends Struct {
  static final Map<Pointer<Handle>, Object> handleObjects = Map();
  static final Map<Object, Handle> objectHandles = Map();

  static Pointer<Handle> get(Object object) {
    if (objectHandles.containsKey(object)) {
      return objectHandles[object].addressOf;
    }
    final handle = Handle.fromCallback(ObjectCallbackStub.instance);
    objectHandles[object] = handle;
    handleObjects[handle.addressOf] = object;
    return handle.addressOf;
  }

  static Object find(Pointer<Handle> handle) {
    return objectHandles[handle];
  }

  static void release(Handle handle) {
    handleObjects.remove(handle.addressOf);
  }
}
