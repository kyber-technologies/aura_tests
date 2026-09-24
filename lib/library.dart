import 'dart:io';

import 'package:aura_dart/chat.dart';
import 'package:aura_dart/general.dart';
import 'package:aura_dart/posting.dart';
import 'package:aura_dart/resource.dart';
import 'package:aura_dart/user.dart';
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

final Map<String, Test> tests = <String, Test>{};

final Set<String> registeredMethods = <String>{};

void registerTest(Test test) => tests[test.name] = test;

class TestContext {
  late final String version;

  late final ClientChannel channel;
  late final GeneralServiceClient general;
  late final UserServiceClient user;
  late final ChatServiceClient chat;
  late final ResourceServiceClient resource;
  late final PostingServiceClient posting;
  late final ConfigResponse config;

  late final User testUser;
  late final CallOptions testUserOptions;

  late final User admin;
  late final CallOptions adminOptions;

  late final User moderator;
  late final CallOptions moderatorOptions;

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
    );

    logger.d('Initializing general service...');
    general = GeneralServiceClient(channel);

    logger.d('Initializing user service...');
    user = UserServiceClient(channel);

    logger.d('Initializing chat service...');
    chat = ChatServiceClient(channel);

    logger.d('Initializing resource service...');
    resource = ResourceServiceClient(channel);

    logger.d('Initializing posting service...');
    posting = PostingServiceClient(channel);

    logger.d('Clearing server state...');
    await general.clearState(ClearStateRequest());

    logger.d('Validating configuration...');
    {
      final ConfigResponse config = await general.config(ConfigRequest());

      assert(
        config.version == version,
        'Package version and server version do not match',
      );

      this.config = config;
    }

    if (registeredMethods.isEmpty) {
      logger.d('Fetching registered methods...');

      final ServicesResponse response = await general.services(
        ServicesRequest(),
      );

      for (final ServiceDescriptor service in response.services) {
        for (final String method in service.methods) {
          registeredMethods.add('${service.name}/$method');
        }
      }
    }

    logger.d('Requesting test user data...');
    {
      final TestUsersResponse testUsers = await general.testUsers(
        TestUsersRequest(),
      );

      admin = testUsers.admin;
      moderator = testUsers.moderator;
      testUser = testUsers.user;
    }

    logger.d('Authenticating as test user...');
    {
      final AuthResponse response = await user.auth(
        AuthRequest(userId: testUser.userId, password: testUser.password),
      );

      if (response.hasError()) {
        throw Exception('Failed to authenticate test user: ${response.error}');
      }

      testUserOptions = authOptions(response.token);
    }

    logger.d('Authenticating as moderator...');
    {
      final AuthResponse response = await user.auth(
        AuthRequest(userId: moderator.userId, password: moderator.password),
      );

      if (response.hasError()) {
        throw Exception('Failed to authenticate moderator: ${response.error}');
      }

      moderatorOptions = authOptions(response.token);
    }

    logger.d('Authenticating as admin...');
    {
      final AuthResponse response = await user.auth(
        AuthRequest(userId: admin.userId, password: admin.password),
      );

      if (response.hasError()) {
        throw Exception('Failed to authenticate admin: ${response.error}');
      }

      adminOptions = authOptions(response.token);
    }
  }

  Future<void> dispose() async {
    await channel.shutdown();
  }
}

abstract class Test {
  String get name;

  String get description;

  Set<String> get coveredMethods;

  Future<void> run(TestContext context);
}
