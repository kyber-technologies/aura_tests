import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';

final TestGroup userTests =
    TestGroup('user', 'User relatest tests', <(Test<dynamic>, dynamic)>[
      (UserTest(), TestUser.admin),
      (UserTest(), TestUser.supervisor),
      (UserTest(), TestUser.newUser),
    ]);

class UserTest extends Test<TestUser> {
  @override
  String get identifier => 'User';

  @override
  String get description => 'Various operations on users';

  @override
  Future<void> run(TestGroup group, TestUser user) async {
    final String createUserId = 'user-$user';

    // Only allowed for admins
    final CreateUserResponse createUserResponse = await group.user.createUser(
      CreateUserRequest(
        user: User(
          userId: createUserId,
          username: 'Foo Bar',
          email: 'foo@bar.baz',
          password: '123',
          role: UserRole.USER_ROLE_USER_UNSPECIFIED,
          icon: defaultUserIcon,
        ),
      ),
      options: user.options(group),
    );

    if (user == TestUser.admin) {
      assert(
        !createUserResponse.hasError(),
        'Failed to create user: ${createUserResponse.error}',
      );
    } else {
      assert(
        createUserResponse.hasError() &&
            createUserResponse.error.code == ErrorCode.ERROR_CODE_UNAUTHORIZED,
        'Failed to create user: ${createUserResponse.error}',
      );
    }

    // Only allowed for admins
    final UpdateUserResponse updateUserResponse = await group.user.updateUser(
      UpdateUserRequest(
        user: User(
          userId: createUserId,
          username: 'Foo Bar Baz',
          email: 'foo-bar@baz.com',
          password: 'abc',
          role: UserRole.USER_ROLE_SUPERVISOR,
          icon: ResourceId(namespace: 'test-1', key: 'test-resource-1'),
        ),
      ),
      options: user.options(group),
    );

    if (user == TestUser.admin) {
      assert(
        !updateUserResponse.hasError(),
        'Failed to update user: ${updateUserResponse.error}',
      );
    } else {
      assert(
        updateUserResponse.hasError() &&
            updateUserResponse.error.code == ErrorCode.ERROR_CODE_UNAUTHORIZED,
        'Failed to update user: ${updateUserResponse.error}',
      );
    }

    // Not allowed (failed)
    final AuthUserResponse failedAuthUserResponse = await group.user.authUser(
      AuthUserRequest(userId: createUserId, password: 'abcde'),
    );

    assert(
      failedAuthUserResponse.hasError() &&
          failedAuthUserResponse.error.code ==
              ErrorCode.ERROR_CODE_UNAUTHORIZED,
      'Failed authentication not correct: ${failedAuthUserResponse.error}',
    );

    // Allowed
    final AuthUserResponse authUserResponse = await group.user.authUser(
      AuthUserRequest(userId: createUserId, password: 'abc'),
    );

    if (user == TestUser.admin) {
      assert(
        !authUserResponse.hasError(),
        'Failed to authenticate user: ${authUserResponse.error}',
      );
    } else {
      // Following operations will not succeed,
      // since only admins can create user.
      return;
    }

    // Allowed
    final UpdateUserAvatarResponse updateUserAvatarResponse = await group.user
        .updateUserAvatar(
          UpdateUserAvatarRequest(
            avatar: ResourceId(namespace: 'test-2', key: 'test-resource-2'),
          ),
          options: authOptions(authUserResponse.token),
        );

    assert(
      !updateUserAvatarResponse.hasError(),
      'Failed to update user avatar: ${updateUserAvatarResponse.error}',
    );

    // Allowed
    final GetUserResponse getUserResponse = await group.user.getUser(
      GetUserRequest(userId: createUserId),
      options: user.options(group),
    );

    assert(
      !getUserResponse.hasError(),
      'Failed to get user: ${getUserResponse.error}',
    );

    assert(
      getUserResponse.user.username == 'Foo Bar Baz',
      'Got wrong user: ${getUserResponse.user}',
    );

    // Allowed
    final SearchUsersResponse searchUsersResponse = await group.user
        .searchUsers(
          SearchUsersRequest(query: 'Foo Bar'),
          options: authOptions(authUserResponse.token),
        );

    assert(
      !searchUsersResponse.hasError(),
      'Failed to search users: ${searchUsersResponse.error}',
    );

    assert(
      searchUsersResponse.users[0].username == 'Foo Bar Baz',
      'Got wrong user: ${searchUsersResponse.users[0]}',
    );

    // Only allowed for admins
    final DeleteUserResponse deleteUserResponse = await group.user.deleteUser(
      DeleteUserRequest(userId: createUserId),
      options: user.options(group),
    );

    assert(
      !deleteUserResponse.hasError(),
      'Failed to delete user: ${deleteUserResponse.error}',
    );
  }
}
