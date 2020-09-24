import 'package:ms_persist/ms_persist.dart';

class Dumb with Persist<Dumb> {
  String uuid;
  String dummy;
  String title;

  Dumb({this.uuid, this.dummy, this.title});

  factory Dumb.fromMap(Map<String, dynamic> map) {
    return new Dumb(
      uuid: map['uuid'] as String,
      dummy: map['dummy'] as String,
      title: map['title'] as String,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'id': this.uuid,
      'dummy': this.dummy,
      'title': this.title,
    };
  }

  @override
  Dumb buildModel(Map<String, dynamic> map) => Dumb.fromMap(map);
}
