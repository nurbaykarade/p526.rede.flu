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
import 'services/pro_service.dart';
import 'services/widget_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = await IdiomRepository.load();
  final state = await AppState.load();
  final notifications = NotificationService();
  await notifications.init();
  final widgets = WidgetService();
  await widgets.init();
  final pro = ProService();
  unawaited(pro.init(state));

  state.onScheduleChanged = () => notifications.reschedule(state, repo);

  runApp(
    RedewendixApp(
      state: state,
      repo: repo,
      notifications: notifications,
      widgets: widgets,
      pro: pro,
    ),
  );

  unawaited(notifications.reschedule(state, repo));
  unawaited(widgets.update(repo));
}

class RedewendixApp extends StatefulWidget {
  const RedewendixApp({
    super.key,
    required this.state,
    required this.repo,
    required this.notifications,
    this.widgets,
    this.pro,
  });

  final AppState state;
  final IdiomRepository repo;
  final NotificationService notifications;

  /// Startbildschirm-Widget; in Tests weggelassen.
  final WidgetService? widgets;

  /// Pro-Kauf; in Tests ohne Store.
  final ProService? pro;

  @override
  State<RedewendixApp> createState() => _RedewendixAppState();
}

class _RedewendixAppState extends State<RedewendixApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final ProService _pro = widget.pro ?? ProService();
  StreamSubscription<int>? _tapSub;
  StreamSubscription<int>? _widgetTapSub;
  AppLifecycleListener? _lifecycle;

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

    final widgets = widget.widgets;
    if (widgets != null) {
      _widgetTapSub = widgets.taps.listen(_openFromNotification);
      widgets.launchIdiomId().then((id) {
        if (id != null) _openFromNotification(id);
      });
      // Beim Zurückkehren in die App: Vorrat des Widgets auffüllen.
      _lifecycle = AppLifecycleListener(
        onResume: () => widgets.update(widget.repo),
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
    _widgetTapSub?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      repo: widget.repo,
      notifications: widget.notifications,
      pro: _pro,
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
