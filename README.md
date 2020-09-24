# MS Persist

A mixin that help you on handling model as a CRUD

## Getting Started

Is very simple to start use.

After set the lib in `pubspec.yaml` and run `flutter pub get`

```dart
import 'package:ms_persist/ms_persist.dart';

class YourModel with Persist<YourModel> {
  // .. a lot of another fields
  //TODO: implement field uuid
  @override
  String uuid;

  YourModel({this.uuid/*other fields*/});

  //TODO: implement buildModel
  @override
  YourModel buildModel(Map<String, dynamic> map){
    return YourModel(
      uuid: map['uuid'],
      );
  }

  //TODO: implement toMap
  @override
  Map<String, dynamic> toMap(){
    return {
      'uuid': this.uuid,
      //TODO: add here every field or extra data that you want to save
    };
  }
}
```

_That's all folks_
I hope you enjoy this lib.
