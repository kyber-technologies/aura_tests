import 'package:aura_dart/user.dart';
import 'package:aura_tests/utils.dart';

extension UserExt on User {
  UserProfile toProfile() => UserProfile(
    userId: userId,
    username: username,
    role: role,
    createdAt: createdAt,
    icon: icon,
  );

  void assertUser(User other) => assertList(<(Object, Object)>[
    (other.userId, userId),
    (other.username, username),
    (other.email, email),
    (other.role, role),
    (other.icon, icon),
  ]);
}

extension UserProfileExt on UserProfile {
  void assertProfile(UserProfile other) => assertList(<(Object, Object)>[
    (other.userId, userId),
    (other.username, username),
    (other.role, role),
    (other.icon, icon),
  ]);
}

extension VerifyEmailResponseExt on VerifyEmailResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension CreateResponseExt on CreateResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension ExistsResponseExt on ExistsResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension GetUsersResponseExt on GetResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertUsers(List<UserProfile> users) => assertLists(
    users,
    this.users.values.toList(),
    asserter: (UserProfile a, UserProfile b) => a.assertProfile(b),
  );
}

extension AuthResponseExt on AuthResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertUser(User user) => user.assertUser(this.user);
}

extension UpdateResponseExt on UpdateResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension SearchUsersResponseExt on SearchResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertContains(String userId) {
    assert(
      users.any((UserProfile user) => user.userId == userId),
      'Expected user $userId, but none was found',
    );
  }
}

extension BlockResponseExt on BlockResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension IsBlockedResponseExt on IsBlockedResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertBlocked(bool blocked) {
    assert(
      this.blocked == blocked,
      'Expected blocked $blocked, but found $blocked',
    );
  }
}

extension FollowResponseExt on FollowResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension DeleteResponseExt on DeleteResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}
