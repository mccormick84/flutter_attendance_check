import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final LatLng companyLatLng = LatLng(
    37.5233373,
    126.921252,
  );
  static final CameraPosition initialPositon = CameraPosition(
    target: companyLatLng,
    zoom: 15,
  );

  static final double okDistance = 100;

  static final Circle inDistanceCircle = Circle(
    circleId: CircleId('inDistanceCircle'),
    center: companyLatLng,
    strokeColor: Colors.blue.withOpacity(0.5),
    fillColor: Colors.blue.withOpacity(0.5),
    strokeWidth: 1,
    radius: okDistance,
  );

  static final Circle notInDistanceCircle = Circle(
    circleId: CircleId('notInDistanceCircle'),
    center: companyLatLng,
    strokeColor: Colors.red.withOpacity(0.5),
    fillColor: Colors.red.withOpacity(0.5),
    strokeWidth: 1,
    radius: okDistance,
  );

  static final Circle checkDoneCircle = Circle(
    circleId: CircleId('checkDoneCircle'),
    center: companyLatLng,
    strokeColor: Colors.green.withOpacity(0.5),
    fillColor: Colors.green.withOpacity(0.5),
    strokeWidth: 1,
    radius: okDistance,
  );

  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder(
        //future의 상태가 변경될 때 마다 빌드
        future: checkPermission(),
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data == '위치 정보 사용이 허가 되었습니다.') {
            return StreamBuilder<Position>(
                stream: Geolocator.getPositionStream(),
                builder: (context, snapshot) {
                  bool isWithinRange = false;

                  if (snapshot.hasData) {
                    final start = snapshot.data!;
                    final end = companyLatLng;

                    final distance = Geolocator.distanceBetween(
                      start.latitude,
                      start.longitude,
                      end.latitude,
                      end.longitude,
                    );

                    if (distance < okDistance) {
                      isWithinRange = true;
                    }
                  }
                  return Column(
                    children: [
                      _CustomGoogleMap(
                        initialPositon: initialPositon,
                        circle: isWithinRange
                            ? inDistanceCircle
                            : notInDistanceCircle,
                        marker: marker,
                      ),
                      _AttendanceButton(),
                    ],
                  );
                });
          }

          return Center(
            child: Text(snapshot.data),
          );
        },
      ),
    );
  }

  checkPermission() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationEnabled) {
      return '위치 서비스를 활성화 해주세요.';
    }

    LocationPermission checkedPermission = await Geolocator.checkPermission();

    if (checkedPermission == LocationPermission.denied) {
      checkedPermission = await Geolocator.requestPermission();

      if (checkedPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요.';
      }
    }

    if (checkedPermission == LocationPermission.deniedForever) {
      return '위치 서비스 권한을 사용할 수 있도록 설정해주세요.';
    }

    return '위치 정보 사용이 허가 되었습니다.';
  }

  AppBar renderAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      title: const Text(
        '오늘도 출근',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPositon;
  final Circle circle;
  final Marker marker;

  const _CustomGoogleMap({
    Key? key,
    required this.initialPositon,
    required this.circle,
    required this.marker,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        initialCameraPosition: initialPositon,
        mapType: MapType.normal,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: Set.from([circle]),
        markers: Set.from([marker]),
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  const _AttendanceButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text('출근'),
    );
  }
}
