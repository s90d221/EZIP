import 'package:dio/dio.dart';
import 'package:ezip/models/listing.dart';
import 'package:ezip/models/review.dart';

class ApiClient {
  final Dio _dio;

  // baseUrl 끝에 / 강제
  static String _ensureTrailingSlash(String url) =>
      url.endsWith('/') ? url : '$url/';

  ApiClient(String baseUrl)
      : _dio = Dio(BaseOptions(
    // ✅ 예: https://api.ezip.kro.kr/api/v1/
    baseUrl: _ensureTrailingSlash(baseUrl),
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 12),
    headers: {'Content-Type': 'application/json'},
    followRedirects: false,
    validateStatus: (s) => s != null && (s < 400 || (s >= 300 && s < 400)),
  )) {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      requestHeader: false,
      responseHeader: true,
    ));
    // 디버깅용
    // // ignore: avoid_print
    // print('[ApiClient] baseUrl=${_dio.options.baseUrl}');
  }

  // 쿼리 합치기
  Uri _withQuery(Uri base, Map<String, dynamic>? query) {
    if (query == null || query.isEmpty) return base;
    final merged = <String, String>{...base.queryParameters};
    query.forEach((k, v) { if (v != null) merged[k] = '$v'; });
    return base.replace(queryParameters: merged);
  }

  // 3xx 추종 + 경로 보정(선행 슬래시 제거)
  Future<Response<dynamic>> _req(
      String method,
      String pathOrUrl, {
        Map<String, dynamic>? query,
        dynamic data,
      }) async {
    final base = Uri.parse(_dio.options.baseUrl);

    // 절대 URL 여부
    final isAbs = RegExp(r'^[a-z][a-z0-9+\-.]*://', caseSensitive: false)
        .hasMatch(pathOrUrl);

    // 상대경로면 선행 '/' 제거해서 루트로 안 튀게 하기
    final normalized = isAbs
        ? pathOrUrl
        : (pathOrUrl.startsWith('/') ? pathOrUrl.substring(1) : pathOrUrl);

    Uri uri = isAbs ? Uri.parse(pathOrUrl) : base.resolve(normalized);
    uri = _withQuery(uri, query);

    for (int hop = 0; hop < 5; hop++) {
      // // ignore: avoid_print
      // print('[REQ] $method $uri');
      final res = await _dio.requestUri(uri, data: data, options: Options(method: method));
      final code = res.statusCode ?? 0;

      if (code >= 300 && code < 400) {
        final loc = res.headers.value('location');
        if (loc == null) throw Exception('Redirect($code) but no Location header from $uri');
        var nextUri = Uri.parse(loc);
        if (!nextUri.hasScheme) nextUri = uri.resolveUri(nextUri);
        if (nextUri.query.isEmpty) nextUri = _withQuery(nextUri, query);
        uri = nextUri;
        continue;
      }
      return res; // 2xx or 기타
    }
    throw Exception('Too many redirects (>=5) from $uri');
  }

  // -------- Room --------
  Future<List<Listing>> getRooms({Map<String, dynamic>? query}) async {
    final res = await _req('GET', 'rooms', query: _clean(query)); // ✅ no leading slash
    final data = _extractList(res.data);
    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  Future<List<Listing>> searchRooms(Map<String, dynamic> filters) async {
    final res = await _req('GET', 'rooms/search', query: _clean(filters)); // ✅
    final data = _extractList(res.data);
    return data.map<Listing>((e) => Listing.fromJson(e)).toList();
  }

  Future<Listing> getRoomDetail(int roomId) async {
    final res = await _req('GET', 'rooms/$roomId'); // ✅
    return Listing.fromJson(res.data);
  }

  Future<Listing> createRoom(Map<String, dynamic> body) async {
    final res = await _req('POST', 'rooms', data: _compatRoomBody(body)); // ✅
    return Listing.fromJson(res.data);
  }

  Future<void> updateRoom(int roomId, Map<String, dynamic> body) async {
    await _req('PUT', 'rooms/$roomId', data: _compatRoomBody(body)); // ✅
  }

  Future<void> deleteRoom(int roomId) async {
    await _req('DELETE', 'rooms/$roomId'); // ✅
  }

  // -------- Review --------
  Future<List<Review>> getReviews({Map<String, dynamic>? query}) async {
    final res = await _req('GET', 'reviews', query: _clean(query)); // ✅
    final data = _extractList(res.data);
    return data.map<Review>((e) => Review.fromJson(e)).toList();
  }

  Future<Review> createReview(Review review) async {
    final res = await _req('POST', 'reviews', data: _compatReviewBody(review.toJson())); // ✅
    return Review.fromJson(res.data);
  }

  Future<void> updateReview(int reviewId, Map<String, dynamic> body) async {
    await _req('PUT', 'reviews/$reviewId', data: _compatReviewBody(body)); // ✅
  }

  Future<void> deleteReview(int reviewId) async {
    await _req('DELETE', 'reviews/$reviewId'); // ✅
  }

  // -------- Chat (optional) --------
  Future<Response> chat(Map<String, dynamic> body) =>
      _req('POST', 'chat', data: body); // ✅
  Future<Response> chatTranslate(Map<String, dynamic> body) =>
      _req('POST', 'chat/translate', data: body); // ✅

  // ===== Helpers =====
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['items'] is List) return data['items'] as List;
    return const [];
  }

  Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    final m = Map<String, dynamic>.from(q);
    m.removeWhere((_, v) => v == null || (v is String && v.isEmpty));
    return m;
  }

  Map<String, dynamic> _compatRoomBody(Map<String, dynamic> b) {
    String? s(v) => v?.toString();
    return {
      'type': b['type'],
      'monthly': b['monthly'],
      'deposit': b['deposit'],
      'area': b['area'],
      'floor': b['floor'],
      'tags': b['tags'],
      'maintenanceFee': s(b['maintenanceFee']),
      'maintenance_fee': s(b['maintenanceFee']),
      'shortTitle': b['shortTitle'],
      'title': b['shortTitle'],
      'lat': b['lat'],
      'latitude': b['lat'],
      'lng': b['lng'],
      'longitude': b['lng'],
      'imageUrl': b['imageUrl'],
      'image_url': b['imageUrl'],
    };
  }

  Map<String, dynamic> _compatReviewBody(Map<String, dynamic> b) => {
    'id': b['id'],
    'roomId': b['roomId'] ?? b['room_id'],
    'room_id': b['roomId'] ?? b['room_id'],
    'author': b['author'] ?? b['name'],
    'name': b['author'] ?? b['name'],
    'content': b['content'] ?? b['text'],
    'text': b['content'] ?? b['text'],
  };
}
