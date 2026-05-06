import 'package:aura_tests/library.dart';
import 'package:aura_tests/tests/chat.dart';
import 'package:aura_tests/tests/resource.dart';
import 'package:aura_tests/tests/user.dart';

void main(List<String> args) async {
  registerAll();

  final String command = args.firstOrNull ?? 'all';

  final List<(String, bool)> results = <(String, bool)>[];

  switch (command) {
    case 'all':
      for (final TestGroup test in groups.values) {
        final List<(String, bool)> testResults = await runTestGroup(test.name);

        results.addAll(testResults);
      }
    case 'list':
      logger.i('Listing available tests...');

      for (final TestGroup group in groups.values) {
        print('"${group.name}" - ${group.description}');

        for (final (Test<dynamic> test, dynamic args) in group.tests) {
          print('   "${test.getName(args)}" - ${test.description}');
        }
      }
    default:
      final List<(String, bool)> testResults = await runTestGroup(command);

      results.addAll(testResults);
  }

  if (results.isNotEmpty) {
    printResults(results);
  }
}

void registerAll() {
  registerGroup(userTests);
  registerGroup(chatTests);
  registerGroup(resourceTests);
}

Future<List<(String, bool)>> runTestGroup(String name) async {
  final TestGroup? group = groups[name];

  if (group == null) {
    throw Exception(
      "Test group $name not found! Use 'list' to list available tests groups.",
    );
  } else {
    logger.i('Initializing test group ${group.name}...');

    await group.init();

    final List<(String, bool)> results = await group.run();

    await group.dispose();

    return results;
  }
}

void printResults(final List<(String, bool)> results) {
  int passed = 0;
  int failed = 0;

  logger.i('########## RESULTS ##########');

  for (final (String name, bool result) in results) {
    if (result) {
      logger.i("Test '$name' passed");
      passed++;
    } else {
      logger.e("Test '$name' failed");
      failed++;
    }
  }

  final int percentage = ((passed / (passed + failed)) * 100).round();

  logger.i('Passed $passed tests, failed $failed tests, $percentage% passed');
}
