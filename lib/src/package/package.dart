import 'package:eni_svc/src/service/run_level.dart';
import 'package:eni_svc/src/service/service_provider.dart';
import 'package:eni_utils/logger.dart';
import 'package:flutter/widgets.dart';

import 'package_feature.dart';

abstract class Package with Service {
  String get name;

  String get rootPath => "packages/$name/";

  static const int defaultPriority = -15000;

  int get priority => defaultPriority;
  static final Logger _logger = loggerFor("ServicePackage");

  @override
  @mustCallSuper
  Future onPrepare(ServiceRegistry services) async {
    final features = services
        .getServices<PackageFeature>(requiredRunLevel: RunLevel.created)
        .toList();

    _logger.d(
        "Installing service package $name, found ${features.length} feature(s): "
        "${features.map((f) => f.name).join(", ")}");

    for (final feature in features) {
      feature.onApply(this);
    }
  }
}
