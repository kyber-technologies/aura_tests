import 'package:aura_dart/aura_dart.dart';
import 'package:grpc/grpc.dart';
import 'package:protobuf/well_known_types/google/protobuf/empty.pb.dart';

final ResourceId defaultIconResource = ResourceId(
  namespace: ResourceNamespace(aura: Empty()),
  key: 'default_icon.png',
);

CallOptions authOptions(String token) =>
    CallOptions(metadata: <String, String>{'Authorization': token});

void assertList<T>(List<T> a, List<T> b) {
  final bool equal = a.indexed.every(((int, T) item) => item.$2 == b[item.$1]);

  assert(equal, '''
Expected length: ${a.length} 
Actual length: ${b.length} 
      
Expected first 20: ${a.take(20).toList()} 
Actual first 20: ${b.take(20).toList()} 
      
Expected last 20: ${a.skip(a.length - 20).toList()} 
Actual last 20: ${b.skip(b.length - 20).toList()}
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

extension UserExt on User {
  UserProfile toProfile() => UserProfile(
    userId: userId,
    username: username,
    role: role,
    createdAt: createdAt,
    icon: icon,
  );
}

extension VerifyEmailResponseExt on VerifyEmailResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension CreateUserResponseExt on CreateUserResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension UserExistsResponseExt on UserExistsResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension GetUserResponseExt on GetUserResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertUser(UserProfile user) => assertValues(<(Object, Object)>[
    (user.userId, this.user.userId),
    (user.username, this.user.username),
    (user.role, this.user.role),
    (user.icon, this.user.icon),
  ]);
}

extension AuthUserResponseExt on AuthUserResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertUser(User user) => assertValues(<(Object, Object)>[
    (user.userId, this.user.userId),
    (user.username, this.user.username),
    (user.email, this.user.email),
    (user.role, this.user.role),
    (user.icon, this.user.icon),
  ]);
}

extension UpdateUserResponseExt on UpdateUserResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SearchUsersResponseExt on SearchUsersResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertContains(String userId) {
    assert(
      users.any((UserProfile user) => user.userId == userId),
      'Expected user $userId, but none was found',
    );
  }
}

extension BlockUserResponseExt on BlockUserResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension IsBlockedResponseExt on IsBlockedResponse {
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

extension DeleteUserResponseExt on DeleteUserResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension UploadResponseExt on UploadResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension GetResourceMetaResponseExt on GetResourceMetaResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertMeta(ResourceMeta meta) => assertValues(<(Object, Object)>[
    (meta.size, this.meta.size),
    (meta.name, this.meta.name),
    (meta.metadata, this.meta.metadata),
  ]);
}

extension DownloadResponseExt on List<DownloadResponse> {
  void assertSuccess() {
    for (final DownloadResponse resp in this) {
      assert(!resp.hasError(), 'Failed Operation: ${resp.error}');
    }
  }

  void assertError(ErrorCode code) {
    for (final DownloadResponse resp in this) {
      assert(resp.hasError(), 'Expected error, but none was found');
      assert(
        resp.error.code == code,
        'Expected error $code, but found ${resp.error}',
      );
    }
  }

  void assertMeta(ResourceMeta meta) {
    final ResourceMeta thisMeta = this.first.meta;

    assertValues(<(Object, Object)>[
      (meta.size, thisMeta.size),
      (meta.name, thisMeta.name),
      (meta.metadata, thisMeta.metadata),
    ]);
  }

  void assertData(List<int> data) {
    final List<int> thisData = List<int>.empty(growable: true);

    for (final DownloadResponse resp in this) {
      if (resp.hasData()) {
        thisData.addAll(resp.data);
      }
    }

    assertList(thisData, data);
  }
}

extension CreateChannelResponseExt on CreateChannelResponse {
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
    required Map<String, ChannelPermission> members,
  }) {
    assertValues(<(Object, Object)>[
      (name, this.channel.name),
      (description, this.channel.description),
    ]);

    assertMap(members, this.channel.members);
  }
}

extension InviteChannelResponseExt on InviteChannelResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SetUserPermResponseExt on SetUserPermResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension DeleteChannelResponseExt on DeleteChannelResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}

extension SendMessageResponseExt on SendMessageResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertMessage({
    required String user_id,
    required String channel_id,
    required Content content,
  }) {
    assertValues(<(Object, Object)>[
      (user_id, this.message.userId),
      (channel_id, this.message.channelId),
      (content, this.message.content),
    ]);
  }
}

extension ReadMessageResponseExt on ReadMessagesResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }

  void assertMessage(Message message) {
    final Message thisMessage = this.messages.first;

    assertValues(<(Object, Object)>[
      (message.messageId, thisMessage.messageId),
      (message.userId, thisMessage.userId),
      (message.channelId, thisMessage.channelId),
      (message.content, thisMessage.content),
      (message.createdAt, thisMessage.createdAt),
    ]);
  }
}

extension DeleteMessageResponseExt on DeleteMessageResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorCode code) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.code == code, 'Expected error $code, but found $error');
  }
}
