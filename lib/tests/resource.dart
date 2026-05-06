import 'dart:async';

import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:grpc/src/client/common.dart';

// 5 MiB of Data
const int _resourceSize = 1024 * 1024 * 5;

final TestGroup resourceTests =
    TestGroup('resource', 'Resource relatest tests', <(Test<dynamic>, dynamic)>[
      (
        ResourceTest(),
        ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED,
      ),
      (ResourceTest(), ChannelPermission.CHANNEL_PERMISSION_READ_WRITE),
      (ResourceTest(), ChannelPermission.CHANNEL_PERMISSION_MANAGER),
    ]);

class ResourceTest extends Test<ChannelPermission> {
  @override
  String get identifier => 'Resource';

  @override
  String get description => 'Various resource operations';

  @override
  Future<void> run(TestGroup group, ChannelPermission perm) async {
    final ResourceId userAvatarId = ResourceId(
      namespace: 'user.${TestUser.admin.userId}',
      key: 'avatar.png',
    );

    final GetResourceMetaResponse resourceMetaResponse = await group.resource
        .getResourceMeta(
          GetResourceMetaRequest(resourceId: userAvatarId),
          options: group.newUserOptions,
        );

    assert(
      !resourceMetaResponse.hasError(),
      'Failed to get user avatar meta: ${resourceMetaResponse.error}',
    );

    final List<DownloadResponse> avatarResponse = await group.resource
        .download(
          DownloadRequest(resourceId: userAvatarId),
          options: group.newUserOptions,
        )
        .toList();

    {
      final DownloadResponse firstAvatarResponse = avatarResponse.removeAt(0);

      assert(
        !firstAvatarResponse.hasError(),
        'Failed to download user avatar: ${firstAvatarResponse.error}',
      );
      assert(
        firstAvatarResponse.hasMeta(),
        'First download response must be meta',
      );
    }

    {
      final DownloadResponse firstAvatarResponse = avatarResponse.removeAt(0);

      assert(
        !firstAvatarResponse.hasError(),
        'Failed to download user avatar: ${firstAvatarResponse.error}',
      );
      assert(
        firstAvatarResponse.hasData(),
        'First download response must be data',
      );
      assert(firstAvatarResponse.data.isNotEmpty, 'User avatar is empty');
    }

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

    // If the channel is read-only, we can't upload resources
    if (perm == ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED) {
      return;
    }

    final ResourceId resourceId = ResourceId(
      namespace: createChannelResponse.channel.channelId,
      key: 'data',
    );

    final List<int> data = List<int>.generate(
      _resourceSize,
      (int index) => index,
    );

    final StreamController<UploadRequest> controller =
        StreamController<UploadRequest>()..add(
          UploadRequest(
            resourceId: resourceId,
            meta: ResourceMeta(
              size: _resourceSize,
              // Gets fixed by server internally
              timestamp: Timestamp(millis: Int64.parseInt('0')),
              metadata: <MapEntry<String, String>>[],
            ),
          ),
        );

    final ResponseFuture<UploadResponse> uploadResponseFut = group.resource
        .upload(controller.stream, options: group.adminOptions);

    for (final List<int> chunk in data.chunked(
      group.config.resourceChunkSize,
    )) {
      controller.add(UploadRequest(resourceId: resourceId, data: chunk));
    }

    await controller.close();

    final UploadResponse uploadResponse = await uploadResponseFut;

    assert(
      !uploadResponse.hasError(),
      'Failed to upload resource: ${uploadResponse.error}',
    );
  }
}
