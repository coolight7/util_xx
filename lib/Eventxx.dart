// ignore_for_file: file_names, non_constant_identifier_names, camel_case_types, constant_identifier_names

import 'dart:async';
import 'dart:collection';
import 'package:util_xx/Platformxx.dart';

import 'Loggerxx.dart';
import 'Streamxx.dart';

abstract class EventxxBase_c<T> {
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
      Loggerxx.to().severe(LogxxItem(
        prefix: "MyEvent.run Error",
        msg: [e.toString()],
      ));
    }
  }
}

class EventxxControl_c {
  /// - 检查[future]的执行是否超时
  /// 该函数只会在[future]完成后才会调用[onDone]并返回结果
  /// - 注意，部分阻塞会导致[startTime]和[endTime]在[future]一段时间后返回后仍然相等，
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

class EventxxDebounce_c<T> extends EventxxBase_c<T> {
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
  /// - 限制在 [time] 时间内没有新收到新数据后触发执行一次 [onListen]
  EventxxDebounce_c({
    required this.time,
    required this.onListen,
    this.fastFirstRun = false,
  });

  EventxxDebounce_c.fromMyStream({
    required Streamxx_c<T> stream,
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

class EventxxDebounceThrottle_c<T> extends EventxxThrottle_c<T> {
  late final EventxxDebounce_c<T> debounce;

  /// ## 节流版防抖
  /// - [onListen] 限制频率，在[time]时间内只会触发一次
  /// - [onDebounceListen] 当[debounceTime]时间内没有新通知[notify]后，才会触发
  EventxxDebounceThrottle_c({
    required Duration debounceTime,
    required super.time,
    required super.onListen,
    required void Function(T) onDebounceListen,
    super.fastFirstRun = true,
  }) {
    debounce = EventxxDebounce_c(
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

class EventxxThrottle_c<T> extends EventxxBase_c<T> {
  bool _hasValue = false;
  late T _value;

  T get value => _value;

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
  /// - 限制在 [time] 时间内只执行一次 [onListen]。
  /// - 默认情况下会等待限制期后取最后一次通知的[_value]触发一次[onListen]，之前的[_value]
  ///   都将被丢弃。
  /// - [fastFirstRun] 若为[true]，当未限流时得到通知马上触发[onListen], 之后限制期间的[_value]都会
  ///   被丢弃；若启用[dofastFirstRunEnd]，则保留最后一个[_value]在限制结束时触发[onListen]，而后再次进入限流。
  EventxxThrottle_c({
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

  /// ## 通知值
  /// - 返回是否触发执行
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

class EventxxRepeat_c {
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
  /// - 仅当一段时间[duration]内重复通知多次达到[repeatLimitNum]时才会触发执行[onListen]
  EventxxRepeat_c({
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

class EventxxOnce_c {
  final void Function()? onListen;

  /// 记录是否执行过
  bool _hasRun = false;

  bool get hasRun => _hasRun;

  /// 只会执行一次[onListen]
  EventxxOnce_c({
    required this.onListen,
  });

  /// 通知
  /// - 返回是否允许执行
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

class EventxxLine_c<T> {
  final list = Queue<T>();

  /// 当任务来临时执行的操作
  /// - 每次执行前，取出[list]第一个值作为[onListen]的参数
  /// - 返回值
  ///   - [true]，执行完当前函数后清空事件 [list]
  final Future<bool> Function(T value) onListen;
  final Duration? timeout;

  /// 标记是否正在执行
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// ## 线性任务队列
  EventxxLine_c({
    required this.onListen,
    this.timeout,
  });

  Future<bool> onRunEvent() async {
    if (_isRunning) {
      return false;
    }
    _isRunning = true;
    while (list.isNotEmpty) {
      try {
        // 移除一个
        final current = list.removeFirst();
        var rebool = onListen.call(current);
        if (null != timeout) {
          // 超时，移除当前
          rebool = rebool.timeout(timeout!, onTimeout: () => false);
        }
        if (await rebool) {
          // 清空
          list.clear();
        }
      } catch (e) {
        if (Platformxx_c.isDebugMode) {
          print(e);
        }
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

class EventxxQueueItem_c<T, T1> {
  final T1? value;
  final Future<T?> Function(T1? value) fun;
  final Completer<T?> result = Completer<T?>();

  EventxxQueueItem_c({
    this.value,
    required this.fun,
  });
}

class EventxxQueue_c<T, T1> {
  final list = Queue<EventxxQueueItem_c<T, T1>>();

  /// 标记是否正在执行
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// ## 线性任务队列
  /// * 用于控制异步函数不会并发执行
  EventxxQueue_c();

  void completeWhere((bool, T?) Function(EventxxQueueItem_c<T, T1> item) fun) {
    list.removeWhere((item) {
      final (doComplete, result) = fun.call(item);
      if (doComplete) {
        item.result.complete(result);
        return true;
      }
      return false;
    });
  }

  Future<T?> onRunItem(EventxxQueueItem_c<T, T1> item) async {
    try {
      final reData = await item.fun.call(item.value);
      if (false == item.result.isCompleted) {
        item.result.complete(reData);
      }
      return reData;
    } catch (e, stack) {
      item.result.complete(null);
      if (Platformxx_c.isDebugMode) {
        print(e);
        print(stack);
      }
    }
    return null;
  }

  Future<void> onRunEvent() async {
    if (_isRunning) {
      return;
    }
    list.removeWhere((element) => false);
    _isRunning = true;
    while (list.isNotEmpty) {
      final item = list.first;
      await onRunItem(item);
      // 移除一个
      list.remove(item);
    }
    _isRunning = false;
    return;
  }

  /// 返回触发执行后的结果
  Future<T?> notify(
    EventxxQueueItem_c<T, T1> item, {
    bool fastRun = false,
  }) {
    if (fastRun) {
      return onRunItem(item);
    }
    list.add(item);
    onRunEvent();
    return item.result.future;
  }
}

class EventxxAvailable_c<ValueType, CheckType> {}
