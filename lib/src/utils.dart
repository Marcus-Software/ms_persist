import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pathProvider;

Future<String> getDbPath(String dbName) async {
  late final String dbPath;
  if (Platform.isWindows) {
    dbPath = Platform.environment['LOCALAPPDATA'].toString();
  } else {
    final appDocDir = await pathProvider.getApplicationDocumentsDirectory();
    dbPath = appDocDir.path;
  }

  return path.join(dbPath, 'databases', dbName);
}
