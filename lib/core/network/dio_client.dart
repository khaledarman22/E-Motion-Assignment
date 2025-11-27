import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/app_constants.dart';
import 'error_interceptor.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  @preResolve
  Future<CacheOptions> getCacheOptions() async {
    final dir = await getTemporaryDirectory();
    return CacheOptions(
      store: HiveCacheStore('${dir.path}/${AppConstants.cacheBoxName}'),
      policy: CachePolicy.forceCache,
      maxStale: const Duration(minutes: 30),
      priority: CachePriority.high,
      hitCacheOnErrorExcept: [
        400,
        401,
        403,
        404,
        405,
        409,
        410,
        412,
        413,
        415,
        422,
        429,
        500,
        502,
        503,
        504,
        505,
      ],
      allowPostMethod: false,
    );
  }

  @lazySingleton
  Dio dio(CacheOptions cacheOptions) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        queryParameters: {'appid': AppConstants.apiKey, 'units': 'metric'},
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    dio.interceptors.addAll([
      DioCacheInterceptor(options: cacheOptions),
      ErrorInterceptor(),
      if (kDebugMode)
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
    ]);

    return dio;
  }
}
