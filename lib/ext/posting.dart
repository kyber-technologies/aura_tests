import 'package:aura_dart/posting.dart';
import 'package:aura_tests/utils.dart';
import 'package:fixnum/fixnum.dart';

extension PostExt on Post {
  void assertPostWeak({
    required String authorId,
    required String content,
    required Int64? parent,
  }) {
    assertList(<(String, String)>[
      (authorId, this.authorId),
      (content, this.content.text),
    ]);

    if (parent != null) {
      assert(hasParent(), 'Expected parent, but none was found');
      assert(
        parent == this.parent,
        'Expected parent $parent, but found ${this.parent}',
      );
    } else {
      assert(!hasParent(), 'Expected no parent, but found one');
    }
  }

  void assertPost(Post other) {
    assertList(<(Object, Object)>[
      (other.authorId, authorId),
      (other.content.text, content.text),
      (other.parent, parent),
      (other.timestamp, timestamp),
      (other.reaction, reaction),
    ]);

    assertLists(other.comments, comments);
    assertMap(other.reactions, reactions);
  }
}

extension PublishResponseExt on PublishResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertPost({
    required String authorId,
    required String content,
    required Int64? parent,
  }) =>
      post.assertPostWeak(authorId: authorId, content: content, parent: parent);
}

extension UnpublishResponseExt on UnpublishResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension GetPostsResponseExt on GetResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertPosts(List<Post> posts) => assertLists(
    posts,
    this.posts.values.toList(),
    asserter: (Post a, Post b) => a.assertPost(b),
  );
}

extension GetOfResponseExt on GetOfResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertPosts(List<Post> posts) => assertLists(
    posts,
    this.posts,
    asserter: (Post a, Post b) => a.assertPost(b),
  );
}

extension ReactResponseExt on ReactResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension SearchPostsResponseExt on SearchResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertPosts(List<Post> posts) => assertLists(
    posts,
    this.posts,
    asserter: (Post a, Post b) => a.assertPost(b),
  );
}

extension FeedResponseExt on FeedResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertContains(Int64 postId) {
    assert(
      this.postIds.contains(postId),
      'Post $postId not found. Posts: ${this.postIds}',
    );
  }
}
