import 'package:string_util_xx/StringUtilxx.dart';
import 'package:util_xx/stl.dart';

typedef HttpHeaderxx = IgnoreCaseMap<String>;
typedef HttpHeaderAnyxx = Map<String, String>;

typedef HttpFullHeaderxx = IgnoreCaseMap<List<String>>;
typedef HttpFullHeaderAnyxx = Map<String, List<String>>;

class Httpxx_c {
  Httpxx_c._();

  static HttpHeaderxx createHeader({
    HttpHeaderAnyxx? data,
  }) {
    return STLxx_c.createIgnoreCaseMap<String>(data: data);
  }

  static HttpHeaderxx createHeaderFromDynamic({
    Map<String, dynamic>? anyData,
  }) {
    return STLxx_c.createIgnoreCaseMap<String>(data: anyData?.map((k, v) {
      return MapEntry(k, v.toString());
    }));
  }

  static HttpFullHeaderxx createFullHeader({
    HttpFullHeaderAnyxx? data,
  }) {
    return STLxx_c.createIgnoreCaseMap<List<String>>(data: data);
  }

  static HttpHeaderxx setHeaders({
    required HttpHeaderxx toHeaders,
    required HttpHeaderAnyxx fromHeaders,
  }) {
    toHeaders.addAll(fromHeaders);
    return toHeaders;
  }

  static String? toHeaderStr(HttpHeaderAnyxx? header) {
    if (true != header?.isNotEmpty) {
      return null;
    }
    final list = header!.entries;
    final restr = StringBuffer();
    for (final item in list) {
      restr.write("${item.key}: ${item.value}");
      restr.write("\r\n");
    }
    return restr.toString();
  }

  static bool respIsSuccess(
    int? code, {
    String? message,
    bool allow3xx = false,
  }) {
    final c = (code != null) ? code ~/ 100 : null;
    if (c == 2) {
      return true;
    }
    if (allow3xx && c == 3) {
      return true;
    }
    if (null != message) {
      return (StringUtilxx_c.isIgnoreCaseEqual(message, "ok"));
    }
    return false;
  }
}
