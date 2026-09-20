import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:grpc/grpc.dart';

class UsersTest implements Test {
  @override
  Set<String> get coveredMethods => <String>{
    'UserService/VerifyEmail',
    'UserService/CreateUser',
    'UserService/UserExists',
    'UserService/GetUser',
    'UserService/AuthUser',
    'UserService/UpdateUser',
    'UserService/SearchUsers',
    'UserService/BlockUser',
    'UserService/IsBlocked',
    'UserService/DeleteUser',
  };

  @override
  String get description => 'Test user logic';

  @override
  String get name => 'users';

  @override
  Future<void> run(TestContext context) async {
    final User user = User(
      userId: 'newUser',
      username: 'New User',
      email: 'new_user@aura.testing',
      password: 'password123',
      role: UserRole.USER_ROLE_USER_UNSPECIFIED,
      icon: defaultIconResource,
    );

    // User should not exist
    await context.user.userExists(UserExistsRequest(userId: user.userId))
      ..assertError(ErrorCode.ERROR_CODE_NOT_FOUND);

    // Verify Email
    (await context.user.verifyEmail(
      VerifyEmailRequest(email: user.email),
    )).assertSuccess();

    // Create User with invalid Email Token
    await context.user.createUser(
        CreateUserRequest(
          userId: user.userId,
          username: user.username,
          email: user.email,
          password: user.password,
          verificationToken: 'HelloWorld',
        ),
      )
      ..assertError(ErrorCode.ERROR_CODE_UNAUTHORIZED);

    // TESTING: Get correct Email Token
    final GetEmailTokenResponse getTokenResponse = await context.general
        .getEmailToken(GetEmailTokenRequest(email: user.email));

    // Create User with correct Email Token
    await context.user.createUser(
        CreateUserRequest(
          userId: user.userId,
          username: user.username,
          email: user.email,
          password: user.password,
          verificationToken: getTokenResponse.token,
        ),
      )
      ..assertSuccess();

    // User should exist
    await context.user.userExists(UserExistsRequest(userId: user.userId))
      ..assertSuccess();

    // Get non-existent User
    await context.user.getUser(
        GetUserRequest(userId: 'otherUser'),
        options: context.adminOptions,
      )
      ..assertError(ErrorCode.ERROR_CODE_NOT_FOUND);

    // Get existent User
    await context.user.getUser(
        GetUserRequest(userId: user.userId),
        options: context.adminOptions,
      )
      ..assertSuccess()
      ..assertUser(user.toProfile());

    // Auth User
    final AuthUserResponse authResponse =
        await context.user.authUser(
            AuthUserRequest(userId: user.userId, password: user.password),
          )
          ..assertSuccess()
          ..assertUser(user);

    final CallOptions options = authOptions(authResponse.token);

    // Update User
    user
      ..username = 'Awesome User'
      ..email = 'awesome@aura.testing'
      ..password = 'awesome123';
    await context.user.updateUser(
        UpdateUserRequest(
          username: user.username,
          email: user.email,
          password: user.password,
        ),
        options: options,
      )
      ..assertSuccess();

    // Search for User
    await context.user.searchUsers(
        SearchUsersRequest(query: user.username),
        options: options,
      )
      ..assertSuccess()
      ..assertContains(user.userId);

    // Block User
    await context.user.blockUser(
        BlockUserRequest(userId: context.admin.userId, block: true),
        options: options,
      )
      ..assertSuccess();

    // Check if User blocked
    await context.user.isBlocked(
        IsBlockedRequest(userId: context.admin.userId),
        options: options,
      )
      ..assertSuccess()
      ..assertBlocked(true);

    // Unblock User
    await context.user.blockUser(
        BlockUserRequest(userId: context.admin.userId, block: false),
        options: options,
      )
      ..assertSuccess();

    // Check if User unblocked
    await context.user.isBlocked(
        IsBlockedRequest(userId: context.admin.userId),
        options: options,
      )
      ..assertSuccess()
      ..assertBlocked(false);

    // Delete User
    await context.user.deleteUser(
      DeleteUserRequest(password: user.password),
      options: options,
    );
  }
}
