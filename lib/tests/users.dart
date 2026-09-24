import 'package:aura_dart/common.dart';
import 'package:aura_dart/general.dart';
import 'package:aura_dart/user.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:grpc/grpc.dart';

class UsersTest implements Test {
  @override
  Set<String> get coveredMethods => <String>{
    'UserService/VerifyEmail',
    'UserService/Create',
    'UserService/Exists',
    'UserService/Get',
    'UserService/Auth',
    'UserService/Update',
    'UserService/Search',
    'UserService/Block',
    'UserService/IsBlocked',
    'UserService/Follow',
    'UserService/Delete',
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
    await context.user.exists(ExistsRequest(userId: user.userId))
      ..assertError(ErrorCode.ERROR_CODE_NOT_FOUND);

    // Verify Email
    (await context.user.verifyEmail(
      VerifyEmailRequest(email: user.email),
    )).assertSuccess();

    // Create User with invalid Email Token
    await context.user.create(
        CreateRequest(
          userId: user.userId,
          username: user.username,
          email: user.email,
          password: user.password,
          verificationToken: 'HelloWorld',
        ),
      )
      ..assertError(ErrorCode.ERROR_CODE_UNAUTHORIZED);

    // TESTING: Get correct Email Token
    final EmailTokenResponse getTokenResponse = await context.general
        .emailToken(EmailTokenRequest(email: user.email));

    // Create User with correct Email Token
    await context.user.create(
        CreateRequest(
          userId: user.userId,
          username: user.username,
          email: user.email,
          password: user.password,
          verificationToken: getTokenResponse.token,
        ),
      )
      ..assertSuccess();

    // User should exist
    await context.user.exists(ExistsRequest(userId: user.userId))
      ..assertSuccess();

    // Get non-existent User
    await context.user.get(
        GetRequest(userId: <String>['otherUser']),
        options: context.adminOptions,
      )
      // User not found
      ..assertUsers(<UserProfile>[]);

    // Get existent User
    await context.user.get(
        GetRequest(userId: <String>[user.userId]),
        options: context.adminOptions,
      )
      ..assertSuccess()
      ..assertUsers(<UserProfile>[user.toProfile()]);

    // Auth User
    final AuthResponse authResponse =
        await context.user.auth(
            AuthRequest(userId: user.userId, password: user.password),
          )
          ..assertSuccess()
          ..assertUser(user);

    final CallOptions options = authOptions(authResponse.token);

    // Update User
    user
      ..username = 'Awesome User'
      ..email = 'awesome@aura.testing'
      ..password = 'awesome123';
    await context.user.update(
        UpdateRequest(
          username: user.username,
          email: user.email,
          password: user.password,
        ),
        options: options,
      )
      ..assertSuccess();

    // Search for User
    await context.user.search(
        SearchRequest(query: user.username, limit: 1),
        options: options,
      )
      ..assertSuccess()
      ..assertContains(user.userId);

    // Block User
    await context.user.block(
        BlockRequest(userId: context.admin.userId, block: true),
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
    await context.user.block(
        BlockRequest(userId: context.admin.userId, block: false),
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

    // Follow admin
    await context.user.follow(
        FollowRequest(userId: context.admin.userId, unfollow: false),
        options: options,
      )
      ..assertSuccess();

    // Unfollow admin
    await context.user.follow(
        FollowRequest(userId: context.admin.userId, unfollow: true),
        options: options,
      )
      ..assertSuccess();

    // Delete User
    await context.user.delete(
      DeleteRequest(password: user.password),
      options: options,
    );
  }
}
