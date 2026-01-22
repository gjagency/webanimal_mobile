import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  static String SCHEMA = "";
  static String HOST = "";
  static String PORT = "";

  static Future<void> load() async {
    await dotenv.load(fileName: ".env");

    SCHEMA = dotenv.env['SCHEMA'] ?? 'http';
    HOST = dotenv.env['HOST'] ?? '127.0.0.1';
    PORT = dotenv.env['PORT'] ?? '8000';
  }

  static String baseUrl = '$SCHEMA://$HOST:$PORT';
}
