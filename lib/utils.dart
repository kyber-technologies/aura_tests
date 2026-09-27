import 'dart:math';

import 'package:aura_dart/chat.dart' as ch;
import 'package:aura_dart/common.dart';
import 'package:aura_dart/posting.dart' as ps;
import 'package:aura_dart/resource.dart' as res;
import 'package:aura_dart/user.dart' as us;
import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

final res.ResourceId defaultIconResource = res.ResourceId(
  namespace: res.ResourceNamespace(aura: Empty()),
  key: 'default_icon.png',
);

CallOptions authOptions(String token) =>
    CallOptions(metadata: <String, String>{'Authorization': token});

void assertList<T>(List<T> a, List<T> b) {
  final bool sameLength = a.length == b.length;
  final bool equalContent =
      sameLength && a.indexed.every(((int, T) item) => item.$2 == b[item.$1]);

  final bool isEqual = sameLength && equalContent;

  assert(isEqual, '''
Expected length: ${a.length}
Actual length: ${b.length}

Expected first 20: ${a.take(20).toList()}
Actual first 20: ${b.take(20).toList()}

Expected last 20: ${a.skip(max(0, a.length - 20)).toList()}
Actual last 20: ${b.skip(max(0, b.length - 20)).toList()}
  ''');
}

void assertMap<T, U>(Map<T, U> a, Map<T, U> b) {
  assert(
    a.length == b.length,
    'Expected map with length ${a.length}, but found ${b.length}',
  );

  for (final MapEntry<T, U> entry in a.entries) {
    assert(
      b.containsKey(entry.key),
      'Expected key ${entry.key}, but none was found',
    );
    assert(
      b[entry.key] == entry.value,
      'Expected value ${entry.value}, but found ${b[entry.key]}',
    );
  }
}

void assertValues(List<(Object, Object)> values) {
  for (final (Object a, Object b) in values) {
    assert(a == b, "Expected '$a', but found '$b'");
  }
}

extension ChunkedList<T> on List<T> {
  Iterable<List<T>> chunked(int size) sync* {
    for (int i = 0; i < length; i += size) {
      yield sublist(i, i + size > length ? length : i + size);
    }
  }
}

extension UserExt on us.User {
  us.UserProfile toProfile() => us.UserProfile(
    userId: userId,
    username: username,
    role: role,
    createdAt: createdAt,
    icon: icon,
  );
}

extension VerifyEmailResponseExt on us.VerifyEmailResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension CreateResponseExt on us.CreateResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension ExistsResponseExt on us.ExistsResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension GetUsersResponseExt on us.GetResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertUsers(List<us.UserProfile> users) {
    assert(
      users.length == this.users.length,
      'Expected ${this.users.length} users, but found ${users.length}',
    );

    for (final us.UserProfile user in users) {
      final us.UserProfile? thisUser = this.users[user.userId];

      assert(thisUser != null, 'User ${user.userId} not found');

      assertValues(<(Object, Object)>[
        (user.userId, thisUser!.userId),
        (user.username, thisUser.username),
        (user.role, thisUser.role),
        (user.icon, thisUser.icon),
      ]);
    }
  }
}

extension AuthResponseExt on us.AuthResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertUser(us.User user) => assertValues(<(Object, Object)>[
    (user.userId, this.user.userId),
    (user.username, this.user.username),
    (user.email, this.user.email),
    (user.role, this.user.role),
    (user.icon, this.user.icon),
  ]);
}

extension UpdateResponseExt on us.UpdateResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SearchUsersResponseExt on us.SearchResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertContains(String userId) {
    assert(
      users.any((us.UserProfile user) => user.userId == userId),
      'Expected user $userId, but none was found',
    );
  }
}

extension BlockResponseExt on us.BlockResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension IsBlockedResponseExt on us.IsBlockedResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertBlocked(bool blocked) {
    assert(
      this.blocked == blocked,
      'Expected blocked $blocked, but found $blocked',
    );
  }
}

extension FollowResponseExt on us.FollowResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension DeleteResponseExt on us.DeleteResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension UploadResponseExt on res.UploadResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension MetaResponseExt on res.MetaResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertMetas(List<res.ResourceMeta> metas) {
    assert(
      metas.length == this.metas.length,
      'Expected ${metas.length} metas, but found ${this.metas.length}',
    );

    for (final (int, res.ResourceMeta) val in metas.indexed) {
      final res.ResourceMeta meta = val.$2;
      final res.ResourceMeta thisMeta = this.metas[val.$1];

      assertValues(<(Object, Object)>[
        (meta.size, thisMeta.size),
        (meta.name, thisMeta.name),
        (meta.metadata, thisMeta.metadata),
      ]);
    }
  }
}

extension DownloadResponseExt on List<res.DownloadResponse> {
  void assertSuccess() {
    for (final res.DownloadResponse resp in this) {
      assert(!resp.hasError(), 'Failed Operation: ${resp.error}');
    }
  }

  void assertError(ErrorCode code) {
    for (final res.DownloadResponse resp in this) {
      assert(resp.hasError(), 'Expected error, but none was found');
      assert(
        resp.error.code == code,
        'Expected error $code, but found ${resp.error}',
      );
    }
  }

  void assertMeta(res.ResourceMeta meta) {
    final res.ResourceMeta thisMeta = this.first.meta;

    assertValues(<(Object, Object)>[
      (meta.size, thisMeta.size),
      (meta.name, thisMeta.name),
      (meta.metadata, thisMeta.metadata),
    ]);
  }

  void assertData(List<int> data) {
    final List<int> thisData = List<int>.empty(growable: true);

    for (final res.DownloadResponse resp in this) {
      if (resp.hasData()) {
        thisData.addAll(resp.data);
      }
    }

    assertList(thisData, data);
  }
}

extension CreateChannelResponseExt on ch.CreateChannelResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertChannel({
    required String name,
    required String description,
    required Map<String, ch.ChannelPermission> members,
  }) {
    assertValues(<(Object, Object)>[
      (name, this.channel.name),
      (description, this.channel.description),
    ]);

    assertMap(members, this.channel.members);
  }
}

extension InviteChannelResponseExt on ch.InviteResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SetUserPermResponseExt on ch.SetUserPermResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension DeleteChannelResponseExt on ch.DeleteChannelResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SendMessageResponseExt on ch.SendResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertMessage({
    required String user_id,
    required Int64 channel_id,
    required res.Content content,
  }) {
    assertValues(<(Object, Object)>[
      (user_id, this.message.userId),
      (channel_id, this.message.channelId),
      (content, this.message.content),
    ]);
  }
}

extension ReadMessageResponseExt on ch.ReadResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertMessage(ch.Message message) {
    final ch.Message thisMessage = this.messages.first;

    assertValues(<(Object, Object)>[
      (message.messageId, thisMessage.messageId),
      (message.userId, thisMessage.userId),
      (message.channelId, thisMessage.channelId),
      (message.content, thisMessage.content),
      (message.createdAt, thisMessage.createdAt),
    ]);
  }
}

extension DeleteMessageResponseExt on ch.DeleteMessageResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension PublishResponseExt on ps.PublishResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertPost({
    required String authorId,
    required String content,
    required Int64? parent,
  }) {
    assertValues(<(Object, Object)>[
      (authorId, this.post.authorId),
      (content, this.post.content.text),
    ]);

    if (parent != null) {
      assert(this.post.hasParent(), 'Expected parent, but none was found');
      assert(
        parent == this.post.parent,
        'Expected parent $parent, but found ${this.post.parent}',
      );
    } else {
      assert(!this.post.hasParent(), 'Expected no parent, but found one');
    }
  }
}

extension UnpublishResponseExt on ps.UnpublishResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension GetPostsResponseExt on ps.GetResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertPosts(List<ps.Post> posts) {
    assert(
      posts.length == this.posts.length,
      'Expected ${this.posts.length} posts, but found ${posts.length}',
    );

    for (final ps.Post post in posts) {
      final ps.Post? thisPost = this.posts[post.postId];

      assert(thisPost != null, 'Post ${post.postId} not found');

      assertValues(<(Object, Object)>[
        (post.authorId, thisPost!.authorId),
        (post.content.text, thisPost.content.text),
        (post.parent, thisPost.parent),
        (post.timestamp, thisPost.timestamp),
        (post.reaction, thisPost.reaction),
      ]);

      assertMap(post.reactions, thisPost.reactions);
    }
  }
}

extension GetOfResponseExt on ps.GetOfResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertPosts(List<ps.Post> posts) {
    assert(
      posts.length == this.posts.length,
      'Expected ${this.posts.length} posts, but found ${posts.length}',
    );

    for (final (int, ps.Post) val in posts.indexed) {
      final ps.Post post = val.$2;
      final ps.Post thisPost = this.posts[val.$1];

      assertValues(<(Object, Object)>[
        (post.authorId, thisPost.authorId),
        (post.content.text, thisPost.content.text),
        (post.parent, thisPost.parent),
        (post.timestamp, thisPost.timestamp),
        (post.reaction, thisPost.reaction),
      ]);

      assertMap(post.reactions, thisPost.reactions);
    }
  }
}

extension ReactResponseExt on ps.ReactResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SearchPostsResponseExt on ps.SearchResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertPosts(List<ps.Post> posts) {
    assert(
      posts.length == this.posts.length,
      'Expected ${this.posts.length} posts, but found ${posts.length}',
    );

    for (final (int, ps.Post) val in posts.indexed) {
      final ps.Post post = val.$2;
      final ps.Post thisPost = this.posts[val.$1];

      assertValues(<(Object, Object)>[
        (post.authorId, thisPost.authorId),
        (post.content.text, thisPost.content.text),
        (post.parent, thisPost.parent),
        (post.timestamp, thisPost.timestamp),
        (post.reaction, thisPost.reaction),
      ]);

      assertMap(post.reactions, thisPost.reactions);
    }
  }
}

extension FeedResponseExt on ps.FeedResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertContains(Int64 postId) {
    assert(
      this.postIds.contains(postId),
      'Post $postId not found. Posts: ${this.postIds}',
    );
  }
}
