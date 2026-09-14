import 'package:aura_tests/library.dart';
import 'package:aura_tests/tests/chat.dart';
import 'package:aura_tests/tests/resource.dart';
import 'package:aura_tests/tests/user.dart';

void main(List<String> args) async {
  registerAll();

  final String? command = args.firstOrNull;

  final List<(String, bool, Set<String>)> results =
      <(String, bool, Set<String>)>[];

  if (command == null) {
    logger.e('Please provide a subcommand.');
    return;
  }

  switch (command) {
    case 'all':
      for (final TestGroup test in groups.values) {
        final List<(String, bool, Set<String>)> testResults =
            await runTestGroup(test.name);

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
    case 'help':
      print('aura_tests - Aura Server Testing Suite');
      print('Available commands:');
      print('  - <name>: Run a specific test group.');
      print('  - all: Run all tests.');
      print('  - list: List available tests.');
      print('  - help: Show this help message.');
    default:
      final List<(String, bool, Set<String>)> testResults = await runTestGroup(
        command,
      );
      results.addAll(testResults);
  }

  if (results.isNotEmpty) {
    printResults(results, command == 'all');
  }
}

void registerAll() {
  registerGroup(userTests);
  registerGroup(chatTests);
  registerGroup(resourceTests);
}

Future<List<(String, bool, Set<String>)>> runTestGroup(String name) async {
  final TestGroup? group = groups[name];

  if (group == null) {
    throw Exception(
      "Test group $name not found! Use 'list' to list available tests groups.",
    );
  } else {
    logger.i('Initializing test group ${group.name}...');

    await group.init();

    final List<(String, bool, Set<String>)> results = await group.run();

    await group.dispose();

    return results;
  }
}

void printResults(
  final List<(String, bool, Set<String>)> results,
  final bool all,
) {
  final Set<String> coveredMethods = <String>{};

  int passed = 0;
  int failed = 0;

  logger.i('########## RESULTS ##########');

  for (final (String name, bool result, Set<String> methods) in results) {
    coveredMethods.addAll(methods);

    if (result) {
      logger.i("Test '$name' passed");
      passed++;
    } else {
      logger.e("Test '$name' failed");
      failed++;
    }
  }

  final int percentage = ((passed / (passed + failed)) * 100).round();

  bool unknownMethods = false;

  // Validate that all methods covered by tests are registered
  for (final String method in coveredMethods) {
    if (!registeredMethods.contains(method)) {
      unknownMethods = true;
      logger.e('A test covered a method that is not registered: $method');
    }
  }

  if (unknownMethods) {
    print('Registered Methods:');
    for (final String method in registeredMethods) {
      print('   - $method');
    }
  }

  logger.i('Passed $passed tests, failed $failed tests, $percentage% passed');

  if (all) {
    final Set<String> uncoveredMethods =
        registeredMethods.difference(coveredMethods)..removeAll(<Object?>[
          // Remove general methods that are never covered
          'GeneralService/GetConfig',
          'GeneralService/ClearState',
          'GeneralService/GetEmailToken',
          'GeneralService/GetServices',
        ]);

    if (uncoveredMethods.isEmpty) {
      logger.i('All methods are covered by tests');
    } else {
      logger.w('Some methods are not covered by tests:');
      for (final String method in uncoveredMethods) {
        print('   - $method');
      }
    }
  }
}
