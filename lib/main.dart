import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'globals.dart' as globals;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Page Demo',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: MapPage(title: 'Map Page'),
    );
  }
}

class MapPage extends StatefulWidget {
// コンストラクト
  MapPage({Key key, this.title}) : super(key: key);

// 定数定義
  final String title;

// アロー関数を用いて、Stateを呼ぶ
  @override
  _MapPageState createState() => new _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<String> _data = [];
  String _selectedChoice = ''; // The app's "state".

  void _select(String choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = choice;
    });
  }

  @override
  void initState() {
    super.initState();
    _getAuth();
  }

  Future<void> _getAuth() async {
    var res = await http.get(
      globals.targetUrl + 'api/auth',
      headers: {HttpHeaders.authorizationHeader: globals.authToken},
    );

    var jsonList = json.decode(res.body);

    jsonList.forEach((value) {
      Map _temp = value;
      _data.add(_temp['user_id']);
    });
  }

  Widget buildListView() {
    return new ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _data.length,
        /* Divider を挟む */
        itemBuilder: (context, i) {
          final index = i;
          return ListTile(
            title: Text(_data[index]),
          );
        });
  }

  DateTime selectedDate = DateTime.now();
  String selectDate = '';

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2019, 4),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        //ここで選択された値を変数なり、コントローラーに代入する
        globals.targetDate = DateFormat('yyyyMMdd').format(selectedDate);
        print('select date = ' + globals.targetDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: _buildBar(context),
      body: _mapView(context),
    );
  }

  Widget _buildBar(BuildContext context) {
    return new AppBar(
      title: new Text("Map"),
//      centerTitle: true,
      leading: IconButton(icon: Icon(Icons.menu), onPressed: null),
      actions: <Widget>[
        PopupMenuButton<String>(
          icon: Icon(Icons.account_box),
          initialValue: _selectedChoice,
          onSelected: _select,
          itemBuilder: (BuildContext context) {
            return _data.map((String choice) {
              return PopupMenuItem(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
//        IconButton(
//            icon: Icon(Icons.account_box), onPressed: () => buildListView()),
        IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context)),
        IconButton(icon: Icon(Icons.watch_later), onPressed: null),
        IconButton(icon: Icon(Icons.directions_walk), onPressed: null),
        IconButton(
          icon: Icon(Icons.location_on),
          onPressed: null,
        ),
      ],
    );
  }

  Widget _mapView(BuildContext context) {
    return new FlutterMap(
      options: new MapOptions(
        center: new LatLng(35.000081, 137.004055),
        zoom: 17.0,
      ),
      layers: [
        new TileLayerOptions(
          urlTemplate: "https://api.tiles.mapbox.com/v4/"
              "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
          additionalOptions: {
            'accessToken':
                'pk.eyJ1IjoieWlzaWthd2EiLCJhIjoiY2s2YndmdXFuMGZ1bDNsb3ZnMXBsbnI3eSJ9.gftC8NPsB9xNWIVEdWnTvw',
            'id': 'mapbox.streets',
          },
        ),
      ],
    );
  }
}
