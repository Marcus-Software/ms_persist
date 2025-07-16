import 'package:ms_persist/ms_persist.dart';

class Dumb with Persist<Dumb> {
  String? uuid;
  String? dummy;
  String? title;
  int beforeSaveHits = 0;
  int afterSaveHits = 0;
  int beforeDeleteHits = 0;
  int afterDeleteHits = 0;

  Dumb({
    this.uuid,
    this.dummy,
    this.title,
  });

  factory Dumb.fromMap(Map<String, dynamic> map) {
    return new Dumb(
      uuid: map['uuid'] as String?,
      dummy: map['dummy'] as String?,
      title: map['title'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'uuid': this.uuid,
      'dummy': this.dummy,
      'title': this.title,
    };
  }

  @override
  Dumb buildModel(Map<String, dynamic> map) => Dumb.fromMap(map);

  @override
  void onBeforeSave(Dumb? b, bool update) {
    beforeSaveHits++;
  }

  @override
  void onAfterSave(Dumb? b) {
    afterSaveHits++;
  }

  @override
  void onBeforeDelete(Dumb? b) {
    beforeDeleteHits++;
  }

  @override
  void onAfterDelete(Dumb? b) {
    afterDeleteHits++;
  }
}
