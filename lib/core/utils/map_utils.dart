import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

class MapUtils {
  /// A shared HTTP client for all map tile requests.
  /// Using a single client prevents 'Client already closed' errors during
  /// widget disposal and rapid navigation.
  static final http.BaseClient mapClient = RetryClient(
    http.Client(),
    retries: 3,
    when: (response) => response.statusCode == 503 || response.statusCode == 504,
  );
}
