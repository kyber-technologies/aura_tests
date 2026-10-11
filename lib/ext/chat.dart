import 'package:aura_dart/chat.dart';
import 'package:aura_dart/resource.dart';
import 'package:aura_tests/utils.dart';
import 'package:fixnum/fixnum.dart';

extension ChannelExt on Channel {
  void assertChannelWeak({
    required String name,
    required String description,
    required Map<String, ChannelPermission> members,
  }) {
    assertList(<(String, String)>[
      (name, this.name),
      (description, this.description),
    ]);

    assertMap(members, this.members);
  }
}

extension MessageExt on Message {
  void assertMessageWeak({
    required String userId,
    required Int64 channelId,
    required Content content,
  }) => assertList(<(Object, Object)>[
    (userId, this.userId),
    (channelId, this.channelId),
    (this.content.text, content.text),
  ]);

  void assertMessage(Message message) => assertList(<(Object, Object)>[
    (message.messageId, messageId),
    (message.userId, userId),
    (message.channelId, channelId),
    (message.content.text, content.text),
    (message.createdAt, createdAt),
  ]);
}

extension CreateChannelResponseExt on CreateChannelResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertChannel({
    required String name,
    required String description,
    required Map<String, ChannelPermission> members,
  }) => channel.assertChannelWeak(
    name: name,
    description: description,
    members: members,
  );
}

extension InviteChannelResponseExt on InviteResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension SetUserPermResponseExt on SetUserPermResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension DeleteChannelResponseExt on DeleteChannelResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension SendMessageResponseExt on SendResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertMessage({
    required String userId,
    required Int64 channelId,
    required Content content,
  }) => message.assertMessageWeak(
    userId: userId,
    channelId: channelId,
    content: content,
  );
}

extension ReadMessageResponseExt on ReadResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertMessage(Message message) =>
      message.assertMessage(this.messages.first);
}

extension DeleteMessageResponseExt on DeleteMessageResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}
