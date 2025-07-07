import 'package:eni_svc/eni_svc.dart';
import 'package:flutter/widgets.dart';

class ServiceListener<T extends ChangeNotifier> extends StatelessWidget {
  final T? service;
  final String? serviceName;
  final RunLevel requiredRunLevel;
  final Widget Function(BuildContext context, T service) builder;

  const ServiceListener(
      {super.key,
      this.service,
      this.serviceName,
      required this.builder,
      this.requiredRunLevel = RunLevel.ready});

  @override
  Widget build(BuildContext context) {
    final svc = service ??
        context.getService<T>(
            name: serviceName, requiredRunLevel: requiredRunLevel);

    return ListenableBuilder(
        listenable: svc, builder: (context, child) => builder(context, svc));
  }
}
