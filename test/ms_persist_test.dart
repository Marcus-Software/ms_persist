import 'package:flutter_test/flutter_test.dart';
import 'package:ms_persist/ms_persist.dart';

import 'mock/dump.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setDbName('testDb.db');
  });

  test('must return a correct store name', () {
    var dumb = Dumb();
    expect(dumb.storeRef.name, 'Dumb');
  });

  test('must save', () async {
    var dumb = Dumb();
    var savedDump = await dumb.save();
    expect(dumb, isNotNull);
    expect(savedDump.uuid, isNotNull);
    expect(dumb.beforeSaveHits, 1);
    expect(dumb.afterSaveHits, 1);
  });

  test('must delete', () async {
    var dumb = Dumb(title: 'Mr. Deleterson', dummy: 'Nothing');
    var savedDump = await dumb.save();
    expect(savedDump.uuid, isNotNull);
    expect(await savedDump.delete(), isTrue);
    expect(await Dumb().findById(savedDump.uuid!), isNull);
    expect(savedDump.beforeDeleteHits, 1);
    expect(savedDump.afterDeleteHits, 1);
  });

  test('must return a model using a uuid', () async {
    Dumb dumb = Dumb(title: 'Mr. Deleterson', dummy: 'Nothing');
    Dumb savedDump = await dumb.save();
    expect(savedDump.uuid, isNotNull);
    Dumb? foundDump = await Dumb().findById(savedDump.uuid!);
    expect(foundDump, isNotNull);
    expect(foundDump!.uuid, savedDump.uuid);
    expect(foundDump.dummy, savedDump.dummy);
    expect(foundDump.title, savedDump.title);
  });

  test('must return true if is dirty', () async {
    var dumb = await (Dumb(dummy: 'Nothing', title: 'Mr. Dummy').save());
    dumb.title = 'New Title';
    expect(dumb.isDirty(), isTrue);
    expect(dumb.dirtyState().title, 'Mr. Dummy');
    expect(dumb.title, 'New Title');
    expect(dumb.isDirty(['title', 'dummy']), isFalse);
    dumb.dummy = 'continue nothing';
    expect(dumb.isDirty(['title', 'dummy']), isTrue);
  });

  test('must list items', () async {
    final list = await Dumb().list();
    expect(list, isNotEmpty);
    expect(list, isList);
  });

  test('must refresh item', () async {
    final dumb = Dumb(dummy: 'Nothing', title: 'Mr. Dummy');
    var saved = await dumb.save();
    saved.title = 'New Title';
    saved = await saved.refresh() as Dumb;
    expect(saved.title, 'Mr. Dummy');
  });

  test('must listen changes', () async {
    final dumb = Dumb(dummy: 'Nothing', title: 'Mr. Dummy');
    var stream = dumb.listenChanges();
    expect(
        stream,
        emitsInOrder([
          isA<Dumb>(),
          isA<Dumb>(),
          null,
          emitsDone,
        ]));
    var saved = await dumb.save();
    saved.title = 'New Title';
    saved = await saved.save();
    await saved.delete();
  });
}
