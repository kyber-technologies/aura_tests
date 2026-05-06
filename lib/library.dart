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
  late final CallOptions supervisorOptions;
  late final CallOptions newUserOptions;

  final String name;
  final String description;
  final List<(Test<dynamic>, dynamic)> tests;

  TestGroup(this.name, this.description, this.tests);

  Future<List<(String, bool)>> run() async {
    final List<(String, bool)> results = <(String, bool)>[];

    for (final (Test<dynamic> test, dynamic args) in tests) {
      final String name = test.getName(args);
      try {
        logger.i("Running '$name'...");
        await test.run(this, args);

        results.add((name, true));
      } on Object catch (e) {
        logger.e("Test '$name' failed: $e");
        results.add((name, false));
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

    logger.d('Authenticating as admin...');
    {
      final AuthUserResponse adminResponse = await user.authUser(
        AuthUserRequest(userId: adminUserId, password: adminPassword),
      );

      if (adminResponse.hasError()) {
        throw Exception(
          'Failed to authenticate test admin: ${adminResponse.error}',
        );
      }

      adminOptions = authOptions(adminResponse.token);
    }

    logger.d('Authenticating as supervisor...');
    {
      final AuthUserResponse superResponse = await user.authUser(
        AuthUserRequest(userId: supervisorUserId, password: supervisorPassword),
      );

      if (superResponse.hasError()) {
        throw Exception(
          'Failed to authenticate test supervisor: ${superResponse.error}',
        );
      }

      supervisorOptions = authOptions(superResponse.token);
    }

    logger.d('Authenticating as user...');
    {
      final AuthUserResponse userResponse = await user.authUser(
        AuthUserRequest(userId: newUserUserId, password: newUserPassword),
      );

      if (userResponse.hasError()) {
        throw Exception(
          'Failed to authenticate test user: ${userResponse.error}',
        );
      }

      newUserOptions = authOptions(userResponse.token);
    }

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
  }

  Future<void> dispose() async {
    await channel.shutdown();
  }
}

abstract class Test<A> {
  String getName(A args) => '$identifier - $args';

  String get identifier;

  String get description;

  Future<void> run(TestGroup group, A args);
}
