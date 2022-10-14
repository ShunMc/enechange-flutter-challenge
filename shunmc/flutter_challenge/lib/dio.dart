import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final dioProvider = StateProvider(
  (ref) => Dio(BaseOptions(baseUrl: 'https://stg.evene.jp/')),
);
