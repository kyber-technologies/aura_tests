import 'package:aura_dart/chat.dart';
import 'package:aura_dart/resource.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

class MessagesTest implements Test {
  @override
  Set<String> get coveredMethods => <String>{
    'ChatService/Send',
    'ChatService/Read',
    'ChatService/DeleteMessage',
  };

  @override
  String get description => 'Test message logic';

  @override
  String get name => 'messages';

  @override
  Future<void> run(TestContext context) async {
    // Create channel with members:
    // - Test User as read-only
    // - Moderator as read-write
    // - Implicitly: Admin as manager
    final CreateChannelResponse createChannelResponse =
        await context.chat.createChannel(
            CreateChannelRequest(
              name: 'New Channel',
              description: 'Some channel',
              members: <MapEntry<String, ChannelPermission>>[
                MapEntry<String, ChannelPermission>(
                  context.testUser.userId,
                  ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED,
                ),
                MapEntry<String, ChannelPermission>(
                  context.moderator.userId,
                  ChannelPermission.CHANNEL_PERMISSION_READ_WRITE,
                ),
              ],
            ),
            options: context.adminOptions,
          )
          ..assertSuccess();

    // Try to send message with read-only permission
    await context.chat.send(
        SendRequest(
          channelId: createChannelResponse.channel.channelId,
          content: Content(text: 'Hello World!'),
        ),
        options: context.testUserOptions,
      )
      ..assertError(ErrorType.restricted);

    // Send message with read-write permission
    final SendResponse sendMessageResponse =
        await context.chat.send(
            SendRequest(
              channelId: createChannelResponse.channel.channelId,
              content: Content(text: 'Hello World!'),
            ),
            options: context.moderatorOptions,
          )
          ..assertSuccess()
          ..assertMessage(
            user_id: context.moderator.userId,
            channel_id: createChannelResponse.channel.channelId,
            content: Content(text: 'Hello World!'),
          );

    // Read message with read permission
    await context.chat.read(
        ReadRequest(
          channelId: createChannelResponse.channel.channelId,
          limit: 1,
          startTime: Timestamp.fromDateTime(DateTime.now()),
        ),
        options: context.testUserOptions,
      )
      ..assertSuccess()
      ..assertMessage(sendMessageResponse.message);

    // Delete message with read-only permission
    await context.chat.deleteMessage(
        DeleteMessageRequest(messageId: sendMessageResponse.message.messageId),
        options: context.testUserOptions,
      )
      ..assertError(ErrorType.restricted);

    // Delete message with sufficient permission
    await context.chat.deleteMessage(
        DeleteMessageRequest(messageId: sendMessageResponse.message.messageId),
        options: context.moderatorOptions,
      )
      ..assertSuccess();
  }
}
