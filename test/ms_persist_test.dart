import 'package:flutter_test/flutter_test.dart';

import 'mock/dump.dart';

void main() {
  test('must return a correct store name', () {
    var dumb = Dumb();
    expect(dumb.storeRef.name, 'Dumb');
  });

  test('must throw AssertError', () {
    var dumb = Dumb(uuid: null);
    expect(() async => await dumb.delete(), throwsAssertionError);
  });

  test('must save', () async {
    var dumb = Dumb();
    var savedDump = await dumb.save();
    expect(dumb, isNotNull);
    expect(savedDump.uuid, isNotNull);
  });

  test('must delete', () async {
    var dumb = Dumb();
    var savedDump = await dumb.save();
    expect(savedDump.uuid, isNotNull);
    expect(await savedDump.delete(), isTrue);
    expect(await Dumb().findById(savedDump.uuid), isNull);
  });
}
