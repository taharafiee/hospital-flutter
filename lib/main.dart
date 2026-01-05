import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'pages/common/splash_page.dart';
import 'pages/auth/login_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    /// بعد از اولین فریم، چک آپدیت انجام میشه
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  // ================= UPDATE CHECK =================

  Future<void> _checkForUpdate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version; // مثلا 1.3.1

      final res = await http.get(
        Uri.parse(
          'https://api.github.com/repos/taharafiee/hospital-flutter/releases/latest',
        ),
        headers: {
          'Accept': 'application/vnd.github+json',
          'User-Agent': 'hospital-flutter-app',
        },
      );

      if (res.statusCode != 200) {
        SplashScreen.blockNavigation = false;
        return;
      }

      final data = jsonDecode(res.body);
      final latestVersion =
          (data['tag_name'] as String).replaceFirst('v', '');

      if (!_isNewerVersion(currentVersion, latestVersion)) {
        SplashScreen.blockNavigation = false;
        return;
      }

      final assets = data['assets'] as List;
      final apk = assets.firstWhere(
        (e) => e['name'].toString().endsWith('.apk'),
        orElse: () => null,
      );

      if (apk == null) {
        SplashScreen.blockNavigation = false;
        return;
      }

      _showUpdateDialog(
        apk['browser_download_url'],
        latestVersion,
      );
    } catch (e) {
      SplashScreen.blockNavigation = false;
    }
  }

  bool _isNewerVersion(String current, String latest) {
    final c = current.split('.').map(int.parse).toList();
    final l = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < 3; i++) {
      if (l[i] > c[i]) return true;
      if (l[i] < c[i]) return false;
    }
    return false;
  }

  // ================= UPDATE UI =================

  void _showUpdateDialog(String url, String version) {
    final context = navigatorKey.currentContext!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'Version $version is available.\nDo you want to download it now?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              SplashScreen.blockNavigation = false;
              Navigator.of(context).pop();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadWithProgress(url);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  // ================= DOWNLOAD =================

  Future<void> _downloadWithProgress(String url) async {
    final context = navigatorKey.currentContext!;
    SplashScreen.blockNavigation = true;

    double progress = 0;
    bool indeterminate = true;

    late void Function(void Function()) dialogSetState;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (_, setState) {
          dialogSetState = setState;
          return AlertDialog(
            title: const Text('Downloading update'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: indeterminate ? null : progress,
                ),
                const SizedBox(height: 12),
                Text(
                  indeterminate
                      ? 'Preparing download...'
                      : '${(progress * 100).toStringAsFixed(0)} %',
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      final dir = await getExternalStorageDirectory();
      final file = File('${dir!.path}/hospital_update.apk');

      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      final total = response.contentLength;
      if (total != null && total > 0) {
        indeterminate = false;
      }

      int received = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        received += chunk.length;
        sink.add(chunk);

        if (!indeterminate && total != null) {
          dialogSetState(() {
            progress = (received / total).clamp(0.0, 1.0);
          });
        }
      }

      await sink.close();

      Navigator.of(context).pop();
      SplashScreen.blockNavigation = false;
      await OpenFilex.open(file.path);
    } catch (_) {
      SplashScreen.blockNavigation = false;
      Navigator.of(context).pop();
    }
  }

  // ================= APP =================

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Hospital App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}
