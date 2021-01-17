import 'dart:ffi';

import 'hybridge.dart';

class Handle extends Struct {
  Pointer<Void> callback;

  Handle(Pointer<Void> c) {
    callback = c;
  }

  static Handle fromCallback<C extends Struct>(C callback) {
    Handle h = Hybridge.alloc<Handle>();
    h.callback = callback.addressOf.cast();
    return h;
  }
}

class HandleSet<T, C extends Struct> {
  final Map<Pointer<Handle>, T> objects = Map();
  final Map<T, Handle> handles = Map();
  final C callback;

  HandleSet(this.callback);

  Handle alloc(T object) {
    if (handles.containsKey(object)) {
      return handles[object];
    }
    final handle = Handle.fromCallback(callback);
    objects[handle.addressOf] = object;
    handles[object] = handle;
    return handle;
  }

  void free(Handle handle) {
    handles.remove(objects.remove(callback.addressOf));
  }

  T operator [](Pointer<Handle> handle) {
    return objects[handle];
  }
}
