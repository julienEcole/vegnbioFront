import 'package:flutter/material.dart';
import '../../widgets/events/public_events_view.dart';
import '../../utils/web_logger.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[EventsScreen] BUILD APPELÉ !', '🎉', color: '#FF9800');
    return const PublicEventsView();
  }
}