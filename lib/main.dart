import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
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
  
  static const platform = const MethodChannel('samples.flutter.dev/speech');

  String resposta = 'msg';

  @override
  void initState() {
    super.initState();
    getVoiceText();
  }

  void _onLoading() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Container(
        width: 400,
        height: 400,
        child:Dialog(
        child: new Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            new CircularProgressIndicator(),
            new Text("Loading"),
          ],
        ),
      )
      );
    },
  );
}

  void getVoiceText() {
    platform.setMethodCallHandler((call){
      if(call.method == "voice_text"){
        setState(() {
          resposta = call.arguments;
        });
        // Navigator.pop(context);
      }
      return null;
    });
  }

  Future<void> _voiceRecord() async {
      platform.invokeMethod('speech');
  }

  Future<void> _stop() async {
    // _onLoading();
    String texto;
    try {
      await platform.invokeMethod('stop');
    } on PlatformException catch (e) {
      texto = "Failed";
    }

    setState(() {
      resposta = texto;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              resposta,
            ),
            RaisedButton(
              child: Text("escutar"),
              onPressed: _voiceRecord,
            ),
            RaisedButton(
              child: Text("cancelar"),
              onPressed: _stop,
            ),
          ],
        ),
      ),
    );
  }
}
