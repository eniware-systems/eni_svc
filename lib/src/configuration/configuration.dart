import 'package:eni_svc/eni_svc.dart';

/// This class provides service specific or global configuration parameters.
/// Usually you want to provide these using the [addConfiguration] extension method
/// on a [ServiceRegistry] instance.
class Configuration {
  final Pattern? serviceNamePattern;
  final Type? serviceType;

  final Map<String, dynamic> _config;

  Map<String, dynamic> get config => Map.unmodifiable(_config);

  Configuration(Map<String, dynamic> config,
      {this.serviceNamePattern, this.serviceType})
      : _config = config;

  T get<T>(String key, T defaultValue) {
    return getOrNull<T>(key) ?? defaultValue;
  }

  T? getOrNull<T>(String key) {
    final value = _config[key];

    if (value == null || value is! T) {
      return null;
    }

    return value;
  }
}

int _nextId = 0;

ServiceDescriptor makeConfigurationDescriptor(Configuration configuration) =>
    ServiceDescriptor.from<Configuration>(
        create: (_) => configuration, name: "Configuration${++_nextId}");
