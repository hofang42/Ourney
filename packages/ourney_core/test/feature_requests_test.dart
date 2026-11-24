import 'package:ourney_core/ourney_core.dart';
import 'package:test/test.dart';

void main() {
  group('FeatureRequest validation', () {
    test('valid Vietnamese and English titles', () {
      expect(
        validateFeatureRequestTitle('Widget chuỗi ngày ngoài màn hình khóa'),
        isNull,
      );
      expect(validateFeatureRequestTitle('Lock-screen streak widget'), isNull);
      expect(validateFeatureRequestTitle('123456'), isNull);
      expect(validateFeatureRequestTitle('a' * 80), isNull);
    });

    test('title length bounds after trim', () {
      expect(
        validateFeatureRequestTitle('  abc  '),
        FeatureRequestTitleError.tooShort,
      );
      expect(
        validateFeatureRequestTitle('a' * 81),
        FeatureRequestTitleError.tooLong,
      );
    });

    test('title rejects external links', () {
      expect(
        validateFeatureRequestTitle('Check https://spam.example.com now'),
        FeatureRequestTitleError.linksNotAllowed,
      );
      expect(
        validateFeatureRequestTitle('Visit www.example-site.vn today'),
        FeatureRequestTitleError.linksNotAllowed,
      );
      expect(
        validateFeatureRequestTitle('Open scam.xyz/free-coins'),
        FeatureRequestTitleError.linksNotAllowed,
      );
    });

    test('body length bounds and link rejection', () {
      expect(
        validateFeatureRequestBody('Ngắn quá'),
        FeatureRequestBodyError.tooShort,
      );
      expect(
        validateFeatureRequestBody(
          'Giúp mình xem nhanh chuỗi ngày ngay trên màn hình khóa mỗi sáng.',
        ),
        isNull,
      );
      expect(validateFeatureRequestBody('a' * 1000), isNull);
      expect(
        validateFeatureRequestBody('a' * 1001),
        FeatureRequestBodyError.tooLong,
      );
      expect(
        validateFeatureRequestBody('Xem thêm tại http://phishing.io/login nhé'),
        FeatureRequestBodyError.linksNotAllowed,
      );
    });
  });

  group('foldVietnameseDiacritics', () {
    test('folds accented Vietnamese to lowercase ASCII', () {
      expect(
        foldVietnameseDiacritics('Chế độ tối cho buổi sáng & Đếm cân nặng'),
        'che do toi cho buoi sang & dem can nang',
      );
      expect(
        foldVietnameseDiacritics('Widget màn hình khóa'),
        'widget man hinh khoa',
      );
    });
  });

  group('FeatureRequest JSON & lifecycle flags', () {
    test('round-trips JSON and computes canVote / canAuthorModify', () {
      final json = <String, dynamic>{
        'id': 'req-1',
        'title': 'Widget chuỗi ngày ngoài màn hình khóa',
        'body': 'Xem nhanh chuỗi ngày mà không cần mở khóa điện thoại.',
        'category': 'design',
        'status': 'new',
        'vote_count': 12,
        'voted_by_me': true,
        'is_mine': true,
        'author': {
          'user_id': 'u-1',
          'username': 'minh_anh',
          'display_name': 'Minh Anh',
        },
        'admin_reply': null,
        'admin_replied_at': null,
        'shipped_at': null,
        'duplicate_of': null,
        'canonical_title': null,
        'created_at': '2026-11-20T08:00:00Z',
        'updated_at': '2026-11-20T08:00:00Z',
      };

      final item = FeatureRequest.fromJson(json);
      expect(item.id, 'req-1');
      expect(item.category, FeatureRequestCategory.design);
      expect(item.status, FeatureRequestStatus.newRequest);
      expect(item.voteCount, 12);
      expect(item.votedByMe, isTrue);
      expect(item.isMine, isTrue);
      expect(item.author?.username, 'minh_anh');
      expect(item.canVote, isTrue);
      expect(item.canAuthorModify, isTrue);
      expect(item.wasEdited, isFalse);

      final roundTripped = FeatureRequest.fromJson(item.toJson());
      expect(roundTripped.id, item.id);
      expect(roundTripped.title, item.title);
      expect(roundTripped.category, item.category);
      expect(roundTripped.status, item.status);
      expect(roundTripped.voteCount, item.voteCount);
      expect(roundTripped.author?.userId, 'u-1');
    });

    test('locks voting and author edits when shipped, declined, or merged', () {
      final base = FeatureRequest.fromJson(const {
        'id': 'req-2',
        'title': 'Hỗ trợ xuất lịch tháng',
        'body': 'Xuất ảnh tổng kết 30 ngày cho hành trình tối giản.',
        'category': 'sharing',
        'status': 'under_review',
        'vote_count': 5,
        'voted_by_me': false,
        'is_mine': true,
        'created_at': '2026-11-20T08:00:00Z',
        'updated_at': '2026-11-20T09:00:00Z',
      });
      expect(base.canVote, isTrue);
      expect(base.canAuthorModify, isFalse);

      final shipped = base.copyWith(status: FeatureRequestStatus.shipped);
      expect(shipped.isShipped, isTrue);
      expect(shipped.canVote, isFalse);

      final declined = base.copyWith(status: FeatureRequestStatus.declined);
      expect(declined.isDeclined, isTrue);
      expect(declined.canVote, isFalse);

      final merged = base.copyWith(
        status: FeatureRequestStatus.newRequest,
        duplicateOf: 'req-canonical',
      );
      expect(merged.isMerged, isTrue);
      expect(merged.canVote, isFalse);
      expect(merged.canAuthorModify, isFalse);
    });

    test('anonymizes deleted or nil-UUID author', () {
      final item = FeatureRequest.fromJson(const {
        'id': 'req-3',
        'title': 'Chế độ tiết kiệm pin cho máy ảnh',
        'body': 'Giảm tốc độ khung hình khi mở máy ảnh lâu.',
        'category': 'camera',
        'status': 'planned',
        'vote_count': 19,
        'voted_by_me': false,
        'is_mine': false,
        'author': {
          'user_id': '00000000-0000-0000-0000-000000000000',
          'username': '',
          'display_name': '',
        },
        'created_at': '2026-11-20T08:00:00Z',
      });
      expect(item.author, isNull);
      expect(item.authorUserId, isNull);
    });

    test('parses vote result and shipped notification payloads', () {
      final vote = FeatureRequestVoteResult.fromJson(const {
        'request_id': 'req-1',
        'vote_count': 42,
        'voted_by_me': true,
      });
      expect(vote.requestId, 'req-1');
      expect(vote.voteCount, 42);
      expect(vote.votedByMe, isTrue);

      final notif = ShippedRequestNotification.fromJson(const {
        'request_id': 'req-1',
        'title': 'Widget chuỗi ngày ngoài màn hình khóa',
        'category': 'design',
        'admin_reply': 'Đã có mặt trong bản cập nhật mới nhất!',
        'is_author': false,
        'shipped_at': '2026-11-24T06:00:00Z',
        'created_at': '2026-11-24T06:00:00Z',
        'seen': false,
      });
      expect(notif.requestId, 'req-1');
      expect(notif.category, FeatureRequestCategory.design);
      expect(notif.adminReply, 'Đã có mặt trong bản cập nhật mới nhất!');
      expect(notif.isAuthor, isFalse);
      expect(notif.seen, isFalse);
    });
  });

  group('Error codes & InboxCounts', () {
    test('maps content_policy, links_not_allowed, and missing RPCs', () {
      expect(
        OurneyErrorCode.fromServer(
          message: 'content_policy',
          sqlstate: '23514',
        ),
        OurneyErrorCode.contentPolicy,
      );
      expect(
        OurneyErrorCode.fromServer(
          message: 'links_not_allowed',
          sqlstate: '23514',
        ),
        OurneyErrorCode.linksNotAllowed,
      );
      expect(
        OurneyErrorCode.fromServer(
          message: 'Could not find the function public.list_feature_requests',
          sqlstate: 'PGRST202',
        ),
        OurneyErrorCode.serverOutdated,
      );
      expect(
        OurneyErrorCode.fromServer(
          message: 'Could not find the function public.list_feature_requests',
        ),
        OurneyErrorCode.serverOutdated,
      );
    });

    test('InboxCounts includes shippedRequests in hasDot', () {
      const empty = InboxCounts(
        friendRequests: 0,
        publicRequests: 0,
        newShares: 0,
        unreadMessages: 0,
        consentRequests: 0,
      );
      expect(empty.hasDot, isFalse);

      const withShipped = InboxCounts(
        friendRequests: 0,
        publicRequests: 0,
        newShares: 0,
        unreadMessages: 0,
        consentRequests: 0,
        shippedRequests: 1,
      );
      expect(withShipped.hasDot, isTrue);
    });
  });
}
