import 'dart:async';
import 'dart:math';

import 'package:eni_svc/eni_svc.dart';
import 'package:flutter/widgets.dart';

const _parallelBootstrap = true;

String _generateAnonymousProviderName() {
  return "unnamed service provider";
}

abstract class ImmutableServiceRegistry {
  Iterable<T> getServices<T>({RunLevel requiredRunLevel = RunLevel.ready});

  T? getServiceOrNull<T>(
      {String? name, RunLevel requiredRunLevel = RunLevel.ready});

  T getService<T>({String? name, RunLevel requiredRunLevel = RunLevel.ready});
}

abstract class MutableServiceRegistry {
  void register(ServiceDescriptor descriptor);
}

abstract class ServiceRegistry
    implements ImmutableServiceRegistry, MutableServiceRegistry {}

bool _isServiceNameMatch(String name, Pattern? pattern) {
  if (pattern == null) {
    return true;
  }

  return pattern.matchAsPrefix(name)?.input == name;
}

enum ServiceScopeType { scoped, transient }

mixin Service {
  void onRegister(ServiceRegistry services) {}

  Future onPrepare(ServiceRegistry services) => Future.value();

  Future onPreInit(ServiceRegistry services) => Future.value();

  Future onInit(ServiceRegistry services) => Future.value();

  Future onPostInit(ServiceRegistry services) => Future.value();

  Future onStart(ServiceRegistry services) => Future.value();

  Future onReload() => Future.value();

  ServiceProvider get services => _services;
  late final ServiceProvider _services;

  late final ServiceDescriptor _descriptor;

  List<Configuration> get configurations => services
      .getServices<Configuration>(requiredRunLevel: RunLevel.created)
      .where((config) =>
          _isServiceNameMatch(_descriptor.name, config.serviceNamePattern))
      .where((config) =>
          config.serviceType == null ||
          _descriptor.isOfType(config.serviceType))
      .toList();

  T? getConfigOrNull<T>(String key) {
    return configurations
        .map((config) => config.getOrNull<T>(key))
        .where((val) => val != null)
        .firstOrNull;
  }

  T getConfig<T>(String key, [T? defaultValue]) {
    final value = getConfigOrNull<T>(key);
    if (value != null) {
      return value;
    }

    if (defaultValue != null) {
      return defaultValue;
    }

    throw UnsupportedError("No such config key '$key'");
  }
}

class ServiceDescriptor {
  static const defaultScope = ServiceScopeType.scoped;
  static const int defaultPriority = 0;

  final int Function(BuildContext context) priority;
  final Type type;
  final Type family;
  final String name;
  final FutureOr<dynamic> Function(BuildContext context) create;
  final bool ephemeral;
  final ServiceScopeType scope;

  ServiceDescriptor(
      {required this.create,
      required this.priority,
      required this.type,
      required this.name,
      Type? family,
      this.ephemeral = false,
      this.scope = defaultScope})
      : family = family ?? type;

  bool isOfType<S>([Type? t]) =>
      t != null ? (type == t || family == t) : type == S || family == S;

  static ServiceDescriptor from<T>({
    required String name,
    required FutureOr<T> Function(BuildContext context) create,
    int Function(BuildContext context)? priorityCallback,
    Type? family,
    int priority = defaultPriority,
    bool ephemeral = false,
  }) {
    return ServiceDescriptor(
      name: name,
      create: create,
      priority: priorityCallback ?? (_) => priority,
      type: T,
      family: family,
      ephemeral: ephemeral,
    );
  }
}

class _BootstrapServiceDescriptor {
  RunLevel _level = RunLevel.uninitialized;
  late final dynamic instance;

  _BootstrapServiceDescriptor({required this.descriptor});

  RunLevel get level => _level;

  final ServiceDescriptor descriptor;
}

class ServiceProvider implements ServiceRegistry {
  final String name;
  final Set<_BootstrapServiceDescriptor> _bootstrapServiceDescriptors = {};

  final Future Function(ServiceDescriptor serviceDescriptor, dynamic service,
      RunLevel level, double hookExecutionTime)? onServiceBootstrapLevelChanged;

  final Future Function(RunLevel level)? onBootstrapLevelChanged;
  final Future Function(ServiceDescriptor serviceDescriptor, dynamic instance)?
      onServiceInstanceCreated;

  final BuildContext Function()? buildContextProvider;

  ServiceProvider(
      {this.buildContextProvider,
      this.onServiceBootstrapLevelChanged,
      this.onBootstrapLevelChanged,
      this.onServiceInstanceCreated,
      String? name})
      : name = name ?? _generateAnonymousProviderName();

  var _level = RunLevel.uninitialized;

  RunLevel get level => _level;

  Iterable<_BootstrapServiceDescriptor> _getServiceDescriptors<T>(
          {RunLevel requiredRunLevel = RunLevel.ready}) =>
      (T == dynamic
              ? _bootstrapServiceDescriptors
              : _bootstrapServiceDescriptors
                  .where((svc) => svc.descriptor.isOfType(T)))
          .where((svc) => svc.level.index >= requiredRunLevel.index)
          .where((svc) => svc._level != RunLevel.uninitialized);

  @override
  Iterable<T> getServices<T>({RunLevel requiredRunLevel = RunLevel.ready}) =>
      _getServiceDescriptors<T>(requiredRunLevel: requiredRunLevel)
          .map((d) => d.instance);

  @override
  T? getServiceOrNull<T>(
      {String? name, RunLevel requiredRunLevel = RunLevel.ready}) {
    final allDescriptors =
        _getServiceDescriptors<T>(requiredRunLevel: requiredRunLevel).toList();
    if (allDescriptors.isEmpty) {
      return null;
    }

    final transientMatches = allDescriptors
        .where((d) =>
            d.descriptor.scope == ServiceScopeType.transient &&
            d.descriptor.isOfType(T) &&
            (name == null || d.descriptor.name == name))
        .toList();

    if (transientMatches.isNotEmpty) {
      if (transientMatches.length > 1) {
        throw StateError("Multiple services of given type are registered");
      }
      final descriptor = transientMatches.first;

      if (buildContextProvider == null) {
        throw StateError(
            "Transient services can only be constructed with a buildContextProvider passed to ServiceProvider");
      }

      final instance = descriptor.descriptor.create(buildContextProvider!());
      if (instance is! T) {
        throw StateError("Transient state factories must not return Futures");
      }

      onServiceInstanceCreated?.call(descriptor.descriptor, instance);

      if (instance is Service) {
        instance.onRegister(this);
      }

      return instance;
    }

    _BootstrapServiceDescriptor? descriptor;

    if (name != null) {
      descriptor =
          allDescriptors.where((d) => d.descriptor.name == name).firstOrNull;
    } else {
      if (allDescriptors.length != 1) {
        throw StateError("Multiple services of given type are registered");
      }
      descriptor = allDescriptors.single;
    }

    return descriptor?.instance;
  }

  @override
  T getService<T>({String? name, RunLevel requiredRunLevel = RunLevel.ready}) {
    final svc =
        getServiceOrNull<T>(name: name, requiredRunLevel: requiredRunLevel);
    if (svc == null) {
      throw ArgumentError("No such service");
    }
    return svc;
  }

  @override
  void register(ServiceDescriptor descriptor) {
    if (_level == RunLevel.values.last) {
      throw StateError("ServiceProvider is already bootstrapped");
    }

    if (descriptor.scope == ServiceScopeType.transient &&
        descriptor.type is Service) {
      throw ArgumentError(
          "Transient services may not implement a Service interface");
    }

    if (_bootstrapServiceDescriptors
        .any((d) => d.descriptor.name == descriptor.name)) {
      throw StateError(
          "A service named '${descriptor.name}' is already registered");
    }

    _bootstrapServiceDescriptors
        .add(_BootstrapServiceDescriptor(descriptor: descriptor));
  }

  bool registerIfAbsent(ServiceDescriptor descriptor) {
    if (_bootstrapServiceDescriptors
        .any((d) => d.descriptor.isOfType(descriptor.type))) {
      return false;
    }

    register(descriptor);
    return true;
  }

  RunLevel get _lowestServiceLevel => _bootstrapServiceDescriptors
      .map((d) => d.level)
      .reduce((a, b) => a.index < b.index ? a : b);

  @protected
  Future bootstrap(BuildContext context) async {
    Future bootService(_BootstrapServiceDescriptor service) async {
      if (!context.mounted) {
        throw StateError("ServiceProvider lost its BuildContext");
      }

      if (service._level == RunLevel.uninitialized) {
        // Create the service
        if (!context.mounted) {
          throw StateError("ServiceProvider lost its BuildContext");
        }
        service.instance = await service.descriptor.create(context);
        if (service.instance is Service) {
          service.instance._services = this;
          service.instance._descriptor = service.descriptor;
        }

        await onServiceInstanceCreated?.call(
            service.descriptor, service.instance);

        service._level = RunLevel.created;

        if (service.instance is Service) {
          service.instance.onRegister(this);
        }

        return;
      }

      if (_lowestServiceLevel == RunLevel.uninitialized) {
        // Idle as long as there are pending services to be created.
        return;
      }

      final sw = Stopwatch()..start();

      if (service.instance is Service) {
        switch (service._level) {
          case RunLevel.uninitialized:
          case RunLevel.created:
            await service.instance.onPrepare(this);
          case RunLevel.prepared:
            await service.instance.onPreInit(this);
          case RunLevel.preInitialized:
            await service.instance.onInit(this);
          case RunLevel.initialized:
            await service.instance.onPostInit(this);
          case RunLevel.postInitialized:
            await service.instance.onStart(this);
          case RunLevel.ready:
        }
      }

      service._level = RunLevel
          .values[min(service._level.index + 1, RunLevel.values.length - 1)];

      if (service.descriptor.ephemeral && service.level == RunLevel.ready) {
        // Remove ephemeral services when they become ready
        _bootstrapServiceDescriptors
            .removeWhere((d) => d.descriptor == service.descriptor);
      }

      await onServiceBootstrapLevelChanged?.call(service.descriptor,
          service.instance, service.level, sw.elapsedMilliseconds / 1000.0);
    }

    do {
      if (_bootstrapServiceDescriptors.isEmpty) {
        // Nothing to do here
        _level = RunLevel.ready;
        await onBootstrapLevelChanged?.call(_level);
        return;
      }

      if (_lowestServiceLevel == RunLevel.ready) {
        // Bootstrap is complete
        break;
      }

      // Gather all descriptors and sort by their priorities
      final descriptors = _bootstrapServiceDescriptors
          .where((d) => d.level == _lowestServiceLevel)
          .toList()
        ..sort((a, b) {
          final aPriority = a.descriptor.priority(context);
          final bPriority = b.descriptor.priority(context);
          return bPriority.compareTo(aPriority);
        });

      if (_parallelBootstrap) {
        await Future.wait(descriptors.map((service) => bootService(service)));
      } else {
        for (final service in descriptors) {
          await bootService(service);
        }
      }

      late final RunLevel nextLevel;

      if (_bootstrapServiceDescriptors.isNotEmpty) {
        nextLevel = _bootstrapServiceDescriptors
            .map((d) => d.level)
            .reduce((a, b) => a.index < b.index ? a : b);
      } else {
        nextLevel = RunLevel.ready;
      }

      if (nextLevel != _level) {
        _level = nextLevel;
        await onBootstrapLevelChanged?.call(_level);
      }
    } while (true);
  }
}
