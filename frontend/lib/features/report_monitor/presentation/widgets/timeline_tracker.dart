import 'package:flutter/material.dart';
import 'package:sigap_mobile/core/constants/app_constants.dart';

enum TimelineStatus { success, loading, failed, pending }

class TimelineStepModel {
  final String title;
  final String description;
  final String date;
  final TimelineStatus status;

  const TimelineStepModel({
    required this.title,
    required this.description,
    required this.date,
    required this.status,
  });
}

class TimelineTracker extends StatelessWidget {
  final List<TimelineStepModel> steps;

  const TimelineTracker({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return _buildTimelineItem(step, isLast);
      },
    );
  }

  Widget _buildTimelineItem(TimelineStepModel step, bool isLast) {
    // Determine colors based on status
    Color markerColor;
    Color contentBgColor;
    Color borderLeftColor;

    switch (step.status) {
      case TimelineStatus.success:
        markerColor = AppConstants.successColor;
        contentBgColor = Colors.green.withValues(alpha: 0.05);
        borderLeftColor = AppConstants.successColor;
        break;
      case TimelineStatus.failed:
        markerColor = AppConstants.errorColor;
        contentBgColor = Colors.red.withValues(alpha: 0.05);
        borderLeftColor = AppConstants.errorColor;
        break;
      case TimelineStatus.pending:
        markerColor = Colors.orange;
        contentBgColor = Colors.orange.withValues(alpha: 0.05);
        borderLeftColor = Colors.orange;
        break;
      case TimelineStatus.loading:
        markerColor = Colors.grey.shade400;
        contentBgColor = Colors.grey.shade50;
        borderLeftColor = Colors.grey.shade300;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line and Marker
          SizedBox(
            width: 40,
            child: Stack(
              children: [
                if (!isLast)
                  Positioned(
                    left: 18,
                    top: 24,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: Colors.grey.shade200,
                    ),
                  ),
                Positioned(
                  left: 8,
                  top: 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: markerColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      step.status == TimelineStatus.success
                          ? Icons.check_rounded
                          : step.status == TimelineStatus.failed
                              ? Icons.close_rounded
                              : step.status == TimelineStatus.pending
                                  ? Icons.pending_rounded
                                  : Icons.hourglass_empty_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: contentBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border(
                    left: BorderSide(
                      color: borderLeftColor,
                      width: 4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            step.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Text(
                          step.date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
