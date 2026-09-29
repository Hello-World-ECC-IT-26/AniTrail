import 'package:anitrail/features/navigation/models/navigation_direction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  group('navigationDirectionAlignment', () {
    test('端末の向きがルート方向から20度以内なら一致', () {
      expect(
        navigationDirectionAlignment(
          routeBearingDegrees: 15,
          deviceHeadingDegrees: 355,
        ),
        NavigationDirectionAlignment.aligned,
      );
    });

    test('0度をまたぐ角度差を短い側で判定', () {
      expect(angularDifferenceDegrees(5, 355), 10);
      expect(
        navigationDirectionAlignment(
          routeBearingDegrees: 5,
          deviceHeadingDegrees: 355,
        ),
        NavigationDirectionAlignment.aligned,
      );
    });

    test('徒歩ルート矢印と直線方向ピンは別々の相対角を保つ', () {
      final routeDirection = relativeDirectionDegrees(
        bearingDegrees: 45,
        deviceHeadingDegrees: 10,
      );
      final destinationDirection = relativeDirectionDegrees(
        bearingDegrees: 100,
        deviceHeadingDegrees: 10,
      );

      expect(routeDirection, 35);
      expect(destinationDirection, 90);
    });

    test('20度を超えると不一致', () {
      expect(
        navigationDirectionAlignment(
          routeBearingDegrees: 21,
          deviceHeadingDegrees: 0,
        ),
        NavigationDirectionAlignment.misaligned,
      );
    });

    test('角度を得られない時は判定不能', () {
      expect(
        navigationDirectionAlignment(
          routeBearingDegrees: null,
          deviceHeadingDegrees: 0,
        ),
        NavigationDirectionAlignment.unavailable,
      );
    });
  });

  group('walkingRouteBearingAtLocation', () {
    const route = [
      LatLng(35, 139),
      LatLng(35.001, 139),
      LatLng(35.001, 139.001),
    ];

    test('現在地に近い徒歩ルート区間の進行方向を返す', () {
      final bearing = walkingRouteBearingAtLocation(
        currentLocation: const LatLng(35.0005, 139),
        routePoints: route,
      );

      expect(bearing, isNotNull);
      expect(angularDifferenceDegrees(bearing!, 0), lessThan(1));
    });

    test('曲がり角では次の区間の方向を返す', () {
      final bearing = walkingRouteBearingAtLocation(
        currentLocation: route[1],
        routePoints: route,
      );

      expect(bearing, isNotNull);
      expect(angularDifferenceDegrees(bearing!, 90), lessThan(1));
    });

    test('有効なルート区間がなければnullを返す', () {
      expect(
        walkingRouteBearingAtLocation(
          currentLocation: route.first,
          routePoints: const [],
        ),
        isNull,
      );
    });
  });
}
