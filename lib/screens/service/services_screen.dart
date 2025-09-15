import 'package:flutter/material.dart';
import '../../widgets/services/public_services_view.dart';
import '../../utils/web_logger.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WebLogger.logWithEmoji('[ServicesScreen] BUILD APPELÉ !', '🔧', color: '#2196F3');
    return const PublicServicesView();
  }
}