import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_scope.dart';
import 'screens/home_shell.dart';
import 'screens/idiom_detail_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/app_state.dart';
import 'services/idiom_repository.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = await IdiomRepository.load();
  final state = await AppState.load();
  final notifications = NotificationService();
  await notifications.init();

  state.onScheduleChanged = () => notifications.reschedule(state, repo);

  runApp(RedewendixApp(state: state, repo: repo, notifications: notifications));

  unawaited(notifications.reschedule(state, repo));
}

class RedewendixApp extends StatefulWidget {
  const RedewendixApp({
    super.key,
    required this.state,
    required this.repo,
    required this.notifications,
  });

  final AppState state;
  final IdiomRepository repo;
  final NotificationService notifications;

  @override
  State<RedewendixApp> createState() => _RedewendixAppState();
}

class _RedewendixAppState extends State<RedewendixApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<int>? _tapSub;

  @override
  void initState() {
    super.initState();
    _tapSub = widget.notifications.taps.listen(_openFromNotification);
    final launchId = widget.notifications.launchIdiomId;
    if (launchId != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openFromNotification(launchId),
      );
    }
  }

  void _openFromNotification(int idiomId) {
    final idiom = widget.repo.byId(idiomId);
    final nav = _navigatorKey.currentState;
    if (idiom == null || nav == null) return;
    nav.push(
      MaterialPageRoute<void>(builder: (_) => IdiomDetailScreen(idiom: idiom)),
    );
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      repo: widget.repo,
      notifications: widget.notifications,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) => MaterialApp(
          title: 'Redewendix',
          navigatorKey: _navigatorKey,
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          supportedLocales: const [Locale('de')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: widget.state.themeMode,
          builder: (context, child) {
            // Eigene Schriftgröße zusätzlich zur System-Einstellung.
            final mq = MediaQuery.of(context);
            final system = mq.textScaler.scale(16) / 16;
            return MediaQuery(
              data: mq.copyWith(
                textScaler: TextScaler.linear(system * widget.state.textScale),
              ),
              child: child!,
            );
          },
          home: const _Start(),
        ),
      ),
    );
  }
}

/// Zeigt beim ersten Start das Onboarding, danach die App.
class _Start extends StatelessWidget {
  const _Start();

  @override
  Widget build(BuildContext context) =>
      AppScope.of(context).state.onboardingDone
      ? const HomeShell()
      : const OnboardingScreen();
}

ThemeData buildTheme(Brightness brightness) {
  const seed = Color(0xFF2F6B5A);
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
    useMaterial3: true,
  );
}
