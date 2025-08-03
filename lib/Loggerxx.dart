// ignore_for_file: file_names, camel_case_types, constant_identifier_names

import 'dart:convert' as convert;
import 'package:logging/logging.dart';

import 'Platformxx.dart';

class Loggerxx {
  static final _instance = Loggerxx(className: "Global");

  final Logger _log;
  final String className;

  Loggerxx({
    required this.className,
  }) : _log = Logger(className);

  /// 获得全局通用单例
  static Loggerxx to() => _instance;

  /// * 如果希望输出日志，需要调用一次`MyLogger.enableDebugPrint()`
  /// * 当然也可以自己通过[listenLog]监听处理日志
  static void enableDebugPrint() {
    if (Platformxx_c.isDebugMode) {
      listenLog((item) {
        // ignore: avoid_print
        print(item.toString());
      });
    }
  }

  /// * 监听并自定义处理收到的日志
  /// * 多个不同的[Loggerxx]收集到的日志都会汇集于此
  static void listenLog(void Function(LogRecord)? onLog) {
    Logger.root.onRecord.listen(onLog);
  }

  void shout(LogxxItem msg) {
    _log.shout(convert.jsonEncode(msg));
  }

  void severe(LogxxItem msg) {
    _log.severe(convert.jsonEncode(msg));
  }

  void warning(LogxxItem msg) {
    _log.warning(convert.jsonEncode(msg));
  }

  void info(LogxxItem msg) {
    _log.info(convert.jsonEncode(msg));
  }

  void config(LogxxItem msg) {
    _log.config(convert.jsonEncode(msg));
  }

  void fine(LogxxItem msg) {
    _log.fine(convert.jsonEncode(msg));
  }

  void finer(LogxxItem msg) {
    _log.finer(convert.jsonEncode(msg));
  }

  void finest(LogxxItem msg) {
    _log.finest(convert.jsonEncode(msg));
  }
}

class LogxxItem {
  final String? prefix;
  final List<String>? msg;

  LogxxItem({
    this.prefix,
    this.msg,
  });

  factory LogxxItem.fromJson(Map<String, dynamic> json) {
    final List? list = json["msg"];
    List<String>? msgs;
    if (null != list) {
      msgs = [];
      for (int i = 0, len = list.length; i < len; ++i) {
        msgs.add(list[i].toString());
      }
    }
    return LogxxItem(
      prefix: json["prefix"],
      msg: msgs,
    );
  }

  factory LogxxItem.fromJsonStr(String json) {
    try {
      return LogxxItem.fromJson(convert.jsonDecode(json));
    } catch (e) {
      // 由于是日志结构本身的错误，解析失败直接输出即可，
      // 仍写回日志可能导致滚雪球
      if (Platformxx_c.isDebugMode) {
        print("json解析错误");
        print(e.toString());
        print(json);
      }
      return LogxxItem(msg: [json]);
    }
  }

  Map<String, dynamic> toJson() {
    final remap = <String, dynamic>{
      "prefix": prefix ?? "",
      "msg": msg ?? [],
    };
    return remap;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}

class LogxxRecord {
  final Level level;
  final String message;

  /// Logger where this record is stored.
  final String loggerName;

  /// Time when this record was created.
  final DateTime time;

  /// Unique sequence number greater than all log records created before it.
  final int sequenceNumber;

  final LogxxItem content;

  LogxxRecord({
    required this.level,
    required this.message,
    required this.time,
    required this.content,
    this.loggerName = "",
    this.sequenceNumber = -1,
  });

  static String getJsonStrByLogRecord(LogRecord item) {
    return getJsonStr(
      level: item.level,
      message: item.message,
      time: item.time,
      sequenceNumber: item.sequenceNumber,
      loggerName: item.loggerName,
      content: null,
    );
  }

  static String getJsonStr({
    required Level level,
    required String? message,
    required DateTime time,
    required LogxxItem? content,
    String loggerName = "",
    int sequenceNumber = -1,
  }) {
    assert(null != message || null != content);
    final remap = {
      "levelValue": level.value,
      "levelName": level.name,
      "message": message,
      "loggerName": loggerName,
      "time": time.millisecondsSinceEpoch,
      "sequenceNumber": sequenceNumber,
      "content": (null == content) ? convert.jsonEncode(content) : null,
    };
    return convert.jsonEncode(remap);
  }

  factory LogxxRecord.fromJson(Map json) {
    return LogxxRecord(
      level: Level(json["levelName"] ?? "", json["levelValue"] ?? -777),
      message: json["message"] ?? "",
      time: DateTime.fromMillisecondsSinceEpoch(json["time"] ?? 0),
      content: LogxxItem.fromJsonStr(json["message"] ?? ""),
      loggerName: json["loggerName"] ?? "",
      sequenceNumber: json["sequenceNumber"] ?? -1,
    );
  }

  factory LogxxRecord.fromJsonStr(String json) {
    try {
      return LogxxRecord.fromJson(convert.jsonDecode(json));
    } catch (e) {
      // 由于是日志结构本身的错误，解析失败直接输出即可，
      // 仍写回日志可能导致滚雪球
      if (Platformxx_c.isDebugMode) {
        print("json解析错误");
        print(e.toString());
        print(json);
      }
      return LogxxRecord(
        level: const Level("", -777),
        message: json,
        time: DateTime.fromMillisecondsSinceEpoch(0),
        content: LogxxItem(),
      );
    }
  }

  Map<String, dynamic> toJson() {
    final remap = <String, dynamic>{
      "levelValue": level.value,
      "levelName": level.name,
      "message": message,
      "loggerName": loggerName,
      "time": time.millisecondsSinceEpoch,
      "sequenceNumber": sequenceNumber,
    };
    return remap;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
