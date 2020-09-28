# MS Persist
[![Pub](https://img.shields.io/pub/v/ms_persist.svg)](https://pub.dartlang.org/packages/ms_persist)
[![GitHub stars](https://img.shields.io/github/stars/Marcus-Software/ms_persist?style=social)](https://github.com/Marcus-Software/ms_persist)
<span class="badge-buymeacoffee">
<a href="https://www.buymeacoffee.com/marcusedu" title="Donate to this project using Buy Me A Coffee"><img src="https://img.shields.io/badge/buy%20me%20a%20coffee-donate-yellow.svg" alt="Buy Me A Coffee donate button" /></a>
</span>

A mixin that help you on handling model as a CRUD

## Getting Started

Is very simple to start use.

After set the lib in `pubspec.yaml` and run `flutter pub get`

```dart
import 'package:ms_persist/ms_persist.dart';

class YourModel with Persist<YourModel> {
  // .. a lot of another fields
  String someField;
  //TODO: implement field uuid
  @override
  String uuid;

  YourModel({this.uuid,this.someField/*other fields*/});

  //TODO: implement buildModel
  @override
  YourModel buildModel(Map<String, dynamic> map){
    return YourModel(
      uuid: map['uuid'],
      someField: map['someField'],
      );
  }

  //TODO: implement toMap
  @override
  Map<String, dynamic> toMap(){
    return {
      'uuid': this.uuid,
      'someField': someField,
      //TODO: add here every field or extra data that you want to save
    };
  }
}

// Now just use Persist to do hard word to persist data.
void main() async {
    var myModel = YourModel().find('42854c0c-018d-11eb-adc1-0242ac120002');
    myModel.someField = 'new value';
    await myModel.save();
    myModel.someField = 'other value';
    myModel.isDirty(); // returns true;
    await myModel.save();
    myModel.isDirty(); // returns false;
}
```

_That's all folks!_

I hope you enjoy this lib.

[See another libs here](https://pub.dev/publishers/marcussoftware.info/packages)
