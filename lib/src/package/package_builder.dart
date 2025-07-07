import 'package:eni_svc/src/configuration/configuration.dart';
import 'package:eni_svc/src/service/service_collection.dart';
import 'package:eni_svc/src/service/service_provider.dart';

import 'package.dart';

ServiceDescriptor _makePackageDescriptor(Package package) => ServiceDescriptor(
      create: (context) => package,
      priority: (context) => package.priority,
      type: Package,
      name: package.name,
    );

class _GeneratedPackage extends Package {
  @override
  final String name;

  @override
  final String rootPath;

  @override
  final int priority;

  _GeneratedPackage(
      {required this.name, required this.rootPath, required this.priority});
}

class PackageBuilder {
  PackageBuilder({required String name, int? priority})
      : _name = name,
        _priority = priority ?? Package.defaultPriority;

  String _rootPath = "";
  final String _name;
  final _config = <String, dynamic>{};
  final int _priority;

  void withRootPath(String path) {
    _rootPath = path;
  }

  void withConfigMap(Map<String, dynamic> config) {
    _config.addAll(config);
  }

  void withConfig(String key, dynamic value) {
    _config[key] = value;
  }

  ServiceDescriptor get descriptor {
    final packageDescriptor = _makePackageDescriptor(_GeneratedPackage(
        name: _name, rootPath: _rootPath, priority: _priority));

    if (_config.isEmpty) {
      return packageDescriptor;
    }

    final configDescriptor = makeConfigurationDescriptor(
        Configuration(_config, serviceNamePattern: _name));

    return makeServiceDescriptorCollection(
        descriptors: [packageDescriptor, configDescriptor]);
  }
}

PackageBuilder makePackage(String name) => PackageBuilder(name: name);
