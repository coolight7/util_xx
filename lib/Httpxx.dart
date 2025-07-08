import 'package:util_xx/stl.dart';

typedef HttpHeaderxx = IgnoreCaseMap<String>;
typedef HttpHeaderAnyxx = Map<String, String>;

class Httpxx_c {
  Httpxx_c._();

  static HttpHeaderxx createHeader({
    HttpHeaderAnyxx? data,
  }) {
    return STLxx_c.createIgnoreCaseMap<String>(data: data);
  }

  static HttpHeaderxx setHeaders({
    required HttpHeaderxx toHeaders,
    required HttpHeaderAnyxx fromHeaders,
  }) {
    toHeaders.addAll(fromHeaders);
    return toHeaders;
  }
}
