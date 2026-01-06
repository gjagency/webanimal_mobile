import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String SCHEMA = dotenv.env['SCHEMA'] ?? "";
  static String HOST = dotenv.env['HOST'] ?? "";
  static String PORT = dotenv.env['PORT'] ?? "";

  static String baseUrl = '$SCHEMA://$HOST:$PORT';
}