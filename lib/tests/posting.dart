import 'package:aura_dart/common.dart';
import 'package:aura_dart/posting.dart';
import 'package:aura_dart/resource.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/utils.dart';
import 'package:fixnum/fixnum.dart';
import 'package:protobuf/well_known_types/google/protobuf/timestamp.pb.dart';

class PostingTest implements Test {
  @override
  Set<String> get coveredMethods => <String>{
    'PostingService/Publish',
    'PostingService/Get',
    'PostingService/GetOf',
    'PostingService/Search',
    'PostingService/React',
    'PostingService/Feed',
    'PostingService/Unpublish'
  };

  @override
  String get description => 'Test posting logic';

  @override
  String get name => 'posting';

  @override
  Future<void> run(TestContext context) async {
    // Publish post by test user
    final PublishResponse publishResponse =
        await context.posting.publish(
            PublishRequest(content: Content(text: 'Hello World!')),
            options: context.testUserOptions,
          )
          ..assertSuccess()
          ..assertPost(
            authorId: context.testUser.userId,
            content: 'Hello World!',
            parent: null,
          );

    // Publish comment by admin
    await context.posting.publish(
        PublishRequest(
          content: Content(text: 'Hello to you too!'),
          parent: publishResponse.post.postId,
        ),
        options: context.adminOptions,
      )
      ..assertSuccess()
      ..assertPost(
        authorId: context.admin.userId,
        content: 'Hello to you too!',
        parent: publishResponse.post.postId,
      );

    // Get post
    await context.posting.get(
        GetRequest(posts: <Int64>[publishResponse.post.postId]),
        options: context.adminOptions,
      )
      ..assertSuccess()
      ..assertPosts(<Post>[publishResponse.post]);

    // Get posts of test user
    await context.posting.getOf(
        GetOfRequest(
          authorId: context.testUser.userId,
          limit: 1,
          startAt: Timestamp.fromDateTime(DateTime.now()),
        ),
        options: context.adminOptions,
      )
      ..assertSuccess()
      ..assertPosts(<Post>[publishResponse.post]);

    // Search for posts
    await context.posting.search(
        SearchRequest(
          query: 'Hello World!',
          limit: 1,
          startAt: Timestamp.fromDateTime(DateTime.now()),
        ),
        options: context.adminOptions,
      )
      ..assertSuccess()
      ..assertPosts(<Post>[publishResponse.post]);

    // React to a post as admin
    await context.posting.react(
        ReactRequest(
          postId: publishResponse.post.postId,
          reaction: PostReaction.POST_REACTION_LIKE,
        ),
        options: context.adminOptions,
      )
      ..assertSuccess();

    // Get feed of moderator
    await context.posting.feed(
        FeedRequest(limit: 10, index: 0),
        options: context.moderatorOptions,
      )
      ..assertSuccess()
      ..assertContains(publishResponse.post.postId);

    // Try to unpublish root post by admin
    await context.posting.unpublish(
        UnpublishRequest(postId: publishResponse.post.postId),
        options: context.adminOptions,
      )
      ..assertError(ErrorCode.ERROR_CODE_RESTRICTED);

    // Unpublish root post
    await context.posting.unpublish(
        UnpublishRequest(postId: publishResponse.post.postId),
        options: context.testUserOptions,
      )
      ..assertSuccess();
  }
}
