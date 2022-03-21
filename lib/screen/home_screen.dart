import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool attendanceCheckDone = false;

  // 생성이 된 다음 정의 할 수 있기 때문에 ? 사용
  GoogleMapController? mapController;

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
      body: FutureBuilder<String>(
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
                        circle: attendanceCheckDone
                            ? checkDoneCircle
                            : isWithinRange
                            ? inDistanceCircle
                            : notInDistanceCircle,
                        marker: marker,
                        onMapCreated: onMapCreated,
                      ),
                      _AttendanceButton(
                        isWithinRange: isWithinRange,
                        onPressed: onAttendancePressed,
                        attendanceCheckDone: attendanceCheckDone,
                      ),
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

  Future<String> checkPermission() async {
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
      actions: [
        IconButton(
          onPressed: () async {
            if (mapController == null) {
              return; //맵 컨트롤러가 생성이 되지 않았을 경우
            }

            final location = await Geolocator.getCurrentPosition();

            mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(
                  location.latitude,
                  location.longitude,
                ),
              ),
            );
          },
          color: Colors.blue,
          icon: Icon(
            Icons.my_location,
          ),
        )
      ],
    );
  }

  onAttendancePressed() async {
    final result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('출근하기'),
            content: Text('출근 체크를 하시겠습니까?'),
            actions: [
              // 취소 버튼
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('확인'),
              ),
            ],
          );
        });

    if (result) {
      setState(() {
        attendanceCheckDone = true;
      });
    }
  }

  onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPositon;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated;

  const _CustomGoogleMap({
    Key? key,
    required this.initialPositon,
    required this.circle,
    required this.marker,
    required this.onMapCreated,
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
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool attendanceCheckDone;

  const _AttendanceButton({
    Key? key,
    required this.isWithinRange,
    required this.onPressed,
    required this.attendanceCheckDone,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 50.0,
            color: attendanceCheckDone
                ? Colors.green
                : isWithinRange
                ? Colors.blue
                : Colors.red,
          ),
          const SizedBox(
            height: 20,
          ),
          if (!attendanceCheckDone && isWithinRange)
            TextButton(
              onPressed: onPressed,
              child: Text('출근하기'),
            ),
        ],
      ),
    );
  }
}
