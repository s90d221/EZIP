class Listing {
  final int id;
  final String type;          // '월세' or '전세'
  final int monthly;          // 월세 금액
  final int deposit;          // 보증금
  final double area;          // 면적(m2)
  final int floor;
  final String maintenanceFee; // 문자열로 보관(서버 int도 toString)
  final String shortTitle;    // 주소 등 간단 타이틀
  final double lat;
  final double lng;
  final String imageUrl;      // 대표 이미지
  final List<String> tags;    // 옵션/보안 등 태그

  Listing({
    required this.id,
    required this.type,
    required this.monthly,
    required this.deposit,
    required this.area,
    required this.floor,
    required this.maintenanceFee,
    required this.shortTitle,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    this.tags = const [],
  });

  String get priceLabel =>
      type == '월세' ? '월세 $monthly/보증금 $deposit' : '전세 $deposit';

  /// 서버 스키마(roomId/latitude/longitude/monthlyRent/images...)와
  /// 기존 데모 스키마(id/lat/lng/monthly/imageUrl...) 모두 지원
  factory Listing.fromJson(Map<String, dynamic> j) {
    // ---- 서버 스키마 감지 ----
    if (j.containsKey('roomId')) {
      final images = (j['images'] as List?) ?? const [];
      String firstImg = '';
      if (images.isNotEmpty && images.first is Map) {
        firstImg = (images.first as Map)['url']?.toString() ?? '';
      }

      final monthlyRentNum = (j['monthlyRent'] as num?) ?? 0;
      final areaM2 = (j['areaM2'] as num?)?.toDouble() ?? 0.0;

      return Listing(
        id: (j['roomId'] as num).toInt(),
        type: monthlyRentNum > 0 ? '월세' : '전세',
        monthly: monthlyRentNum.toInt(),
        deposit: (j['deposit'] as num?)?.toInt() ?? 0,
        area: areaM2,
        floor: (j['floor'] as num?)?.toInt() ?? 0,
        maintenanceFee: (j['maintenanceFee'] ?? '').toString(),
        shortTitle: (j['address'] as String?) ?? '주소 미상',
        lat: (j['latitude'] as num?)?.toDouble() ?? 0.0,
        lng: (j['longitude'] as num?)?.toDouble() ?? 0.0,
        imageUrl: firstImg,
        tags: _combineTags(j),
      );
    }

    // ---- 기존 데모 스키마(로컬 목업) ----
    return Listing(
      id: (j['id'] as num).toInt(),
      type: (j['type'] as String?) ?? '월세',
      monthly: (j['monthly'] as num?)?.toInt() ?? 0,
      deposit: (j['deposit'] as num?)?.toInt() ?? 0,
      area: (j['area'] as num?)?.toDouble() ?? 0.0,
      floor: (j['floor'] as num?)?.toInt() ?? 0,
      maintenanceFee: (j['maintenanceFee'] ?? '').toString(),
      shortTitle: (j['shortTitle'] as String?) ?? '제목 없음',
      lat: (j['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0.0,
      imageUrl: (j['imageUrl'] as String?) ?? '',
      tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  // 서버 응답의 roomType/options/securityFacilities를 태그로 합치기
  static List<String> _combineTags(Map<String, dynamic> j) {
    final tags = <String>[];

    final rt = j['roomType'] as String?;
    if (rt != null) tags.add(_roomTypeKo(rt));

    final opts = (j['options'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    tags.addAll(opts);

    final sec = (j['securityFacilities'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    tags.addAll(sec);

    return tags;
  }

  static String _roomTypeKo(String v) {
    switch (v) {
      case 'ONE_ROOM':
        return '원룸';
      case 'ONE_POINT_FIVE':
        return '1.5룸';
      case 'TWO_ROOM':
        return '투룸';
      case 'THREE_ROOM':
        return '쓰리룸';
      default:
        return v;
    }
  }
}