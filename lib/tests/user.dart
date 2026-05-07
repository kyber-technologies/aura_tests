import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:grpc/grpc.dart';

final TestGroup userTests = TestGroup(
  'user',
  'User relatest tests',
  <(Test<dynamic>, dynamic)>[(UserTest(), ())],
);

class UserTest extends Test<void> {
  @override
  String get identifier => 'User';

  @override
  String get description => 'Various operations on users';

  @override
  Future<void> run(TestGroup group, void args) async {
    const String userId = 'foobar';

    final VerifyEmailResponse verifyEmailResponse = await group.user
        .verifyEmail(VerifyEmailRequest(email: 'foo@bar.baz'));

    assert(
      !verifyEmailResponse.hasError(),
      'Failed to verify email: ${verifyEmailResponse.error}',
    );

    final GetEmailTokenResponse emailTokenResponse = await group.general
        .getEmailToken(GetEmailTokenRequest(email: 'foo@bar.baz'));

    // Only allowed for admins
    final CreateUserResponse createUserResponse = await group.user.createUser(
      CreateUserRequest(
        userId: userId,
        username: 'Foo Bar',
        email: 'foo@bar.baz',
        password: '123',
        verificationToken: emailTokenResponse.token,
      ),
    );

    assert(
      !createUserResponse.hasError(),
      'Failed to create user: ${createUserResponse.error}',
    );

    final AuthUserResponse authUserResponse = await group.user.authUser(
      AuthUserRequest(userId: 'foobar', password: '123'),
    );

    assert(
      !authUserResponse.hasError(),
      'Failed to auth user: ${authUserResponse.error}',
    );

    CallOptions authOpts = authOptions(authUserResponse.token);

    // Only allowed for admins
    final UpdateUserResponse updateUserResponse = await group.user.updateUser(
      UpdateUserRequest(
        username: 'Foo Bar Baz',
        email: 'foobar@bar.baz',
        password: 'abc123',
      ),
      options: authOpts,
    );

    assert(
      !updateUserResponse.hasError(),
      'Failed to update user: ${updateUserResponse.error}',
    );

    final AuthUserResponse authUserResponse2 = await group.user.authUser(
      AuthUserRequest(userId: 'foobar', password: 'abc123'),
    );

    assert(
      !authUserResponse2.hasError(),
      'Failed to auth user: ${authUserResponse2.error}',
    );

    authOpts = authOptions(authUserResponse2.token);

    // Allowed
    final GetUserResponse getUserResponse = await group.user.getUser(
      GetUserRequest(userId: userId),
      options: authOpts,
    );

    assert(
      !getUserResponse.hasError(),
      'Failed to get user: ${getUserResponse.error}',
    );

    assert(
      getUserResponse.user.username == 'Foo Bar Baz',
      'Got wrong user: ${getUserResponse.user.username}',
    );

    // Allowed
    final SearchUsersResponse searchUsersResponse = await group.user
        .searchUsers(SearchUsersRequest(query: 'Foo Bar'), options: authOpts);

    assert(
      !searchUsersResponse.hasError(),
      'Failed to search users: ${searchUsersResponse.error}',
    );

    assert(
      searchUsersResponse.users[0].username == 'Foo Bar Baz',
      'Got wrong user: ${searchUsersResponse.users[0]}',
    );

    // Not allowed
    final DeleteUserResponse failDeleteUserResponse = await group.user
        .deleteUser(DeleteUserRequest(password: '123'), options: authOpts);

    assert(
      failDeleteUserResponse.hasError() &&
          failDeleteUserResponse.error.code ==
              ErrorCode.ERROR_CODE_UNAUTHORIZED,
      'Failed to delete user: ${failDeleteUserResponse.error}',
    );

    // Allowed
    final DeleteUserResponse deleteUserResponse = await group.user.deleteUser(
      DeleteUserRequest(password: 'abc123'),
      options: authOpts,
    );

    assert(
      !deleteUserResponse.hasError(),
      'Failed to delete user: ${deleteUserResponse.error}',
    );
  }
}
