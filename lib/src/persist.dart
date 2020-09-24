import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:uuid/uuid.dart';

final Uuid _uuid = Uuid();
Database _database;
String _dbName = '_persist.db';

Future<String> get _dbPath async {
  final appDocDir = await pathProvider.getApplicationDocumentsDirectory();
  return path.join(appDocDir.path, 'databases', _dbName);
}

/// The mixin with useful functions to save, update, list, find or delete any
/// model that implements [uuid], [buildModel] and [toMap]
///
mixin Persist<T> {
  StoreRef<String, dynamic> _storeRef;
  StreamController<T> _controller = StreamController();

  /// Singleton that provides a [Database] instance
  static Future<Database> get database async {
    if (_database == null) {
      _database = await databaseFactoryIo.openDatabase(await _dbPath);
    }
    return _database;
  }

  /// Main id that mixin uses to saves, retrieves or deletes in [Database].
  ///
  /// Must be override by model.
  String get uuid;

  /// A pointer to a store.
  ///
  StoreRef<String, dynamic> get storeRef {
    _storeRef ??= StoreRef(T.toString());
    return _storeRef;
  }

  /// Looks in db for model with same [id]
  Future<T> findById(String id) async {
    var record = await storeRef.record(id).get(await database);
    if (record == null) return null;
    return buildModel(record);
  }

  /// Build a new model from a [map].
  ///
  /// Must be override by model.
  T buildModel(Map<String, dynamic> map);

  Future<List<T>> list({Finder finder}) async {
    return (await storeRef.query(finder: finder).getSnapshots(await database))
        .map((e) => buildModel(e.value))
        .toList();
  }

  /// Emit a event every time has any change in current instance.
  /// Will emit a `null` as last event and closes stream when [delete] is called
  Stream<T> listenChanges() => _controller.stream;

  /// Save or update the current state.
  /// Return a new instance.
  /// The save method do not update current instance.
  Future<T> save([Map<String, dynamic> overrideData]) async {
    var data = {
      'createdAt': DateTime.now().toString(),
      ...this.toMap(),
      'uuid': uuid ?? _uuid.v4(),
      ...overrideData ?? {},
      'updatedAt': DateTime.now().toString(),
    };
    await storeRef.record(data['id'].toString()).put(await database, data);
    var model = this.buildModel(data);
    _controller.add(model);
    return model;
  }

  /// Deletes a record.
  /// Return `true` if record was deleted or `false` if record does not exists
  ///
  /// Throws [AssertionError] if [uuid] is null or empty.
  Future<bool> delete() async {
    _checkId();
    _controller.add(null);
    _controller.close();
    return storeRef.record(uuid.toString()).delete(await database) == null
        ? false
        : true;
  }

  /// Must return a [Map] that represent the current state, that [Persist] lib will write on db
  ///
  /// Must be override by model.
  Map<String, dynamic> toMap();

  /// Throws [AssertionError] if [uuid] is null or empty.
  void _checkId() {
    assert(uuid != null, 'id key must be non null');
    assert(uuid != '', 'id key must be non empty');
  }
}

/// Define a dbName.
/// Must set a name before any db operation or will use "_persist.db" as default value.
///
/// Throws [AssertionError] if [dbName] is null os empty string.
void setDBName(String dbName) {
  assert(dbName != null, 'dbName must be non null');
  assert(dbName.isNotEmpty, 'dbName must be non empty');
  _dbName = dbName;
}
