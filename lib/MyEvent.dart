// ignore_for_file: file_names, non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:my_util_base/MyUtil.dart';
import 'MyLogger.dart';
import 'MyStream.dart';

abstract class MyEventBase_c<T> {
  void notify(T in_value);
  @Deprecated(
    "需要实现该函数，但不要直接调用，应当调用[_onListenRun]，由[_onListenRun]来调用[_onListenBind]",
  )
  void _onListenBind(T in_value);
  void _onListenRun(T in_value) {
    try {
      // ignore: deprecated_member_use_from_same_package
      _onListenBind(in_value);
    } catch (e) {
      MyLogger.to().severe(MyLogItem(
        prefix: "MyEvent.run Error",
        msg: [e.toString()],
      ));
    }
  }
}

class MyEventControl_c {
  /// * 检查[future]的执行是否超时
  /// 该函数只会在[future]完成后才会调用[onDone]并返回结果
  /// * 注意，部分阻塞会导致[startTime]和[endTime]在[future]一段时间后返回后仍然相等，
  /// 导致[isTimeOut]永远为[false]。例如win端调用系统选择文件夹路径接口
  static Future<T?> checkTimeOut<T>(
    Future<T> future,
    Duration duration, {
    FutureOr<T?> Function(T value, bool isTimeOut)? onDone,
  }) async {
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final value = await future;
    if (null == onDone) {
      return value;
    }
    final endTime = DateTime.now().millisecondsSinceEpoch;
    return onDone.call(
      value,
      // 时间差大于限定值
      (endTime - startTime) >= duration.inMilliseconds,
    );
  }
}

class MyEventDebounce_c<T> extends MyEventBase_c<T> {
  late T _value;

  T get value => _value;
  set value(in_value) => notify(in_value);

  Timer? _timer;

  /// 间隔时间
  final Duration time;
  final bool fastFirstRun;

  /// 执行
  final void Function(T val) onListen;

  /// ## 防抖
  /// * 限制在 [time] 时间内没有新收到新数据后触发执行一次 [onListen]
  MyEventDebounce_c({
    required this.time,
    required this.onListen,
    this.fastFirstRun = false,
  });

  MyEventDebounce_c.fromMyStream({
    required MyStream_c<T> stream,
    required this.time,
    required this.onListen,
    this.fastFirstRun = false,
  }) {
    stream.addListener((value, _) {
      notify(value);
    });
  }

  @override
  void notify(T in_value) {
    _value = in_value;
    if (fastFirstRun) {
      // 马上触发
      if (null == _timer) {
        _onListenRun(_value);
        _timer = Timer(time, () {
          _onListenRun(_value);
          _timer = null;
        });
      }
    } else {
      _timer?.cancel();
      _timer = Timer(time, () {
        _onListenRun(_value);
        _timer = null;
      });
    }
  }

  @override
  void _onListenBind(T in_value) {
    onListen.call(in_value);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }
}

class MyEventDebounceThrottle_c<T> extends MyEventThrottle_c<T> {
  late final MyEventDebounce_c<T> debounce;

  /// ## 节流版防抖
  /// * 当[debounceTime]时间内没有新通知[notify]后，才会触发[onListen]
  /// * 并且限制调用[notify]的频率在[time]时间内只会触发一次
  MyEventDebounceThrottle_c({
    required Duration debounceTime,
    required super.time,
    required super.onListen,
    required void Function(T) onDebounceListen,
    super.fastFirstRun = true,
  }) {
    debounce = MyEventDebounce_c(
      fastFirstRun: false,
      time: debounceTime,
      onListen: onDebounceListen,
    );
  }

  @override
  void _onListenBind(T in_value) {
    onListen?.call(in_value);
    debounce.notify(in_value);
  }
}

class MyEventThrottle_c<T> extends MyEventBase_c<T> {
  bool _hasValue = false;
  late T _value;

  Timer? _timer;

  /// 间隔时间
  final Duration time;

  /// 执行
  final void Function(T val)? onListen;

  /// 当未限流时得到通知是否马上触发[onListen]
  final bool fastFirstRun;

  /// 是否在启用[fastFirstRun]后，保留最后一个[_value]在限制结束后触发
  final bool dofastFirstRunEnd;

  /// ## 节流
  /// * 限制在 [time] 时间内只执行一次 [onListen]。
  /// * 默认情况下会等待限制期后取最后一次通知的[_value]触发一次[onListen]，之前的[_value]
  /// 都将被丢弃。
  /// * [fastFirstRun] 若为[true]，当未限流时得到通知马上触发[onListen], 之后限制期间的[_value]都会
  /// 被丢弃；若启用[dofastFirstRunEnd]，则保留最后一个[_value]在限制结束时触发[onListen]，而后再次进入限流。
  MyEventThrottle_c({
    required this.time,
    required this.onListen,
    this.fastFirstRun = false,
    this.dofastFirstRunEnd = true,
  });

  void clear({
    required bool doOnListen,
    required T value,
  }) {
    if (doOnListen) {
      _onListenRun(value);
    }
    _hasValue = false;
    _timer?.cancel();
    _timer = null;
  }

  /// 通知值
  /// * 返回是否触发执行
  @override
  bool notify(T in_value) {
    _value = in_value;
    _hasValue = true;
    if (fastFirstRun) {
      // 马上触发
      if (null == _timer) {
        _timer = Timer(time, () {
          _timer = null;
          if (dofastFirstRunEnd && _hasValue) {
            notify(_value);
          }
        });
        _onListenRun(_value);
        _hasValue = false;
        return true;
      }
    } else {
      bool rebool = (null == _timer);
      _timer ??= Timer(time, () {
        _timer = null;
        _onListenRun(_value);
        _hasValue = false;
      });
      return rebool;
    }
    return false;
  }

  @override
  void _onListenBind(T in_value) {
    onListen?.call(in_value);
  }
}

class MyEventRepeat_c {
  /// 通知一次后的记录时长
  final Duration duration;
  final int repeatLimitNum;
  final Future<void> Function() onListen;

  /// 标记是否正在执行
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// 记录当前时间段内通知次数
  int repeatNum = 0;

  /// 是否已经进入时间段
  Timer? timer;

  /// ## 重复时触发
  /// * 仅当一段时间[duration]内重复通知多次达到[repeatLimitNum]时才会触发执行[onListen]
  MyEventRepeat_c({
    this.repeatLimitNum = 2,
    required this.duration,
    required this.onListen,
  });

  /// 返回是否触发执行
  Future<bool> notify() async {
    ++repeatNum;
    timer?.cancel();
    if (false == _isRunning && repeatNum >= repeatLimitNum) {
      // 如果没有正在执行，且限制次数满足，则触发执行
      _isRunning = true;
      await onListen.call();
      repeatNum = 0;
      _isRunning = false;
      return true;
    } else {
      timer = Timer(duration, () {
        repeatNum = 0;
      });
      return false;
    }
  }
}

class MyEventOnce_c {
  final void Function()? onListen;

  /// 记录是否执行过
  bool _hasRun = false;

  bool get hasRun => _hasRun;

  /// 只会执行一次[onListen]
  MyEventOnce_c({
    required this.onListen,
  });

  /// 通知
  /// * 返回是否允许执行
  bool notify() {
    if (_hasRun) {
      // 已经执行过
      return false;
    } else {
      // 未执行过
      _hasRun = true;
      onListen?.call();
      return true;
    }
  }
}

class MyEventLine_c<T> {
  final list = Queue<T>();

  /// 当任务来临时执行的操作
  /// * 返回值 <bool>
  ///   * [true]，执行完当前函数后清空事件 [list]
  ///   * [false]，执行完后只清理被用于执行的值 [list.first]
  final Future<bool> Function(T value) onListen;

  /// 标记是否正在执行
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// ## 线性任务队列
  MyEventLine_c({
    required this.onListen,
  });

  Future<bool> onRunEvent() async {
    if (_isRunning) {
      return false;
    }
    _isRunning = true;
    try {
      while (list.isNotEmpty) {
        final rebool = await onListen.call(list.first);
        if (rebool) {
          // 清空
          list.clear();
        } else {
          // 移除一个
          list.removeFirst();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
    _isRunning = false;
    return true;
  }

  /// 返回是否触发执行
  Future<bool> notify(T val) {
    list.add(val);
    return onRunEvent();
  }
}

class MyEventQueueItem_c<T, T1> {
  final T1? value;
  final Future<T?> Function(T1? value) fun;
  final Completer<T?> result = Completer<T?>();

  MyEventQueueItem_c({
    this.value,
    required this.fun,
  });
}

class MyEventQueue_c<T, T1> {
  final list = Queue<MyEventQueueItem_c<T, T1>>();

  /// 标记是否正在执行
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// ## 线性任务队列
  /// * 用于控制异步函数不会并发执行
  MyEventQueue_c();

  void completeWhere(
      bool Function(MyEventQueueItem_c<T, T1> item, MyObj_c<T?> result) fun) {
    list.removeWhere((item) {
      final result = MyObj_c<T?>(null);
      final doComplete = fun.call(item, result);
      if (doComplete) {
        item.result.complete(result.value);
        return true;
      }
      return false;
    });
  }

  Future<void> onRunEvent() async {
    if (_isRunning) {
      return;
    }
    list.removeWhere((element) => false);
    _isRunning = true;
    while (list.isNotEmpty) {
      final item = list.first;
      try {
        final reData = await item.fun.call(item.value);
        if (false == item.result.isCompleted) {
          item.result.complete(reData);
        }
      } catch (e) {
        item.result.complete(null);
        if (kDebugMode) {
          print(e);
        }
      }
      // 移除一个
      list.remove(item);
    }
    _isRunning = false;
    return;
  }

  /// 返回触发执行后的结果
  Future<T?> notify(MyEventQueueItem_c<T, T1> item) {
    list.add(item);
    onRunEvent();
    return item.result.future;
  }
}

class MyEventAvailable_c<ValueType, CheckType> {}
