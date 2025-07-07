import 'package:eni_svc/eni_svc.dart';
import 'package:eni_svc/service.dart';
import 'package:eni_utils/logger.dart';
import 'package:flutter/widgets.dart';

int _anonymousServiceId = 0;
bool _logNonServiceTypes = false;
bool _logEphemeralServices = false;
double _acceptableServiceHookExecutionTime = 2.0;

String _generateAnonymousScopeName() {
  return "unnamed service scope";
}

String _generateAnonymousServiceName({required Type type}) {
  if (type == dynamic) {
    return "anonymous service ${++_anonymousServiceId}";
  }

  return "$type service ${++_anonymousServiceId}";
}

class _ServiceProvider extends ServiceProvider {
  Future doBootstrap(BuildContext context) => bootstrap(context);

  final _ServiceScopeState scope;

  _ServiceProvider(
      {required this.scope,
      required super.name,
      required super.buildContextProvider,
      super.onBootstrapLevelChanged,
      super.onServiceBootstrapLevelChanged,
      super.onServiceInstanceCreated});

  @override
  T? getServiceOrNull<T>(
      {String? name, RunLevel requiredRunLevel = RunLevel.ready}) {
    return super.getServiceOrNull<T>(
            name: name, requiredRunLevel: requiredRunLevel) ??
        (scope.widget.exclusive
            ? null
            : _ServiceScopeState._maybeParentOf(scope.context)
                ?.getServiceOrNull(
                    name: name, requiredRunLevel: requiredRunLevel));
  }

  @override
  T getService<T>({String? name, RunLevel requiredRunLevel = RunLevel.ready}) {
    var svc =
        getServiceOrNull<T>(name: name, requiredRunLevel: requiredRunLevel);
    if (svc == null && !scope.widget.exclusive) {
      final parentScope = _ServiceScopeState._maybeParentOf(scope.context);
      svc = parentScope?.getServiceOrNull(
          name: name, requiredRunLevel: requiredRunLevel);
    }

    if (svc == null) {
      throw ArgumentError("No such service in scope '${this.name}'");
    }

    return svc;
  }

  @override
  Iterable<T> getServices<T>({RunLevel requiredRunLevel = RunLevel.ready}) {
    final services = super.getServices<T>(requiredRunLevel: requiredRunLevel);
    if (scope.widget.exclusive) {
      return services;
    }

    return services.followedBy(_ServiceScopeState._maybeParentOf(scope.context)
            ?.getServices(requiredRunLevel: requiredRunLevel) ??
        const []);
  }
}

typedef ServiceScopeWidgetBuilder = Widget Function(
    BuildContext context, RunLevel bootstrapLevel);

Widget _defaultBuilder(
    BuildContext context, RunLevel bootstrapLevel, Widget child) {
  if (bootstrapLevel != RunLevel.ready) {
    return Container();
  }

  return child;
}

class ServiceScope extends StatefulWidget implements MutableServiceRegistry {
  final String name;
  final ServiceScopeWidgetBuilder builder;
  final Logger logger;
  final _serviceDescriptors = <ServiceDescriptor>[];
  final bool exclusive;

  ServiceScope(
      {super.key,
      String? name,
      Widget? child,
      ServiceScopeWidgetBuilder? builder,
      this.exclusive = false})
      : logger = loggerFor(name ?? "ServiceScope", key),
        builder = builder ??
            ((context, bootstrapLevel) =>
                _defaultBuilder(context, bootstrapLevel, child!)),
        name = name ?? _generateAnonymousScopeName();

  @override
  void register(ServiceDescriptor descriptor) {
    _serviceDescriptors.add(descriptor);
  }

  void provideAs<T, U>(
    dynamic serviceInstanceOrFactory, {
    String? name,
    int priority = ServiceDescriptor.defaultPriority,
    int Function(BuildContext context)? priorityCallback,
    ServiceScopeType scope = ServiceDescriptor.defaultScope,
    bool ephemeral = false,
  }) {
    late final T Function(BuildContext) create;

    Type type = T;
    Type family = U;

    if (serviceInstanceOrFactory is T Function(BuildContext)) {
      create = serviceInstanceOrFactory;
    } else {
      if (scope == ServiceScopeType.transient) {
        throw ArgumentError("Transient services must provide a factory method");
      }

      if (type == dynamic) {
        type = serviceInstanceOrFactory.runtimeType;
      }

      create = (_) => serviceInstanceOrFactory;
    }

    if (family == dynamic) {
      family = type;
    }

    _serviceDescriptors.add(
      ServiceDescriptor(
          name: name ?? _generateAnonymousServiceName(type: type),
          create: create,
          family: family,
          type: type,
          priority: priorityCallback ?? (_) => priority,
          ephemeral: ephemeral,
          scope: scope),
    );
  }

  void provide<T>(dynamic serviceInstanceOrFactory,
          {String? name,
          int priority = ServiceDescriptor.defaultPriority,
          int Function(BuildContext context)? priorityCallback,
          ServiceScopeType scope = ServiceDescriptor.defaultScope,
          bool ephemeral = false}) =>
      provideAs<T, T>(
        serviceInstanceOrFactory,
        name: name,
        priorityCallback: priorityCallback,
        priority: priority,
        scope: scope,
        ephemeral: ephemeral,
      );

  @override
  State<StatefulWidget> createState() => _ServiceScopeState();
}

class _ServiceScopeState extends State<ServiceScope>
    implements ServiceRegistry {
  late final _ServiceProvider _provider;
  var _level = RunLevel.uninitialized;

  Future _handleBootstrapLevelChanged(RunLevel level) async {
    widget.logger.t("ServiceScope bootstrap level is now ${level.name}");
    setState(() {
      _level = level;
    });
  }

  Future _handleServiceBootstrapLevelChanged(
      ServiceDescriptor serviceDescriptor,
      service,
      RunLevel level,
      double hookExecutionTimeSeconds) async {
    if ((!serviceDescriptor.ephemeral || _logEphemeralServices) &&
        (service is Service || _logNonServiceTypes)) {
      if (hookExecutionTimeSeconds > _acceptableServiceHookExecutionTime) {
        widget.logger.w(
            "Service bootstrap level of ${serviceDescriptor.name} is now ${level.name} (took ${hookExecutionTimeSeconds}s)");
      } else {
        widget.logger.t(
            "Service bootstrap level of ${serviceDescriptor.name} is now ${level.name}");
      }
    }
  }

  Future _handleServiceInstanceCreated(
      ServiceDescriptor serviceDescriptor, dynamic instance) async {
    if ((!serviceDescriptor.ephemeral || _logEphemeralServices) &&
        (instance is Service || _logNonServiceTypes)) {
      widget.logger.t("Created service instance of ${serviceDescriptor.name}");
    }
  }

  @override
  void reassemble() {
    for (var service in _provider.getServices()) {
      if (service is Service) {
        service.onReload();
      }
    }
    super.reassemble();
  }

  @override
  void initState() {
    super.initState();

    _provider = _ServiceProvider(
      name: widget.name,
      scope: this,
      buildContextProvider: () => context,
      onBootstrapLevelChanged: _handleBootstrapLevelChanged,
      onServiceBootstrapLevelChanged: _handleServiceBootstrapLevelChanged,
      onServiceInstanceCreated: _handleServiceInstanceCreated,
    );
    for (final descriptor in widget._serviceDescriptors) {
      _provider.register(descriptor);
    }

    widget.logger.d("Bootstrapping");

    final sw = Stopwatch()..start();
    _provider.doBootstrap(context).then((_) {
      widget.logger
          .i("Bootstrapping complete after ${sw.elapsedMilliseconds / 100.0}s");
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedServiceScope(
        state: this,
        child: Builder(builder: (context) => widget.builder(context, _level)));
  }

  static _ServiceScopeState? _maybeParentOf(BuildContext context) =>
      context.findAncestorStateOfType<_ServiceScopeState>();

  @override
  Iterable<T> getServices<T>({RunLevel requiredRunLevel = RunLevel.ready}) =>
      _provider.getServices<T>(requiredRunLevel: requiredRunLevel);

  @override
  T? getServiceOrNull<T>(
      {String? name, RunLevel requiredRunLevel = RunLevel.ready}) {
    return _provider.getServiceOrNull<T>(
        name: name, requiredRunLevel: requiredRunLevel);
  }

  @override
  T getService<T>({String? name, RunLevel requiredRunLevel = RunLevel.ready}) {
    return _provider.getService<T>(
        name: name, requiredRunLevel: requiredRunLevel);
  }

  @override
  void register(ServiceDescriptor descriptor) => _provider.register(descriptor);
}

class _InheritedServiceScope extends InheritedWidget {
  final _ServiceScopeState state;

  const _InheritedServiceScope({required super.child, required this.state});

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

extension BuildContextServiceScopeExtension on BuildContext {
  ImmutableServiceRegistry get services {
    final inheritedElement =
        getElementForInheritedWidgetOfExactType<_InheritedServiceScope>();
    final scope = inheritedElement?.widget as _InheritedServiceScope?;
    assert(scope != null, 'No ServiceScope found in context');
    return scope!.state;
  }
}
