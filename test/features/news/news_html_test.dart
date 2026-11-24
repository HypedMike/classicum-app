import 'package:flutter_test/flutter_test.dart';
import 'package:classicum_admin/features/news/presentation/news_screens.dart';
import 'package:classicum_admin/core/ui/widgets.dart';

void main() {
  test('stripHtml turns paragraphs into text', () {
    expect(stripHtml('<p>Uno &amp; due</p><p>Tre</p>'), 'Uno & due\nTre');
  });

  test('toHtml wraps paragraphs and escapes markup', () {
    expect(
      NewsHtml.toHtml('Uno <b>\nsegue\n\nDue'),
      '<p>Uno &lt;b&gt;<br>segue</p><p>Due</p>',
    );
  });
}
