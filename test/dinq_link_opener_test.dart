import 'package:dinq_app/services/domain_service.dart';
import 'package:dinq_app/utils/dinq_link_opener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainResolveType / DomainResolveResult', () {
    test('parses known types', () {
      expect(
        DomainResolveType.fromString('personal'),
        DomainResolveType.personal,
      );
      expect(
        DomainResolveType.fromString('organization'),
        DomainResolveType.organization,
      );
      expect(DomainResolveType.fromString('system'), DomainResolveType.system);
      expect(
        DomainResolveType.fromString('unknown'),
        DomainResolveType.unknown,
      );
      expect(DomainResolveType.fromString('weird'), DomainResolveType.unknown);
    });

    test('fromJson maps payload', () {
      final result = DomainResolveResult.fromJson({
        'type': 'organization',
        'domain': 'https://dinq.me/kathy-running',
      });
      expect(result.type, DomainResolveType.organization);
      expect(result.domain, 'https://dinq.me/kathy-running');
      expect(result.type.isInAppProfile, isTrue);
    });
  });

  group('extractDinqSlug', () {
    test('supports full url, host path and relative path', () {
      expect(
        extractDinqSlug('https://dinq.me/kathy-running'),
        'kathy-running',
      );
      expect(extractDinqSlug('dinq.me/alice'), 'alice');
      expect(extractDinqSlug('/bob'), 'bob');
      expect(extractDinqSlug('https://dinq.me/organization/x'), 'organization');
      expect(extractDinqSlug('https://dinq.me/'), isNull);
      expect(extractDinqSlug(''), isNull);
    });
  });

  group('decideInboxLinkTarget', () {
    test('personal → in-app profile slug from corrected domain', () {
      final target = decideInboxLinkTarget(
        originalUrl: 'https://dinq.me/alice',
        result: const DomainResolveResult(
          type: DomainResolveType.personal,
          domain: 'https://dinq.me/alice',
        ),
      );
      expect(target.kind, InboxLinkTargetKind.personal);
      expect(target.value, 'alice');
    });

    test('organization corrects /organization/{slug} domain', () {
      final target = decideInboxLinkTarget(
        originalUrl: 'https://dinq.me/organization/kathy-running',
        result: const DomainResolveResult(
          type: DomainResolveType.organization,
          domain: 'https://dinq.me/kathy-running',
        ),
      );
      expect(target.kind, InboxLinkTargetKind.organization);
      expect(target.value, 'kathy-running');
    });

    test('system / unknown / null result → external', () {
      expect(
        decideInboxLinkTarget(
          originalUrl: 'https://dinq.me/pricing',
          result: const DomainResolveResult(
            type: DomainResolveType.system,
            domain: 'https://dinq.me/pricing',
          ),
        ).kind,
        InboxLinkTargetKind.external,
      );
      expect(
        decideInboxLinkTarget(
          originalUrl: 'https://example.com',
          result: const DomainResolveResult(
            type: DomainResolveType.unknown,
            domain: 'https://example.com',
          ),
        ).kind,
        InboxLinkTargetKind.external,
      );
      expect(
        decideInboxLinkTarget(
          originalUrl: 'https://dinq.me/alice',
          result: null,
        ).kind,
        InboxLinkTargetKind.external,
      );
    });
  });
}
