import 'package:ms_persist/ms_persist.dart';

class DumpDto with Persist<DumpData> {
  DumpDto({
    this.dumpData,
  });

  final DumpData? dumpData;

  @override
  DumpData buildModel(Map<String, dynamic> map) {
    return DumpData.fromMap(map);
  }

  @override
  Map<String, dynamic> toMap() {
    return dumpData?.toMap() ?? {};
  }

  @override
  String get storeName => 'DumpData';

  @override
  String? get uuid => dumpData?.id;

  @override
  set uuid(String? value) {
    if (dumpData != null) {
      dumpData!.id = value ?? '';
    }
  }
}

class DumpData {
  DumpData({
    required this.id,
    required this.name,
    required this.description,
  });

  String id;
  String name;
  String description;

  factory DumpData.fromMap(Map<String, dynamic> map) {
    return DumpData(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  @override
  String toString() {
    return 'DumpData{id: $id, name: $name, description: $description}';
  }
}
