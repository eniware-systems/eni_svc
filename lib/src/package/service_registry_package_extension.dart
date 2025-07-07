import 'package:eni_svc/src/service/service_provider.dart';

import 'package_builder.dart';
import 'package_feature.dart';

extension ServiceRegistryPackageExtension on MutableServiceRegistry {
  void addFeature<T extends PackageFeature>(T feature) {
    register(_makePackageFeatureDescriptor(feature));
  }

  void addPackage<T extends PackageBuilder>(T packageBuilder) {
    register(packageBuilder.descriptor);
  }
}

ServiceDescriptor _makePackageFeatureDescriptor(PackageFeature feature) =>
    ServiceDescriptor(
      create: (context) => feature,
      priority: (context) => ServiceDescriptor.defaultPriority,
      type: PackageFeature,
      name: "ServicePackageFeature_${feature.name}",
    );
