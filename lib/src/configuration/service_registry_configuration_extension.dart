import 'package:eni_svc/src/service/service_provider.dart';

import 'configuration.dart';

extension ServiceRegistryConfigurationExtension on MutableServiceRegistry {
  void addConfiguration<T>(Map<String, dynamic> config,
      {Pattern? serviceNamePattern}) {
    register(makeConfigurationDescriptor(Configuration(config,
        serviceNamePattern: serviceNamePattern,
        serviceType: T == dynamic ? null : T)));
  }
}
