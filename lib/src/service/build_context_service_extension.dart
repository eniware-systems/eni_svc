import 'package:eni_svc/eni_svc.dart';
import 'package:flutter/widgets.dart';

extension BuildContextServiceExtension on BuildContext {
  /// Gets all services from the closes encapsulating [ServiceScope]
  Iterable<T> getServices<T>({RunLevel requiredRunLevel = RunLevel.ready}) =>
      services.getServices<T>(requiredRunLevel: requiredRunLevel);

  /// Gets a service from the closes encapsulating [ServiceScope]
  T getService<T>({String? name, RunLevel requiredRunLevel = RunLevel.ready}) =>
      services.getService<T>(name: name, requiredRunLevel: requiredRunLevel);

  /// Gets a service from the closes encapsulating [ServiceScope]
  T? getServiceOrNull<T>(
          {String? name, RunLevel requiredRunLevel = RunLevel.ready}) =>
      services.getServiceOrNull<T>(
          name: name, requiredRunLevel: requiredRunLevel);
}
