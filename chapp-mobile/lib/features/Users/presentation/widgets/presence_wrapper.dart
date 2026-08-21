import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../injection.dart' as di;
import '../../domain/use_cases/update_presence_use_case.dart';

/// Drives the current user's online presence from app lifecycle events:
/// online while the app is in the foreground, offline when it is backgrounded
/// or detached. Wrap the authenticated area of the app with this.
class PresenceWrapper extends StatefulWidget {
  final Widget child;
  const PresenceWrapper({super.key, required this.child});

  @override
  State<PresenceWrapper> createState() => _PresenceWrapperState();
}

class _PresenceWrapperState extends State<PresenceWrapper>
    with WidgetsBindingObserver {
  final UpdatePresenceUseCase _updatePresence = di.sl<UpdatePresenceUseCase>();
  final FirebaseAuth _auth = di.sl<FirebaseAuth>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setOnline(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _setOnline(true);
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _setOnline(false);
    }
  }

  void _setOnline(bool online) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _updatePresence(UpdatePresenceParams(uid: uid, isOnline: online));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
