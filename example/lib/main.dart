import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ms_persist/ms_persist.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persist Demo',
      theme: ThemeData(
        primarySwatch: ([...Colors.primaries]..shuffle()).first,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Persist Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Count _count;

  void _incrementCounter() {
    _count.increment();
    _count.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
              icon: Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () async {
                await _count.delete();
                _count = null;
                setState(() {});
              })
        ],
      ),
      body: FutureBuilder(
        initialData: _count,
        future: () async {
          var list = await Count().list();
          if (list.isNotEmpty) return list.last;
          return Count();
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(
              child: CircularProgressIndicator(),
            );
          _count = snapshot.data;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                StreamBuilder<Count>(
                    stream: _count.listenChanges(),
                    initialData: _count,
                    builder: (context, snapshot) {
                      return Text(
                        '${snapshot.data.counter}',
                        style: Theme.of(context).textTheme.headline4,
                      );
                    }),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class Count with Persist<Count> {
  // You must define a id field or method get id
  String uuid;
  int counter;

  Count([this.uuid = '1', this.counter = 0]);

  void increment() => counter++;

  void decrement() => counter--;

  // Every time the mixer [Persist] need build you object, will call this method
  @override
  Count buildModel(Map<String, dynamic> map) {
    return Count(map['uuid'] as String, map['counter'] as int);
  }

  // Every time the mixer [Persist] need persist, this method is called to serialize object
  @override
  Map<String, dynamic> toMap() => {
        'uuid': uuid,
        'counter': counter,
      };
}
