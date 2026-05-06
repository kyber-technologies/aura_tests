import 'package:aura_tests/library.dart';
import 'package:grpc/grpc.dart';

const String adminUserId = 'admin';
const String adminPassword = 'admin';
const String supervisorUserId = 'supervisor';
const String supervisorPassword = 'supervisor';
const String newUserUserId = 'user';
const String newUserPassword = 'user';

CallOptions authOptions(String token) =>
    CallOptions(metadata: <String, String>{'Authorization': token});

class UserAuth {
  final String username;
  final String password;

  const UserAuth(this.username, this.password);
}

enum TestUser {
  admin,
  supervisor,
  newUser;

  String get userId {
    switch (this) {
      case TestUser.admin:
        return adminUserId;
      case TestUser.supervisor:
        return supervisorUserId;
      case TestUser.newUser:
        return newUserUserId;
    }
  }

  CallOptions options(TestGroup group) {
    switch (this) {
      case TestUser.admin:
        return group.adminOptions;
      case TestUser.supervisor:
        return group.supervisorOptions;
      case TestUser.newUser:
        return group.newUserOptions;
    }
  }
}

extension ChunkedList<T> on List<T> {
  Iterable<List<T>> chunked(int size) sync* {
    for (int i = 0; i < length; i += size) {
      yield sublist(i, i + size > length ? length : i + size);
    }
  }
}
