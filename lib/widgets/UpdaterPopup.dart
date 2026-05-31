import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_app/service/users_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdaterPopup extends StatefulWidget {
  final Widget? child;

  const UpdaterPopup({super.key, this.child});

  @override
  State<UpdaterPopup> createState() => _UpdaterPopupState();
}

class _UpdaterPopupState extends State<UpdaterPopup> {
  bool showPopup = false;
  bool closeDisabled = false;
  AppVersion? data;

@override
void initState() {
  super.initState();

  print("🔥 INIT UPDATER");

  UserService().appVersion().then((appVersion) async {
    print("📲 VERSION REMOTA: ${appVersion.androidVersionUpdater}");

    final packageInfo = await PackageInfo.fromPlatform();

    print("📱 VERSION INSTALADA: ${packageInfo.version}");

    setState(() {
      showPopup = compareVersions(
        packageInfo.version,
        appVersion.androidVersionUpdater,
      ) < 0;

      closeDisabled = compareVersions(
        packageInfo.version,
        appVersion.androidVersionMinimal,
      ) < 0;

      data = appVersion;
    });

    print("🚨 MOSTRAR POPUP: $showPopup");
  });
}

int compareVersions(String currentVersion, String targetVersion) {
  final current = currentVersion.split('.').map(int.parse).toList();
  final target = targetVersion.split('.').map(int.parse).toList();

  final maxLength =
      current.length > target.length ? current.length : target.length;

  while (current.length < maxLength) {
    current.add(0);
  }

  while (target.length < maxLength) {
    target.add(0);
  }

  for (int i = 0; i < maxLength; i++) {
    if (current[i] < target[i]) return -1;
    if (current[i] > target[i]) return 1;
  }

  return 0;
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final List<Widget> children = [];

    if (widget.child != null) children.add(widget.child!);

    if (showPopup) {
      children.add(Positioned(
        child: Center(
          child: Container(
            color: Colors.black38,
            child: Center(
              child: SizedBox(
                width: size.width * 0.8,
                height: 350.0,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Nueva actualización",
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.noScaling,
                        ),
                        Expanded(child: SizedBox()),
                        Text(
                          "Descarga la última versión para disfrutar de las últimas funcionalidades y mayor seguridad.",
                          textAlign: TextAlign.center,
                          textScaler: TextScaler.noScaling,
                        ),
                        Expanded(child: SizedBox()),
                        FilledButton(
                          onPressed: () async {
                            final link = Platform.isAndroid
                                ? data?.playStoreUrl
                                : Platform.isIOS
                                    ? data?.appStoreUrl
                                    : null;
                            if (link == null) return;
                            await launchUrl(Uri.parse(link));
                          },
                          child: Text(
                            "Descargar",
                            textScaler: TextScaler.noScaling,
                          ),
                        ),
                        SizedBox(height: 15.0),
                        closeDisabled
                            ? SizedBox()
                            : TextButton(
                                onPressed: () => setState(() {
                                  showPopup = false;
                                }),
                                child: Text(
                                  "Cerrar",
                                  textScaler: TextScaler.noScaling,
                                ),
                              )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ));
    }

    return Stack(children: children);
  }
}
