// ignore_for_file: file_names, camel_case_types, constant_identifier_names

import 'dart:convert' as convert;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class MyLogger {
  static final _instance = MyLogger(className: "Global");

  final Logger _log;
  final String className;

  MyLogger({
    required this.className,
  }) : _log = Logger(className);

  /// 获得全局通用单例
  static MyLogger to() => _instance;

  /// * 如果希望输出日志，需要调用一次`MyLogger.enableDebugPrint()`
  /// * 当然也可以自己通过[listenLog]监听处理日志
  static void enableDebugPrint() {
    if (kDebugMode) {
      listenLog((item) {
        // ignore: avoid_print
        print(item.toString());
      });
    }
  }

  /// * 监听并自定义处理收到的日志
  /// * 多个不同的[MyLogger]收集到的日志都会汇集于此
  static void listenLog(void Function(LogRecord)? onLog) {
    Logger.root.onRecord.listen(onLog);
  }

  void shout(MyLogItem msg) {
    _log.shout(convert.jsonEncode(msg));
  }

  void severe(MyLogItem msg) {
    _log.severe(convert.jsonEncode(msg));
  }

  void warning(MyLogItem msg) {
    _log.warning(convert.jsonEncode(msg));
  }

  void info(MyLogItem msg) {
    _log.info(convert.jsonEncode(msg));
  }

  void config(MyLogItem msg) {
    _log.config(convert.jsonEncode(msg));
  }

  void fine(MyLogItem msg) {
    _log.fine(convert.jsonEncode(msg));
  }

  void finer(MyLogItem msg) {
    _log.finer(convert.jsonEncode(msg));
  }

  void finest(MyLogItem msg) {
    _log.finest(convert.jsonEncode(msg));
  }
}

class MyLogItem {
  final String? prefix;
  final List<String>? msg;

  MyLogItem({
    this.prefix,
    this.msg,
  });

  factory MyLogItem.fromJson(Map<String, dynamic> json) {
    final List? list = json["msg"];
    List<String>? msgs;
    if (null != list) {
      msgs = [];
      for (int i = 0, len = list.length; i < len; ++i) {
        msgs.add(list[i].toString());
      }
    }
    return MyLogItem(
      prefix: json["prefix"],
      msg: msgs,
    );
  }

  factory MyLogItem.fromJsonStr(String json) {
    try {
      return MyLogItem.fromJson(convert.jsonDecode(json));
    } catch (e) {
      // 由于是日志结构本身的错误，解析失败直接输出即可，
      // 仍写回日志可能导致滚雪球
      if (kDebugMode) {
        print("json解析错误");
        print(e.toString());
        print(json);
      }
      return MyLogItem(msg: [json]);
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

class MyLogRecord {
  final Level level;
  final String message;

  /// Logger where this record is stored.
  final String loggerName;

  /// Time when this record was created.
  final DateTime time;

  /// Unique sequence number greater than all log records created before it.
  final int sequenceNumber;

  final MyLogItem content;

  MyLogRecord({
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
    required MyLogItem? content,
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
      "content": message ?? convert.jsonEncode(content!),
    };
    return convert.jsonEncode(remap);
  }

  factory MyLogRecord.fromJson(Map<String, dynamic> json) {
    return MyLogRecord(
      level: Level(json["levelName"] ?? "", json["levelValue"] ?? -777),
      message: json["message"] ?? "",
      time: DateTime.fromMillisecondsSinceEpoch(json["time"] ?? 0),
      content: MyLogItem.fromJsonStr(json["content"] ?? ""),
      loggerName: json["loggerName"] ?? "",
      sequenceNumber: json["sequenceNumber"] ?? -1,
    );
  }

  factory MyLogRecord.fromJsonStr(String json) {
    try {
      return MyLogRecord.fromJson(convert.jsonDecode(json));
    } catch (e) {
      // 由于是日志结构本身的错误，解析失败直接输出即可，
      // 仍写回日志可能导致滚雪球
      if (kDebugMode) {
        print("json解析错误");
        print(e.toString());
        print(json);
      }
      return MyLogRecord(
        level: const Level("", -777),
        message: json,
        time: DateTime.fromMillisecondsSinceEpoch(0),
        content: MyLogItem(),
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
      "content": convert.jsonEncode(content),
    };
    return remap;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
