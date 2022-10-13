import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_challenge/location_utility.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:openapi/openapi.dart';

final chargerSpotsRepositoryProvider = Provider(
  (ref) {
    final dio = Dio(BaseOptions(baseUrl: 'https://stg.evene.jp/'));
    return ChargerSpotsRepository(dio);
  },
);

final examplePositionProvider = Provider(
  (ref) => LatLngBounds(
    southwest: const LatLng(35.683331703634124, 139.7657155055581),
    northeast: const LatLng(35.686849507072736, 139.77340835691592),
  ),
);

final currentPositionProvider = FutureProvider(
  (ref) async {
    try {
      final center = await LocationUtility.determinePosition();
      final diff = 256 / pow(2, 16);
      return LatLngBounds(
        southwest: LatLng(
          center.latitude - diff,
          center.longitude - diff,
        ),
        northeast: LatLng(
          center.latitude + diff,
          center.longitude + diff,
        ),
      );
    } catch (e) {
      return ref.read(examplePositionProvider);
    }
  },
);

final positionProvider = StateProvider<LatLngBounds?>((ref) => null);

final chargerSpotsProvider = FutureProvider(
  (ref) async {
    final repository = ref.read(chargerSpotsRepositoryProvider);
    var position = ref.watch(positionProvider);
    if (position != null) {
      return repository.getChargerSpots(position);
    }

    position = await ref.read(currentPositionProvider.future);
    final chargerSpots = await repository.getChargerSpots(position!);
    if (chargerSpots?.isNotEmpty ?? false) {
      return chargerSpots;
    }
    return await repository.getChargerSpots(ref.read(examplePositionProvider));
  },
);

class ChargerSpotsRepository {
  ChargerSpotsRepository(this.dio);

  final Dio dio;

  Future<Iterable<ChargerSpot>?> getChargerSpots(LatLngBounds bounds) async {
    final openApi = Openapi(dio: dio);
    final repository = openApi.getChargerSpotsApi();
    final response = await repository.chargerSpots(
      X_EVENE_NATIVE_API_TOKEN: const String.fromEnvironment('API_TOKEN'),
      swLat: bounds.southwest.latitude.toString(),
      swLng: bounds.southwest.longitude.toString(),
      neLat: bounds.northeast.latitude.toString(),
      neLng: bounds.northeast.longitude.toString(),
    );
    return response.data?.chargerSpots;
  }
}
