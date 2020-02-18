import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:gpx/gpx.dart';
import 'package:intl/intl.dart';
import 'package:geojson/geojson.dart';
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
  List<Marker> markersData = [];
  List<String> _data = [];
  List<LatLng> points = [];
  String _selectedChoice = ''; // The app's "state".
  MapController mapController;
  var bounds = new LatLngBounds();
  DateTime selectedDate = DateTime.now();
  String selectDate = '';

  void _select(String choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = choice;
    });
  }

  @override
  void initState() {
    super.initState();
    globals.targetDate = DateFormat('yyyyMMdd').format(DateTime.now());
    _getAuth();
    _getMarker();
    mapController = MapController();
    _getRoute();
  }

  Future<void> _getRoute() async {
    var res = await http.get(
      globals.targetUrl +
          'api/route?userid=' +
          _selectedChoice +
          '&date=' +
          globals.targetDate +
          '&type=' +
          '1',
      headers: {HttpHeaders.authorizationHeader: globals.authToken},
    );

    points.clear();
    var xmlGpx = GpxReader().fromString(res.body);
    xmlGpx.trks.forEach((trks) {
      trks.trksegs.forEach((trksegs) {
        trksegs.trkpts.forEach((val) {
          points.add(LatLng(val.lat, val.lon));
        });
      });
    });

    points.forEach((val) {
      bounds.extend(val);
    });

    mapController.fitBounds(
      bounds,
      options: FitBoundsOptions(
        padding: EdgeInsets.only(left: 8.0, right: 8.0),
      ),
    );
  }

  Future<void> _getRating() async {
    var res = await http.get(
      globals.targetUrl +
          'api/rating?userid=' +
          _selectedChoice +
          '&date=' +
          globals.targetDate,
      headers: {HttpHeaders.authorizationHeader: globals.authToken},
    );
    print('rating =' + res.body);
  }

  Future<void> _getMarker() async {
    var res = await http.get(
      globals.targetUrl + 'api/marker',
      headers: {HttpHeaders.authorizationHeader: globals.authToken},
    );
    markersData.clear();

    var features = await featuresFromGeoJson(res.body);
    features.collection.forEach((element) {
      GeoJsonPoint tmp = element.geometry;
//      LatLng point = tmp.geoPoint.toLatLng();
      Marker tmpdata = new Marker(
        point: tmp.geoPoint.toLatLng(),
        builder: (ctx) =>
            new Container(child: Image.asset('images/pin-icon-wpt.png')),
        width: 40.0,
        height: 40.0,
      );
      markersData.add(tmpdata);
    });
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
    if (_data.length >= 0) {
      _selectedChoice = _data.first;
    }
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2018, 11),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        //ここで選択された値を変数なり、コントローラーに代入する
        globals.targetDate = DateFormat('yyyyMMdd').format(selectedDate);
//        print('select date = ' + globals.targetDate);
      });
      _getRoute();
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
              _getRoute();
            }).toList();
          },
        ),
//        IconButton(
//            icon: Icon(Icons.account_box), onPressed: () => buildListView()),
        IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context)),
        IconButton(
            icon: Icon(Icons.watch_later), onPressed: () => _getRating()),
        IconButton(
            icon: Icon(Icons.directions_walk), onPressed: () => _getRoute()),
        IconButton(
            icon: Icon(Icons.location_on), onPressed: () => _getMarker()),
      ],
    );
  }

  Widget _mapView(BuildContext context) {
    return new FlutterMap(
      mapController: mapController,
      options: new MapOptions(
        center: new LatLng(35.000081, 137.004055),
        zoom: 17.0,
      ),
      layers: [
        new TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c']
//          urlTemplate: "https://api.tiles.mapbox.com/v4/"
//              "{id}/{z}/{x}/{y}@2x.png?access_token={accessToken}",
//          additionalOptions: {
//            'accessToken':
//                'pk.eyJ1IjoieWlzaWthd2EiLCJhIjoiY2s2YndmdXFuMGZ1bDNsb3ZnMXBsbnI3eSJ9.gftC8NPsB9xNWIVEdWnTvw',
//            'id': 'mapbox.streets',
//          },
            ),
        new PolylineLayerOptions(
          polylines: [
            Polyline(points: points, strokeWidth: 10.0, color: Colors.red),
          ],
        ),
        new MarkerLayerOptions(
          markers: markersData,
        ),
      ],
    );
  }
}
