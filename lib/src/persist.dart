import 'dart:async';

import 'package:ms_map_utils/ms_map_utils.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:uuid/uuid.dart';

Database _database;
String _dbName = '_persist.db';
final Uuid _uuid = Uuid();

Future<String> get _dbPath async {
  final appDocDir = await pathProvider.getApplicationDocumentsDirectory();
  return path.join(appDocDir.path, 'databases', _dbName);
}

/// Define a dbName.
/// Must set a name before any db operation or will use "_persist.db" as default value.
///
/// Throws [AssertionError] if [dbName] is null os empty string.
void setDbName(String dbName) {
  assert(dbName != null, 'dbName must be non null');
  assert(dbName.isNotEmpty, 'dbName must be non empty');
  _dbName = dbName;
}

/// The mixin with useful functions to save, update, list, find or delete any
/// model that implements [uuid], [buildModel] and [toMap]
///
mixin Persist<T> {
  /// Singleton that provides a [Database] instance
  static Future<Database> get database async {
    if (_database == null) {
      _database = await (getDatabaseFactorySqflite(sqflite.databaseFactory))
          .openDatabase(await _dbPath);
      // _database = await databaseFactoryIo.openDatabase(await _dbPath);
    }
    return _database;
  }

  StoreRef<String, dynamic> _storeRef;
  StreamController<T> _controller = StreamController();
  Map<String, dynamic> _initialState = {};

  /// A pointer to a store.
  ///
  StoreRef<String, dynamic> get storeRef {
    _storeRef ??= StoreRef(T.toString());
    return _storeRef;
  }

  /// Main id that mixin uses to saves, retrieves or deletes in [Database].
  ///
  /// Must be override by model.
  String get uuid;

  /// Build a new model from a [map].
  ///
  /// Must be override by model.
  T buildModel(Map<String, dynamic> map);

  /// Deletes a record.
  /// Return `true` if record was deleted or `false` if record does not exists
  ///
  /// Throws [AssertionError] if [uuid] is null or empty.
  Future<bool> delete() async {
    onBeforeDelete(this as T);
    if (uuid == null) return false;

    var deleted = await storeRef.record(uuid!).delete(await database);
    _controller.add(null);
    dispose();
    onAfterDelete(this as T);

    return deleted == null ? false : true;
  }

  /// Returns a new model with initial state
  T dirtyState() =>
      this.buildModel({...toMap(), ...toMap().diff(_initialState)});

  /// Looks in db for model with same [id]
  Future<T> findById(String id) async {
    var record = await storeRef.record(id).getSnapshot(await database);
    if (record == null) return null;
    return _buildModel(record.value);
  }

  /// Returns `true` if current state is dirty.
  /// Optional [fields] check only if in those fields is dirty.
  bool isDirty([List fields]) {
    if (fields != null)
      return _initialState.diff(toMap()).containsKeys(fields ?? []);
    return _initialState.diff(toMap()).isNotEmpty;
  }

  /// List or search items in db
  Future<List<T>> list({Finder finder}) async {
    finder ??= Finder(sortOrders: [SortOrder('uuid')]);
    return (await storeRef.query(finder: finder).getSnapshots(await database))
        .map((e) => _buildModel(e.value))
        .toList();
  }

  /// Emit a event every time has any change in current instance.
  /// Will emit a `null` as last event and closes stream when [delete] is called
  Stream<T> listenChanges() => _controller.stream;

  /// Save or update the current state.
  /// Return a new instance.
  /// The save method do not update current instance.
  Future<T> save([Map<String, dynamic>? overrideData]) async {
    onBeforeSave(this as T, uuid != null);
    var data = {
      'createdAt': DateTime.now().toString(),
      ...this.toMap(),
      ...overrideData ?? {},
      'uuid': _genUUID(),
      'updatedAt': DateTime.now().toString(),
    };
    await storeRef.record(data['uuid'].toString()).put(await database, data);
    var model = this._buildModel(data);
    _controller.add(model);
    onAfterSave(model);

    return model;
  }

  /// Must return a [Map] that represent the current state, that [Persist] lib will write on db
  ///
  /// Must be override by model.
  Map<String, dynamic> toMap();

  T _buildModel(Map map) {
    var model = buildModel(map);
    (model as Persist)._initialState = map;
    return model;
  }

  /// Generate a new uuid
  String _genUUID() => uuid ?? _uuid.v1();

  /// Close the stream controller
  @mustCallSuper
  void dispose() {
    _controller.close();
  }

  /// Hook to run before save
  void onBeforeSave(T data, bool update) {}

  /// Hook to run after save
  void onAfterSave(T data) {}

  /// Hook to run before delete
  void onBeforeDelete(T data) {}

  /// Hook to run after delete
  void onAfterDelete(T data) {}
}
