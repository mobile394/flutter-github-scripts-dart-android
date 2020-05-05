import 'package:test/test.dart';
import 'package:flutter_github_scripts/github_queries.dart';
import 'dart:convert';

void main() {
  void main() {
  group('DateRange', () {

    test('at', () {
      var when = DateTime.now();
      var at = DateRange(DateRangeType.at, at: when);
      expect(at.at == when, true);
      expect(at.type == DateRangeType.at, true);
      expect(at.start == null, true);
      expect(at.end == null, true);
    });
    test('range', () {
      var now = DateTime.now();
      var then = now.add(Duration(days: 2));
      var range = DateRange(DateRangeType.range, start: now, end: then);
      expect(range.at == null, true);
      expect(range.type == DateRangeType.range, true);
      expect(range.start == now, true);
      expect(range.end == then, true);
    });
  });

}
