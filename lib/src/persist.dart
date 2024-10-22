import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ms_map_utils/ms_map_utils.dart';
import 'package:ms_persist/src/utils.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqfliteFfi;
import 'package:uuid/uuid.dart';

Database? _database;
String _dbName = '_persist.db';
final Uuid _uuid = Uuid();

/// Define a dbName.
/// Must set a name before any db operation or will use "_persist.db" as default value.
void setDbName(String dbName) {
  _dbName = dbName;
}

/// The mixin with useful functions to save, update, list, find or delete any
/// model that implements [uuid], [buildModel] and [toMap]
///
mixin Persist<T> {
  /// Singleton that provides a [Database] instance
  static Future<Database> get database async {
    final db = _database;
    if (db != null) return db;

    var dbPath = await getDbPath(_dbName);
    if (kIsWeb) {
      _database = await databaseFactoryWeb.openDatabase(_dbName);
    } else if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfi.sqfliteFfiInit();
      _database =
          await (getDatabaseFactorySqflite(sqfliteFfi.databaseFactoryFfi))
              .openDatabase(dbPath);
    } else {
      _database = await (getDatabaseFactorySqflite(sqflite.databaseFactory))
          .openDatabase(dbPath);
    }

    return _database!;
  }

  StoreRef<String, dynamic>? _storeRef;
  StreamController<T?> _controller = StreamController.broadcast();
  Map<String, dynamic> _lastSavedState = {};

  /// Main id that mixin uses to saves, retrieves or deletes in [Database].
  ///
  /// Must be override by model.
  String? uuid;

  /// A pointer to a store.
  ///
  /// The store is created based on the model name.
  StoreRef<String, dynamic> get storeRef {
    _storeRef ??= StoreRef(storeName);

    return _storeRef!;
  }

  /// The model name.
  String get storeName => T.toString();

  /// Build a new model from a [map].
  ///
  /// Must be override by model.
  T buildModel(Map<String, dynamic> map);

  /// Deletes a record.
  /// Return `true` if record was deleted or `false` if record does not exists
  Future<bool> delete() async {
    onBeforeDelete(this as T);
    if (uuid == null) return false;

    var deleted = await storeRef.record(uuid!).delete(await database);
    _controller.add(null as T?);
    dispose();
    onAfterDelete(this as T);

    return deleted == null ? false : true;
  }

  /// Returns a new model initial state before any change saved.
  T dirtyState() =>
      this.buildModel({...toMap(), ...diff(toMap(), _lastSavedState)});

  /// Close the stream controller
  @mustCallSuper
  void dispose() {
    _controller.close();
  }

  /// Looks in db for model with same [id]
  Future<T?> findById(String id) async {
    var record = await storeRef.record(id).getSnapshot(await database);
    if (record == null) return null;

    return _buildModel(record.value);
  }

  /// Returns `true` if current state is dirty.
  /// Optional [fields] check only if in those fields is dirty.
  bool isDirty([List<Object>? fields]) {
    var diffState = diff(toMap(), _lastSavedState);
    if (fields != null) return diffState.containsKeys(fields);

    return diffState.isNotEmpty;
  }

  /// List or search items in db
  Future<List<T>> list({Finder? finder}) async {
    finder ??= Finder(sortOrders: [SortOrder('uuid')]);
    var res = await storeRef.query(finder: finder).getSnapshots(await database);

    return res.map((e) => _buildModel(e.value)).toList();
  }

  /// Emit a event every time has any change in current instance.
  /// Will emit a `null` as last event and closes stream when [delete] is called
  Stream<T?> listenChanges() => _controller.stream;

  /// Hook to run after delete
  void onAfterDelete(T data) {}

  /// Hook to run after save
  void onAfterSave(T data) {}

  /// Hook to run before delete
  void onBeforeDelete(T data) {}

  /// Hook to run before save
  void onBeforeSave(T data, bool update) {}

  /// Refresh current instance with db data.
  Future<T?> refresh() async {
    var record = await storeRef.record(uuid!).getSnapshot(await database);
    if (record == null) return null;
    final model = _buildModel(record.value);
    _controller.add(model);
    (model as Persist)._controller = _controller;

    return model;
  }

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

    _lastSavedState = data;
    await storeRef.record(data['uuid'].toString()).put(await database, data);
    var model = this._buildModel(data);
    (model as Persist)._controller = _controller;
    _controller.add(model);
    onAfterSave(model);

    return model;
  }

  /// Must return a [Map] that represent the current state, that [Persist] lib will write on db
  ///
  /// Must be override by model.
  Map<String, dynamic> toMap();

  /// Build a new model from a [map] and set the last saved state.
  T _buildModel(Map<String, dynamic> map) {
    var model = buildModel(map);
    (model as Persist)._lastSavedState = map;

    return model;
  }

  /// Generate a new uuid
  String _genUUID() => uuid ?? _uuid.v1();
}
