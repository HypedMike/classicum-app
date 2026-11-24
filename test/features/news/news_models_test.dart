import 'package:flutter_test/flutter_test.dart';
import 'package:classicum_admin/features/news/data/news_item.dart';

void main() {
  test('news images are sorted and the main one is picked', () {
    final n = NewsItem.fromJson({
      'id': '1',
      'title': 't',
      'content': 'c',
      'createdAt': '2026-01-01T00:00:00Z',
      'newsImages': [
        {'fileId': 'b', 'isMain': true, 'order': 1},
        {'fileId': 'a', 'isMain': false, 'order': 0},
      ],
    });
    expect(n.images.map((i) => i.fileId), ['a', 'b']);
    expect(n.mainImageId, 'b');
  });

  test('news without images has no main image', () {
    final n = NewsItem.fromJson({
      'id': '1',
      'title': 't',
      'content': 'c',
      'createdAt': '2026-01-01T00:00:00Z',
    });
    expect(n.mainImageId, isNull);
  });
}
