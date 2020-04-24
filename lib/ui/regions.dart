import 'dart:async';

import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

const double CAMERA_BEARING = 0;
const double CAMERA_TILT = 0;
const double CAMERA_ZOOM = 15;
const LatLng ROTTERDAM = LatLng(51.9244, 4.4777);

class Regions extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _RegionsState();
}

class _RegionsState extends State<Regions> {
  final _notificare = NotificarePushLib();
  final _mapsController = Completer<GoogleMapController>();
  final _location = Location();
  final _markers = Set<Marker>();
  final _polygons = Set<Polygon>();
  final _circles = Set<Circle>();

  BitmapDescriptor _markerIcon;
  BitmapDescriptor _userMarkerIcon;
  LocationData _currentLocation;

  @override
  void initState() {
    super.initState();

    _initialize();
  }

  @override
  Widget build(BuildContext context) {
    final initialLatitude = _currentLocation?.latitude ?? ROTTERDAM.latitude;
    final initialLongitude = _currentLocation?.longitude ?? ROTTERDAM.longitude;
    final initialCameraPosition = CameraPosition(
      target: LatLng(initialLatitude, initialLongitude),
      bearing: CAMERA_BEARING,
      tilt: CAMERA_TILT,
      zoom: CAMERA_ZOOM,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Regions'),
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        compassEnabled: true,
        rotateGesturesEnabled: true,
        scrollGesturesEnabled: true,
        tiltGesturesEnabled: true,
        zoomGesturesEnabled: true,
        initialCameraPosition: initialCameraPosition,
        markers: _markers,
        polygons: _polygons,
        circles: _circles,
        onMapCreated: (controller) {
          _mapsController.complete(controller);
          _loadRegions();
        },
      ),
    );
  }

  Future<void> _initialize() async {
    print('Initialize marker icons');
    _markerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/images/map_marker.png',
    );
    _userMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/images/user_location.png',
    );

    print('Load user\'s initial location.');
    await _setInitialLocation();
    _updateCurrentLocationMarker();

    print('Start listening to location updates.');
    _location.onLocationChanged.listen((location) {
      _currentLocation = location;
      _updateCurrentLocationMarker();
    });
  }

  Future<void> _loadRegions() async {
    final result = await _notificare.doCloudHostOperation(
      'GET',
      '/region',
      {'skip': '0', 'limit': '250'},
      null,
      null,
    );

    final markers = Set<Marker>();
    final polygons = Set<Polygon>();
    final circles = Set<Circle>();

    final regions = result['regions'] as List<dynamic>;
    regions.forEach((region) {
      final center = region['geometry']['coordinates'] as List;

      markers.add(Marker(
        markerId: MarkerId(region['_id']),
        position: LatLng(center[1], center[0]),
        icon: _markerIcon,
        infoWindow: InfoWindow(
          title: region['name'],
        ),
      ));

      if (region['advancedGeometry'] != null) {
        // Draw a polygon
        final coordinates =
            region['advancedGeometry']['coordinates'].first as List;

        polygons.add(Polygon(
          polygonId: PolygonId(region['_id']),
          points: coordinates.map((c) => LatLng(c[1], c[0])).toList(),
          fillColor: NotificareColors.outerSpace.withOpacity(0.5),
          strokeWidth: 0,
        ));
      } else {
        // Draw a circle
        circles.add(Circle(
          circleId: CircleId(region['_id']),
          center: LatLng(center[1], center[0]),
          radius: region['distance'] / 2.0,
          fillColor: NotificareColors.outerSpace.withOpacity(0.5),
          strokeWidth: 0,
        ));
      }
    });

    setState(() {
      _markers.removeWhere((m) => m.markerId.value != 'user_marker');
      _polygons.clear();
      _circles.clear();

      _markers.addAll(markers);
      _polygons.addAll(polygons);
      _circles.addAll(circles);
    });
  }

  Future<void> _setInitialLocation() async {
    _currentLocation = await _location.getLocation();

    final controller = await _mapsController.future;
    controller.moveCamera(CameraUpdate.newLatLng(
        LatLng(_currentLocation.latitude, _currentLocation.longitude)));
  }

  void _updateCurrentLocationMarker() {
    print('Updating user marker.');
    if (_currentLocation == null || !mounted) return;

    setState(() {
      _markers.removeWhere((m) => m.markerId.value == 'user_marker');
      _markers.add(Marker(
        markerId: MarkerId('user_marker'),
        icon: _userMarkerIcon,
        position: LatLng(_currentLocation.latitude, _currentLocation.longitude),
      ));
    });
  }
}
