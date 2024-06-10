// ignore_for_file: camel_case_types, constant_identifier_names, file_names, non_constant_identifier_names

import 'MyLogger.dart';

class MyStream_c<T> {
  int _useId = 1;
  final List<MyStreamListener_c<T>> _listeners;
  T _value;

  T get value => _value;
  set value(in_value) => notify(in_value);

  final bool checkModify;

  /// * [value] 初始值
  /// * [listeners]
  MyStream_c({
    required T value,
    this.checkModify = false,
    List<MyStreamListener_c<T>>? listeners,
  })  : _value = value,
        _listeners = listeners ?? <MyStreamListener_c<T>>[];

  MyStream_c.listener({
    required T value,
    this.checkModify = false,
    List<MyStreamListener_c<T>>? listeners,
    List<void Function(T data, bool? hasModify)>? onActiveFunList,
  })  : _value = value,
        _listeners = listeners ?? <MyStreamListener_c<T>>[] {
    if (null != onActiveFunList) {
      // 创建监听器
      for (final item in onActiveFunList) {
        addListener(item);
      }
    }
  }

  MyStreamListener_c<T> addListener(
    void Function(T value, bool? hasModify) onActive, {
    bool Function(T oldData, T newData)? hasModify,
    bool onlyNotifyWhenModify = true,
  }) {
    final item = MyStreamListener_c<T>(
      id: _useId++,
      onActive: onActive,
      hasModify: hasModify,
      onlyNotifyWhenModify: onlyNotifyWhenModify,
      stream: this,
    );
    _listeners.add(item);
    return item;
  }

  bool removeListener(MyStreamListener_c? item) {
    if (null == item) {
      return false;
    }
    for (int i = 0; i < _listeners.length; ++i) {
      final nowId = _listeners[i].id;
      if (nowId == item.id) {
        _listeners.removeAt(i);
        return true;
      } else if (nowId > item.id) {
        return false;
      }
    }
    return false;
  }

  /// 写入新值，发送通知
  /// * [in_modify] 强制指定是否发生了改变
  void notify(
    T in_value, {
    final bool? in_modify,
  }) {
    late final bool? f_modify;
    if (null != in_modify) {
      f_modify = in_modify;
    } else if (checkModify) {
      f_modify = (_value != in_value);
    } else {
      f_modify = null;
    }
    final oldValue = _value;
    _value = in_value;
    for (int i = 0; i < _listeners.length; ++i) {
      final item = _listeners[i];
      late final itemNotify =
          in_modify ?? item.hasModify?.call(oldValue, _value) ?? f_modify;
      if (false == itemNotify && item.onlyNotifyWhenModify) {
        // 未改变，且[item]要求仅当改变时通知，则跳过
        continue;
      }
      try {
        item.onActive(
          _value,
          itemNotify,
        );
      } catch (e) {
        MyLogger.to().severe(MyLogItem(
          prefix: "MyStream.notify Error",
          msg: [e.toString()],
        ));
      }
    }
  }

  /// 发送通知，但值仍为本身
  void reflush() {
    for (int i = 0; i < _listeners.length; ++i) {
      final item = _listeners[i];
      try {
        item.onActive(
          _value,
          false,
        );
      } catch (e) {
        MyLogger.to().severe(MyLogItem(
          prefix: "MyStream.notify Error",
          msg: [e.toString()],
        ));
      }
    }
  }
}

class MyStreamListener_c<T> {
  final int id;
  final void Function(T data, bool? hasModify) onActive;
  final bool Function(T oldData, T newData)? hasModify;

  /// 指定仅当状态改变时才通知
  /// * 这需要同时指定[MyStream_c.checkModify]或给定[hasModify]
  final bool onlyNotifyWhenModify;
  MyStream_c? stream;

  MyStreamListener_c({
    required this.id,
    required this.onActive,
    required this.hasModify,
    required this.onlyNotifyWhenModify,
    required this.stream,
  });

  static bool defHasModify(dynamic oldData, dynamic newData) {
    return (oldData != newData);
  }

  /// 监听器是否可用
  bool isActive() {
    return (null != stream);
  }

  /// 移除监听器
  /// * [null]不需要移除
  /// * [true]移除成功
  /// * [false]移除失败
  bool? dispose() {
    return stream?.removeListener(this);
  }
}
