import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dinq_app/pages/me/organization_page.dart';
import 'package:dinq_app/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> org(String name, String slug, {String role = ''}) => {
      'id': 'id-$slug',
      'slug': slug,
      'name': name,
      'logo_url': '',
      'background_url': '',
      'org_type': 'company',
      'description': '',
      'tags': <String>[],
      'location': '',
      'member_count': 2,
      if (role.isNotEmpty) 'role': role,
    };

class FakeAdapter implements HttpClientAdapter {
  final List<String> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.path}?${options.uri.query}');
    Map<String, dynamic> data;
    if (options.path == '/org/my') {
      data = {
        'organizations': [org('My Own Org', 'own', role: 'owner')],
      };
    } else if (options.path == '/orgs') {
      final kw = options.queryParameters['keyword']?.toString() ?? '';
      if (kw.isEmpty) {
        data = {
          'organizations': [org('DINQ LABS', 'dinq')],
          'total': 1,
        };
      } else if (kw == 'dinq') {
        data = {
          'organizations': [
            org('DINQ LABS', 'dinq'),
            org('DINQ Labs', 'dinq2'),
            org('DINQ Family', 'dinq3'),
            org('DINQ Home', 'dinq4'),
          ],
          'total': 4,
        };
      } else {
        data = {'organizations': <dynamic>[], 'total': 0};
      }
    } else {
      data = {};
    }
    return ResponseBody.fromString(
      jsonEncode({'code': 0, 'data': data, 'message': 'success'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late FakeAdapter adapter;

  setUp(() {
    adapter = FakeAdapter();
    ApiClient.instance.dio.httpClientAdapter = adapter;
  });

  testWidgets('keyword search shows matching orgs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrganizationPage()));
    await tester.pumpAndSettle();

    expect(find.text('DINQ LABS'), findsOneWidget);
    expect(find.text('My Own Org'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dinq');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('REQUESTS: ${adapter.requests}');
    expect(find.text('DINQ Family'), findsOneWidget, reason: 'search results');
    expect(find.text('DINQ Home'), findsOneWidget, reason: 'search results');
  });

  testWidgets('no-match keyword shows empty placeholder', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrganizationPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('REQUESTS: ${adapter.requests}');
    expect(find.text('No organizations found.'), findsOneWidget);
  });

  testWidgets(
      'QA scenario: keyword matching only my/pending orgs still shows them',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OrganizationPage()));
    await tester.pumpAndSettle();

    // "own" 只命中自己已加入的 My Own Org（服务端返回它，但被
    // Recommended 三分区排除）；修复后 My Organization 分区被关键词
    // 过滤，仍展示命中的组织，且不显示 No organizations found。
    await tester.enterText(find.byType(TextField), 'own');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('My Own Org'), findsOneWidget);
    expect(find.text('No organizations found.'), findsNothing);
    expect(find.text('Recommended'), findsNothing);

    // 换成不匹配任何分区的词 → My 分区隐藏 + 空占位
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('My Own Org'), findsNothing);
    expect(find.text('No organizations found.'), findsOneWidget);
  });
}
