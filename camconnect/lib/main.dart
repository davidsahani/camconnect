import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

import 'pages/camera_page.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'utils/connection_manager.dart';
import 'utils/orientation_manager.dart';
import 'utils/preferences.dart';
import 'utils/settings_manager.dart';
import 'widgets/custom_navigation_bar.dart';
import 'widgets/custom_page_view.dart';
import 'widgets/dimming_overlay.dart';
import 'widgets/snack_bars.dart';
import 'widgets/swap_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(202, 6, 113, 235),
        ),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: SafeArea(
          child: MainWidget(),
        ),
      ),
    );
  }
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  int _selectedPage = 0;
  final _dimValueNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  @override
  void dispose() {
    ConnectionManager.dispose();
    super.dispose();
  }

  void _initialize() {
    SettingsManager.init();
    ConnectionManager.init();

    ConnectionManager.statusStream.listen((connectionStatus) async {
      switch (connectionStatus) {
        case ConnectionStatus.connected:
          OrientationManger.lockOrientation(Preferences.getOrientation());
          if (Preferences.getAutoDimScreenEnabled()) {
            _dimValueNotifier.value = true;
          }
          if (Preferences.getWakeLockEnabled()) {
            if (!await Wakelock.enabled) Wakelock.enable();
          }
          break;

        case ConnectionStatus.disconnected:
          OrientationManger.unlockOrientation();
          _dimValueNotifier.value = false;
          if (await Wakelock.enabled) Wakelock.disable();
          break;

        default:
      }
    });

    ConnectionManager.signaling.onPermissionError = (errorMsg) {
      if (errorMsg.isEmpty) {
        // permission granted or no permission error encountered.
        return ScaffoldMessenger.of(context).removeCurrentSnackBar();
      }

      showSnackBarPrompt(context, errorMsg, "Grant Permission", () async {
        try {
          await ConnectionManager.signaling.updateLocalStream();
        } catch (e) {
          _showSnackBarMessage(e.toString());
        }
      },
          duration: const Duration(hours: 2),
          dismissible: Preferences.getMicEnabled());

      if (Preferences.getMicEnabled()) {
        Preferences.setMicEnabled(false);
      }
    };

    ConnectionManager.onError = _showSnackBarMessage;
    ConnectionManager.connect(); // start the connection on application start.
  }

  void _showSnackBarMessage(String msg) => showSnackBarMessage(context, msg);

  @override
  Widget build(BuildContext context) {
    final bool swap = _selectedPage == 1 &&
        MediaQuery.of(context).orientation == Orientation.landscape;

    return DimmingOverlay(
      maxOpacity: 0.8, // pretty dim
      dimValueNotifier: _dimValueNotifier,
      child: SwapLayout(swap: swap, children: [
        CustomPageView(
          currentPage: _selectedPage,
          onPageChanged: _changePage,
          children: const [
            HomePage(),
            CameraPage(),
            SettingsPage(),
          ],
        ),
        RotatedBox(
          quarterTurns: swap ? -1 : 0,
          child: CustomNavigationBar(
            _selectedPage,
            _changePage,
          ),
        )
      ]),
    );
  }

  void _changePage(int currentPage) {
    if (currentPage != _selectedPage) {
      setState(() {
        _selectedPage = currentPage;
      });
    }
  }
}
