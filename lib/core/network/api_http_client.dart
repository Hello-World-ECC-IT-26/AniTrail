import 'package:http/http.dart' as http;

/// Shared connection pool for all API services in the app process.
class ApiHttpClient {
  ApiHttpClient._();

  static final http.Client shared = http.Client();
}
