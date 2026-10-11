import 'package:aura_dart/resource.dart';
import 'package:aura_tests/utils.dart';

extension ResourceMetaExt on ResourceMeta {
  void assertMeta(ResourceMeta other) {
    assertList(<(Object, Object)>[(other.size, size), (other.name, name)]);

    assertMap(other.metadata, metadata);
  }
}

extension UploadResponseExt on UploadResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }
}

extension MetaResponseExt on MetaResponse {
  void assertSuccess() {
    assert(!hasError(), 'Failed Operation: ${error}');
  }

  void assertError(ErrorType ty) {
    assert(hasError(), 'Expected error, but none was found');
    assert(error.whichType() == ty, 'Expected error $ty, but found $error');
  }

  void assertMetas(List<ResourceMeta> metas) => assertLists(
    this.metas,
    metas,
    asserter: (ResourceMeta a, ResourceMeta b) => a.assertMeta(b),
  );
}

extension DownloadResponseExt on List<DownloadResponse> {
  void assertSuccess() {
    for (final DownloadResponse resp in this) {
      assert(!resp.hasError(), 'Failed Operation: ${resp.error}');
    }
  }

  void assertError(ErrorType ty) {
    for (final DownloadResponse resp in this) {
      assert(resp.hasError(), 'Expected error, but none was found');
      assert(
        resp.error.whichType() == ty,
        'Expected error $ty, but found ${resp.error}',
      );
    }
  }

  void assertMeta(ResourceMeta meta) {
    this.first.meta.assertMeta(meta);
  }

  void assertData(List<int> data) {
    final List<int> thisData = List<int>.empty(growable: true);

    for (final DownloadResponse resp in this) {
      if (resp.hasData()) {
        thisData.addAll(resp.data);
      }
    }

    assertLists(thisData, data);
  }
}
