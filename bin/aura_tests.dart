import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/library.dart';
import 'package:aura_tests/tests/channels.dart';
import 'package:aura_tests/tests/messages.dart';
import 'package:aura_tests/tests/resources.dart';
import 'package:aura_tests/tests/users.dart';

void main(List<String> args) async {
  registerTest(UsersTest());
  registerTest(ResourcesTest());
  registerTest(ChannelsTest());
  registerTest(MessagesTest());

  final String? command = args.firstOrNull;

  final List<(Test, bool)> results = <(Test, bool)>[];

  if (command == null) {
    logger.e('Please provide a subcommand.');
    return;
  }

  final TestContext context = TestContext();

  logger.i('Initializing test context...');
  await context.init();

  switch (command) {
    case 'all':
      for (final Test test in tests.values) {
        final (Test, bool) result = await runTest(context, test.name);

        results.add(result);
      }
    case 'list':
      logger.i('Listing available tests...');

      for (final Test test in tests.values) {
        print('"${test.name}" - ${test.description}');
      }
    case 'help':
      print('aura_tests - Aura Server Testing Suite');
      print('Available commands:');
      print('  - <name>: Run a specific test.');
      print('  - all: Run all tests.');
      print('  - list: List available tests.');
      print('  - help: Show this help message.');
    default:
      final (Test, bool) result = await runTest(context, command);
      results.add(result);
  }

  await context.dispose();

  if (results.isNotEmpty) {
    printResults(results, command == 'all');
  }
}

Future<(Test, bool)> runTest(TestContext context, String name) async {
  final Test? test = tests[name];

  if (test == null) {
    throw Exception(
      "Test $name not found! Use 'list' to list available tests.",
    );
  } else {
    await context.general.clearState(ClearStateRequest());

    try {
      await test.run(context);
      return (test, true);
    } on Exception catch (error) {
      logger.e("Test '${test.name}' failed: ${error}");
      return (test, false);
    }
  }
}

void printResults(final List<(Test, bool)> results, final bool all) {
  final Set<String> coveredMethods = <String>{};

  int passed = 0;
  int failed = 0;

  logger.i('########## RESULTS ##########');

  for (final (Test test, bool result) in results) {
    coveredMethods.addAll(test.coveredMethods);

    if (result) {
      logger.i("Test '${test.name}' passed");
      passed++;
    } else {
      logger.e("Test '${test.name}' failed");
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
          'GeneralService/GetTestUsers',
        ]);

    if (uncoveredMethods.isEmpty) {
      logger.i('All methods are covered by tests');
    } else {
      logger.w('Some methods are not covered by tests:');
      for (final String method in uncoveredMethods) {
        print('   - $method');
      }
    }
  } else {
    logger.i("Run 'all' tests to get method coverage data.");
  }
}
