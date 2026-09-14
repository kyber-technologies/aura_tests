import 'dart:io';

import 'package:aura_dart/aura_dart.dart';
import 'package:aura_tests/utils.dart';
import 'package:grpc/grpc.dart';
import 'package:logger/logger.dart';
import 'package:yaml/yaml.dart';

final Logger logger = Logger(
  filter: ProductionFilter(),
  printer: SimplePrinter(),
  output: ConsoleOutput(),
  level: (Platform.environment['LOG_DEBUG'] ?? '0') == '1'
      ? Level.debug
      : Level.info,
);

final Map<String, TestGroup> groups = <String, TestGroup>{};

final Set<String> registeredMethods = <String>{};

void registerGroup(TestGroup group) => groups[group.name] = group;

class TestGroup {
  late final String version;

  late final ClientChannel channel;
  late final GeneralServiceClient general;
  late final UserServiceClient user;
  late final ChatServiceClient chat;
  late final ResourceServiceClient resource;
  late final GetConfigResponse config;

  late final CallOptions adminOptions;
  late final CallOptions moderatorOptions;
  late final CallOptions newUserOptions;

  final String name;
  final String description;
  final List<(Test<dynamic>, dynamic)> tests;

  TestGroup(this.name, this.description, this.tests);

  Future<List<(String, bool, Set<String>)>> run() async {
    final List<(String, bool, Set<String>)> results =
        <(String, bool, Set<String>)>[];

    for (final (Test<dynamic> test, dynamic args) in tests) {
      final String name = test.getName(args);

      try {
        logger.i("Running '$name'...");
        await test.run(this, args);

        results.add((name, true, test.coveredMethods));
      } on Object catch (e) {
        logger.e("Test '$name' failed: $e");
        results.add((name, false, test.coveredMethods));
      }
    }

    return results;
  }

  Future<void> init() async {
    logger.d('Getting package version...');
    {
      final String pubspec = await File('pubspec.yaml').readAsString();
      final YamlMap yaml = loadYaml(pubspec) as YamlMap;
      version = yaml['version'] as String;
    }

    logger.d('Initializing channels...');
    channel = ClientChannel(
      Platform.environment['GRPC_HOST'] ?? '127.0.0.1',
      port: int.parse(Platform.environment['GRPC_PORT'] ?? '50051'),
      options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
    );

    logger.d('Initializing general service...');
    general = GeneralServiceClient(channel);

    logger.d('Initializing user service...');
    user = UserServiceClient(channel);

    logger.d('Initializing chat service...');
    chat = ChatServiceClient(channel);

    logger.d('Initializing resource service...');
    resource = ResourceServiceClient(channel);

    logger.d('Clearing server state...');
    await general.clearState(ClearStateRequest());

    logger.d('Validating configuration...');
    {
      final GetConfigResponse config = await general.getConfig(
        GetConfigRequest(),
      );

      assert(
        config.version == version,
        'Package version and server version do not match',
      );

      this.config = config;
    }

    if (registeredMethods.isEmpty) {
      logger.d('Fetching registered methods...');

      final GetServicesResponse response = await general.getServices(
        GetServicesRequest(),
      );

      for (final ServiceDescriptor service in response.services) {
        for (final String method in service.methods) {
          registeredMethods.add('${service.name}/$method');
        }
      }
    }

    logger.d('Authenticating as admin...');
    {
      final AuthUserResponse response = await user.authUser(
        AuthUserRequest(userId: adminUserId, password: adminPassword),
      );

      if (response.hasError()) {
        throw Exception('Failed to authenticate test admin: ${response.error}');
      }

      adminOptions = authOptions(response.token);
    }

    logger.d('Authenticating as moderator...');
    {
      final AuthUserResponse response = await user.authUser(
        AuthUserRequest(userId: moderatorUserId, password: moderatorPassword),
      );

      if (response.hasError()) {
        throw Exception(
          'Failed to authenticate test supervisor: ${response.error}',
        );
      }

      moderatorOptions = authOptions(response.token);
    }

    logger.d('Authenticating as user...');
    {
      final AuthUserResponse response = await user.authUser(
        AuthUserRequest(userId: newUserUserId, password: newUserPassword),
      );

      if (response.hasError()) {
        throw Exception('Failed to authenticate test user: ${response.error}');
      }

      newUserOptions = authOptions(response.token);
    }
  }

  Future<void> dispose() async {
    await channel.shutdown();
  }
}

abstract class Test<A> {
  String getName(A args) => '$identifier - $args';

  String get identifier;

  String get description;

  Set<String> get coveredMethods;

  Future<void> run(TestGroup group, A args);
}
