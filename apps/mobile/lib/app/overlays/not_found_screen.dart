import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../app_routes.dart';

/// V2 `NotFound` (`path: "*"`) is a replace-redirect to the camera: an
/// unknown link never shows an error page. Used as the router's
/// `errorBuilder`.
class NotFoundRedirect extends StatefulWidget {
  const NotFoundRedirect({super.key});

  @override
  State<NotFoundRedirect> createState() => _NotFoundRedirectState();
}

class _NotFoundRedirectState extends State<NotFoundRedirect> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go(AppRoutes.capture);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
