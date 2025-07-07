import 'service_provider.dart';

class ServiceCollection with Service {
  final List<ServiceDescriptor> descriptors;

  ServiceCollection._({required this.descriptors});

  @override
  void onRegister(ServiceRegistry services) {
    for (final descriptor in descriptors) {
      services.register(descriptor);
    }
  }
}

int _nextId = 0;

ServiceDescriptor makeServiceDescriptorCollection(
    {required List<ServiceDescriptor> descriptors}) {
  return ServiceDescriptor.from(
      name: "ServiceCollection${++_nextId}",
      create: (_) => ServiceCollection._(descriptors: descriptors),
      ephemeral: true);
}
