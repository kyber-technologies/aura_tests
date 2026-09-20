import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

class ResourcesTest implements Test {
  @override
  Set<String> get coveredMethods => <String>{
    'ResourceService/Upload',
    'ResourceService/GetResourceMeta',
    'ResourceService/Download',
  };

  @override
  String get description => 'Test resource logic';

  @override
  String get name => 'resources';

  @override
  Future<void> run(TestContext context) async {
    final int size = context.config.resourceChunkSize * 10;
    final List<int> data = List<int>.generate(size, (int index) => index % 256);
    final ResourceMeta meta = ResourceMeta(
      size: size,
      timestamp: Timestamp(),
      name: 'test.data',
      metadata: <MapEntry<String, String>>{},
    );

    // Create channel owned by admin with test user as read-only member
    final CreateChannelResponse createChannelResponse =
        await context.chat.createChannel(
            CreateChannelRequest(
              name: 'test_channel',
              description: 'New Test Channel',
              members: <MapEntry<String, ChannelPermission>>[
                MapEntry<String, ChannelPermission>(
                  context.testUser.userId,
                  ChannelPermission.CHANNEL_PERMISSION_READ_ONLY_UNSPECIFIED,
                ),
              ],
            ),
            options: context.adminOptions,
          )
          ..assertSuccess();

    final List<UploadRequest> uploads =
        <UploadRequest>[
          UploadRequest(
            namespace: ResourceNamespace(
              channel: createChannelResponse.channel.channelId,
            ),
            meta: meta,
          ),
        ]..addAll(
          data
              .chunked(context.config.resourceChunkSize)
              .map((List<int> chunk) => UploadRequest(data: chunk)),
        );
    ;

    // Try to upload with read-only permission
    await context.resource.upload(
        Stream<UploadRequest>.fromIterable(uploads),
        options: context.testUserOptions,
      )
      ..assertError(ErrorCode.ERROR_CODE_RESTRICTED);

    // Upload with write permission
    final UploadResponse uploadResponse =
        await context.resource.upload(
            Stream<UploadRequest>.fromIterable(uploads),
            options: context.adminOptions,
          )
          ..assertSuccess();

    // Get Resource Meta with read-only permission
    await context.resource.getResourceMeta(
        GetResourceMetaRequest(resourceId: uploadResponse.resourceId),
        options: context.testUserOptions,
      )
      ..assertSuccess()
      ..assertMeta(meta);

    // Download Resource with read-only permission
    await (await context.resource.download(
        DownloadRequest(resourceId: uploadResponse.resourceId),
        options: context.testUserOptions,
      )).toList()
      ..assertSuccess()
      ..assertMeta(meta)
      ..assertData(data);
  }
}
