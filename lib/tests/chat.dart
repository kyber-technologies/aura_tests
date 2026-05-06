import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:fixnum/fixnum.dart';

final TestGroup chatTests =
    TestGroup('chat', 'Chat relatest tests', <(Test<dynamic>, dynamic)>[
      (ChatTest(), ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED),
      (ChatTest(), ChannelPermission.CHANNEL_PERMISSION_READ_WRITE),
      (ChatTest(), ChannelPermission.CHANNEL_PERMISSION_MANAGER),
    ]);

class ChatTest extends Test<ChannelPermission> {
  @override
  String get identifier => 'Chat';

  @override
  String get description => 'Various chat operations';

  @override
  Future<void> run(TestGroup group, ChannelPermission perm) async {
    final CreateChannelResponse
    createChannelResponse = await group.chat.createChannel(
      CreateChannelRequest(
        name: 'Some channel',
        description: 'Some channel',
        members: <MapEntry<String, ChannelPermission>>[
          MapEntry<String, ChannelPermission>(TestUser.admin.userId, perm),
          MapEntry<String, ChannelPermission>(TestUser.supervisor.userId, perm),
          MapEntry<String, ChannelPermission>(TestUser.newUser.userId, perm),
        ],
      ),
      options: group.adminOptions,
    );

    assert(
      !createChannelResponse.hasError(),
      'Failed to create channel: ${createChannelResponse.error}',
    );

    assert(
      createChannelResponse.channel.name == 'Some channel',
      'Channel name does not match',
    );

    final SendMessageResponse sendMessageResponse = await group.chat
        .sendMessage(
          SendMessageRequest(
            channelId: createChannelResponse.channel.channelId,
            content: Content(
              createdAt: Timestamp(millis: Int64()),
              text: 'Hello!',
            ),
          ),
          options: group.adminOptions,
        );

    if (perm == ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED) {
      assert(
        sendMessageResponse.hasError() &&
            sendMessageResponse.error.code == ErrorCode.ERROR_CODE_UNAUTHORIZED,
        'Failed to send message: ${sendMessageResponse.error}',
      );

      // Following operations are only valid if the message was actually created
      return;
    } else {
      assert(
        !sendMessageResponse.hasError(),
        'Failed to send message: ${sendMessageResponse.error}',
      );

      assert(
        sendMessageResponse.message.content.text == 'Hello!' &&
            sendMessageResponse.message.channelId ==
                createChannelResponse.channel.channelId,
        'Created resource does not match sent resource',
      );
    }

    final UpdateMessageResponse updateMessageResponse = await group.chat
        .updateMessage(
          UpdateMessageRequest(
            messageId: sendMessageResponse.message.messageId,
            content: Content(
              createdAt: Timestamp(millis: Int64()),
              text: 'Hello World!',
            ),
          ),
          options: group.adminOptions,
        );

    assert(
      !updateMessageResponse.hasError(),
      'Failed to update message: ${updateMessageResponse.error}',
    );

    assert(
      updateMessageResponse.message.content.text == 'Hello World!',
      'Updated message content does not match: '
      '${updateMessageResponse.message.content}',
    );

    final ReadMessagesResponse readMessagesResponse = await group.chat
        .readMessages(
          ReadMessagesRequest(
            channelId: createChannelResponse.channel.channelId,
            limit: 10,
            startTime: Timestamp(
              millis: Int64.parseInt(
                DateTime.now().millisecondsSinceEpoch.toString(),
              ),
            ),
          ),
          options: group.adminOptions,
        );

    assert(
      !readMessagesResponse.hasError(),
      'Failed to read messages: ${readMessagesResponse.error}',
    );

    assert(
      readMessagesResponse.messages.first.content.text == 'Hello World!',
      'Failed to read first message: ${readMessagesResponse.messages}',
    );

    final DeleteMessageResponse deleteMessageResponse = await group.chat
        .deleteMessage(
          DeleteMessageRequest(
            messageId: readMessagesResponse.messages.first.messageId,
          ),
          options: group.adminOptions,
        );

    assert(
      !deleteMessageResponse.hasError(),
      'Failed to delete message: ${deleteMessageResponse.error}',
    );

    final ReadMessagesResponse readMessagesRequest2 = await group.chat
        .readMessages(
          ReadMessagesRequest(
            channelId: createChannelResponse.channel.channelId,
            limit: 10,
            startTime: Timestamp(
              millis: Int64.parseInt(
                DateTime.now().millisecondsSinceEpoch.toString(),
              ),
            ),
          ),
          options: group.adminOptions,
        );

    assert(
      !readMessagesRequest2.hasError(),
      'Failed to read messages: ${readMessagesRequest2.error}',
    );

    assert(
      readMessagesRequest2.messages.isEmpty,
      'Messages not empty after deletion',
    );
  }
}
