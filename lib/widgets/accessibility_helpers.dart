import 'package:flutter/material.dart';

import '../models/optimus_models.dart';
import '../utils/glucose_utils.dart';
import '../l10n/app_strings.dart';

/// Accessibility helper widgets and utilities.
/// Wraps common UI elements with proper Semantics for screen readers.

/// Wraps a glucose value display with semantic label.
class GlucoseValueSemantics extends StatelessWidget {
  const GlucoseValueSemantics({
    super.key,
    required this.value,
    required this.status,
    required this.trend,
    required this.child,
  });

  final int value;
  final GlucoseStatus status;
  final TrendDirection trend;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '$value ${AppStrings.mgDl}, '
          '${glucoseStatusLabel(status)}, '
          '${trendLabel(trend)}',
      value: value.toString(),
      child: ExcludeSemantics(child: child),
    );
  }
}

/// Wraps a chart with semantic label.
class ChartSemantics extends StatelessWidget {
  const ChartSemantics({
    super.key,
    required this.readingCount,
    required this.duration,
    required this.child,
  });

  final int readingCount;
  final String duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${AppStrings.glucoseChartLabel}, '
          'showing $readingCount readings over $duration',
      child: child,
    );
  }
}

/// Wraps an alert item with semantic label.
class AlertSemantics extends StatelessWidget {
  const AlertSemantics({super.key, required this.alert, required this.child});

  final GlucoseAlert alert;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${alert.severity == AlertSeverity.urgent ? "Urgent" : "Warning"} alert: '
          '${alert.title}, ${alert.value} ${AppStrings.mgDl}',
      child: child,
    );
  }
}
