class Review {
  final int id;
  final int roomId;
  final String author;
  final String content;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.roomId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: (j['id'] ?? j['reviewId']) as int,
    roomId: (j['roomId'] ?? j['room_id']) as int,
    author: (j['author'] ?? j['name'] ?? '익명').toString(),
    content: (j['content'] ?? j['text'] ?? '').toString(),
    createdAt: DateTime.tryParse(j['createdAt'] ?? j['created_at'] ?? '') ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'author': author,
    'content': content,
  };
}
