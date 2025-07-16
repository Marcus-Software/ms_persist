import 'package:flutter_test/flutter_test.dart';
import 'package:ms_persist/ms_persist.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqfliteFfi;

import 'mock/dump_dto.dart';

void main() {
  setUpAll(() {
    setDbName('testDb.db');
    sqflite.databaseFactory = sqfliteFfi.databaseFactoryFfi;
  });
  tearDownAll(() async {
    final list = await DumpDto().list();
    final deletes = <Future>[];
    for (final dd in list) {
      deletes.add(DumpDto(dumpData: dd).delete());
    }
    await Future.wait(deletes);
  });

  test('DumpDto.save', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '1',
        name: 'Test Name',
        description: 'Test Description',
      ),
    );

    var savedDump = await dump.save();

    expect(savedDump, isNotNull);
    expect(savedDump.id, '1');
    expect(savedDump.name, 'Test Name');
    expect(savedDump.description, 'Test Description');
  });

  test('DumpDto.findById', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '2',
        name: 'Another Name',
        description: 'Another Description',
      ),
    );

    await dump.save();
    var foundDump = await dump.findById('2');

    expect(foundDump, isNotNull);
    expect(foundDump!.id, '2');
    expect(foundDump.name, 'Another Name');
    expect(foundDump.description, 'Another Description');
  });

  test('DumpDto.delete', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '3',
        name: 'Delete Me',
        description: 'This will be deleted',
      ),
    );

    var savedDump = await dump.save();
    expect(savedDump, isNotNull);

    var deleteResult = await DumpDto(dumpData: savedDump).delete();
    expect(deleteResult, isTrue);

    var foundDump = await dump.findById('3');
    expect(foundDump, isNull);
  });

  test('DumpDto.list', () async {
    var dump1 = DumpDto(
      dumpData: DumpData(
        id: '4',
        name: 'List Item 1',
        description: 'First item in the list',
      ),
    );
    var dump2 = DumpDto(
      dumpData: DumpData(
        id: '5',
        name: 'List Item 2',
        description: 'Second item in the list',
      ),
    );

    await dump1.save();
    await dump2.save();

    var list = await DumpDto().list();
    expect(list, isNotEmpty);
    expect(list.length, 4);
    expect(list[2].id, '4');
    expect(list[3].id, '5');
  });

  test('DumpDto.update', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '6',
        name: 'Original',
        description: 'Desc',
      ),
    );
    await dump.save();
    var updated = DumpDto(
      dumpData: DumpData(
        id: '6',
        name: 'Updated',
        description: 'Desc',
      ),
    );
    var saved = await updated.save();
    expect(saved.name, 'Updated');
    var found = await dump.findById('6');
    expect(found!.name, 'Updated');
  });

  test('DumpDto.isDirty', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '7',
        name: 'Dirty',
        description: 'Test',
      ),
    );
    await dump.save();
    dump.dumpData!.name = 'Changed';
    expect(dump.isDirty(), isTrue);
    expect(dump.isDirty(['name']), isTrue);
    expect(dump.isDirty(['description']), isFalse);
  });

  test('DumpDto.refresh', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '8',
        name: 'ToRefresh',
        description: 'Desc',
      ),
    );
    await dump.save();
    var updated = DumpDto(
      dumpData: DumpData(
        id: '8',
        name: 'Refreshed',
        description: 'Desc',
      ),
    );
    await updated.save();
    var refreshed = await dump.refresh();
    expect(refreshed!.name, 'Refreshed');
  });

  test('DumpDto.listenChanges', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '9',
        name: 'Listen',
        description: 'Desc',
      ),
    );
    final changes = <DumpData?>[];
    dump.listenChanges().listen((event) {
      print('Change detected: $event');
      if (event != null) changes.add(event);
    });
    await dump.save();
    dump.dumpData!.name = 'Changed';
    await dump.save();
    await Future.delayed(const Duration(seconds: 1));
    expect(changes.length, 2);
    expect(changes[1]!.name, 'Changed');
  });

  test('DumpDto.save with overrideData', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '10',
        name: 'Override',
        description: 'Desc',
      ),
    );
    var saved = await dump.save({'name': 'Overridden'});
    expect(saved.name, 'Overridden');
  });

  test('DumpDto.delete non-existent', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: 'not-exist',
        name: 'No',
        description: 'No',
      ),
    );
    var deleted = await dump.delete();
    expect(deleted, isFalse);
  });

  test('DumpDto.dirtyState', () async {
    var dump = DumpDto(
      dumpData: DumpData(
        id: '11',
        name: 'DirtyState',
        description: 'Desc',
      ),
    );
    await dump.save();
    dump.dumpData!.name = 'Changed';
    var dirty = dump.dirtyState();
    expect(dirty.name, 'Changed');
  });

  test('DumpDto hooks', () async {
    var dump = HookedDumpDto(
      dumpData: DumpData(
        id: '12',
        name: 'Hooks',
        description: 'Desc',
      ),
    );
    await dump.save();
    await dump.delete();
    expect(
        dump.calls,
        containsAll(
            ['beforeSave', 'afterSave', 'beforeDelete', 'afterDelete']));
  });
}

class HookedDumpDto extends DumpDto {
  HookedDumpDto({DumpData? dumpData}) : super(dumpData: dumpData);

  final List<String> calls = [];

  @override
  void onBeforeSave(data, update) => calls.add('beforeSave');

  @override
  void onAfterSave(data) => calls.add('afterSave');

  @override
  void onBeforeDelete(data) => calls.add('beforeDelete');

  @override
  void onAfterDelete(data) => calls.add('afterDelete');
}
