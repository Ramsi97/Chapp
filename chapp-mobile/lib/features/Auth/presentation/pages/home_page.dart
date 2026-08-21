// The Auth feature no longer owns the home screen. The real, data-backed chat
// list now lives in the Chat feature; this re-export keeps older imports of
// `Auth/presentation/pages/home_page.dart` pointing at the right widget.
export 'package:chapp/features/Chat/presentation/pages/home_page.dart';
