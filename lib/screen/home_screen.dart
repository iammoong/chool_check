import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // latitude - 위도, longitude - 경도
  static final LatLng companyLatLng = LatLng(37.5232735666, 126.921079159);
  static final CameraPosition initialPosition =
      CameraPosition(target: companyLatLng, zoom: 15);

  // 동그라미 거리를 위한 변수 (단위 m)
  static final double okDistance = 100;
  
  // 원안에 도착했을 때
  static final Circle withinDistanceCircle = Circle(
    circleId: CircleId('withinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.blue,
    strokeWidth: 1,
  );

  // 원 밖에 있을 때
  static final Circle notWithinDistanceCircle = Circle(
    circleId: CircleId('notWithinDistanceCircle'),
    center: companyLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,
    strokeWidth: 1,
  );

  static final Circle checkDoneCircle = Circle(
    circleId: CircleId('checkDoneCircle'),
    center: companyLatLng,
    fillColor: Colors.green.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.green,
    strokeWidth: 1,
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
        future: checkPermission(),
        builder: (BuildContext context, AsyncSnapshot snapshot){
          if(snapshot.connectionState == ConnectionState.waiting){
            return Center
              (child : CircularProgressIndicator(),
            );
          }

          if(snapshot.data == '위치 권한이 허가 되었습니다.'){
            return StreamBuilder<Position>(
              stream: Geolocator.getPositionStream(),
              builder: (context, snapshot) {
                //현재 핸드폰 위치가 원 안에 있는지 없는지
                bool isWithinRange = false;

                if(snapshot.hasData) {
                  // 현재 내 위치
                  final start = snapshot.data!;
                  // 회사 위치
                  final end = companyLatLng;
                  // 현재 위치와 회사 위치 계산
                  final distance = Geolocator.distanceBetween(
                      start.latitude,
                      start.longitude,
                      end.latitude,
                      end.longitude,
                  );

                  if(distance < okDistance) {
                    isWithinRange = true;
                  }
                  
                }

                return Column(
                  children: [
                    _CustomGoogleMap(
                      initialPosition: initialPosition,
                      circle: isWithinRange
                          ? withinDistanceCircle
                          : notWithinDistanceCircle,
                      marker : marker,
                    ),
                    _CoolCheckButton(),
                  ],
                );
              }
            );
          }
          return Center(
            child: Text(
              snapshot.data
            ),
          );
        },
      ),
    );
  }

  Future<String> checkPermission() async {
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();

    if(!isLocationEnabled) {
      return '위치 서비스를 활성화하세요.';
    }

    // 현재 앱이 가지고 있는 위치 서비스 권한
    LocationPermission checkedPermission = await Geolocator.checkPermission();

    // 위치 서비스 권한을 사용할 것인지 묻는 창이 나옴(디폴트 값)
    if(checkedPermission == LocationPermission.denied) {
      checkedPermission = await Geolocator.requestPermission();
      if(checkedPermission == LocationPermission.denied){
        return '위치 권한을 허가해주세요.';
      }

      if(checkedPermission == LocationPermission.deniedForever) {
        return '앱의 위치 권한을 세팅해서 허가해주세요.';
      }
    }

    return '위치 권한이 허가 되었습니다.';
  }

  AppBar renderAppBar() {
    return AppBar(
      title: Text(
        '오늘도 출근',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;
  const _CustomGoogleMap({
    required this.initialPosition,
    required this.circle,
    required this.marker,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.terrain,
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: Set.from([circle]),
        markers: Set.from([marker]),
      ),
    );
  }
}

class _CoolCheckButton extends StatelessWidget {
  const _CoolCheckButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Expanded(
      child: Text('출근'),
    );
  }
}
