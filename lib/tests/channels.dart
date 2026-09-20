import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';

class ChannelsTest implements Test {
  @override
  Set<String> get coveredMethods => <String>{
    'ChatService/CreateChannel',
    'ChatService/InviteChannel',
    'ChatService/SetUserPerm',
    'ChatService/DeleteChannel',
  };

  @override
  String get description => 'Test channel logic';

  @override
  String get name => 'channels';

  @override
  Future<void> run(TestContext context) async {
    const String channelName = 'New Channel';
    const String channelDesc = 'A new channel';
    final List<MapEntry<String, ChannelPermission>> members =
        <MapEntry<String, ChannelPermission>>[
          MapEntry<String, ChannelPermission>(
            context.testUser.userId,
            ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED,
          ),
          // Admin is automatically a manager as creator of channel
        ];

    // Create channel with members:
    // - Test User as read-only
    // - Implicitly: Admin as manager
    final CreateChannelResponse createChannelResponse =
        await context.chat.createChannel(
            CreateChannelRequest(
              name: channelName,
              description: channelDesc,
              members: members,
            ),
            options: context.adminOptions,
          )
          ..assertSuccess()
          ..assertChannel(
            name: channelName,
            description: channelDesc,
            members: Map<String, ChannelPermission>.fromEntries(members)
              ..addEntries(<MapEntry<String, ChannelPermission>>[
                MapEntry<String, ChannelPermission>(
                  context.admin.userId,
                  ChannelPermission.CHANNEL_PERMISSION_MANAGER,
                ),
              ]),
          );

    // Invite user with insufficient permissions
    await context.chat.inviteChannel(
        InviteChannelRequest(
          userId: context.moderator.userId,
          channelId: createChannelResponse.channel.channelId,
          uninvite: false,
        ),
        options: context.testUserOptions,
      )
      ..assertError(ErrorCode.ERROR_CODE_RESTRICTED);

    // Invite user with sufficient permissions
    await context.chat.inviteChannel(
        InviteChannelRequest(
          userId: context.moderator.userId,
          channelId: createChannelResponse.channel.channelId,
          uninvite: false,
        ),
        options: context.adminOptions,
      )
      ..assertSuccess();

    // Set permission with insufficient permissions
    await context.chat.setUserPerm(
        SetUserPermRequest(
          userId: context.testUser.userId,
          channelId: createChannelResponse.channel.channelId,
          permission: ChannelPermission.CHANNEL_PERMISSION_MANAGER,
        ),
        options: context.testUserOptions,
      )
      ..assertError(ErrorCode.ERROR_CODE_RESTRICTED);

    // Set permission of test user by admin (sufficient permissions)
    await context.chat.setUserPerm(
        SetUserPermRequest(
          userId: context.testUser.userId,
          channelId: createChannelResponse.channel.channelId,
          permission: ChannelPermission.CHANNEL_PERMISSION_MANAGER,
        ),
        options: context.adminOptions,
      )
      ..assertSuccess();

    // Invite user with sufficient permissions
    await context.chat.inviteChannel(
      InviteChannelRequest(
        userId: context.testUser.userId,
        channelId: createChannelResponse.channel.channelId,
        uninvite: false,
      ),
      options: context.adminOptions,
    );

    // Set permission of test user back to read-only
    await context.chat.setUserPerm(
        SetUserPermRequest(
          userId: context.testUser.userId,
          channelId: createChannelResponse.channel.channelId,
          permission:
              ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED,
        ),
        options: context.testUserOptions,
      )
      ..assertSuccess();

    // Try to delete channel with insufficient permissions
    await context.chat.deleteChannel(
        DeleteChannelRequest(
          channelId: createChannelResponse.channel.channelId,
        ),
        options: context.testUserOptions,
      )
      ..assertError(ErrorCode.ERROR_CODE_RESTRICTED);

    // Test user leaves channel
    await context.chat.inviteChannel(
        InviteChannelRequest(
          userId: context.testUser.userId,
          channelId: createChannelResponse.channel.channelId,
          uninvite: true,
        ),
        options: context.testUserOptions,
      )
      ..assertSuccess();

    // Uninvite moderator as admin
    await context.chat.inviteChannel(
        InviteChannelRequest(
          userId: context.moderator.userId,
          channelId: createChannelResponse.channel.channelId,
          uninvite: true,
        ),
        options: context.adminOptions,
      )
      ..assertSuccess();

    // Delete channel as admin
    await context.chat.deleteChannel(
        DeleteChannelRequest(
          channelId: createChannelResponse.channel.channelId,
        ),
        options: context.adminOptions,
      )
      ..assertSuccess();
  }
}
