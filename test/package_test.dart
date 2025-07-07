import 'package:eni_svc/eni_svc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class MyFeature extends PackageFeature {
  @override
  String get name => "myFeature";

  final appliedPackages = <String>[];

  @override
  void onApply(Package package) {
    appliedPackages.add(package.name);
  }
}

class MyFeaturedPackage extends Package {
  @override
  void onRegister(ServiceRegistry services) {
    services.addFeature(MyFeature());
  }

  @override
  String get name => "myFeaturedPackage";
}

void main() {
  testWidgets('custom packages can be registered and obtained', (tester) async {
    late ImmutableServiceRegistry registry;

    final scope = ServiceScope(
      builder: (context, bootstrapLevel) {
        registry = context.services;
        return Container();
      },
    )..addPackage(makePackage("myPackage"));

    await tester.pumpWidget(scope);

    expect(registry.getServiceOrNull<Package>()?.name, equals("myPackage"));
    expect(registry.getServiceOrNull(name: "myPackage"), isA<Package>());
  });

  testWidgets('all features are applied for each package', (tester) async {
    final feature = MyFeature();

    final scope = ServiceScope(
      child: Container(),
    )
      ..addFeature(feature)
      ..addPackage(makePackage("myPackage1"))
      ..addPackage(makePackage("myPackage2"));

    await tester.pumpWidget(scope);

    expect(feature.appliedPackages, containsAll(["myPackage1", "myPackage2"]));
  });

  testWidgets('packages can register new features', (tester) async {
    late ImmutableServiceRegistry registry;

    final scope = ServiceScope(
      builder: (context, bootstrapLevel) {
        registry = context.services;
        return Container();
      },
    )
      ..addPackage(makePackage("myPackage1"))
      ..addPackage(makePackage("myPackage2"))
      ..provide((_) => MyFeaturedPackage());

    await tester.pumpWidget(scope);

    final feature = registry.getService<PackageFeature>() as MyFeature;

    expect(feature.appliedPackages,
        containsAll(["myPackage1", "myPackage2", "myFeaturedPackage"]));
  });
}
