import 'package.dart';

abstract class PackageFeature {
  String get name;

  void onApply(Package package);
}
