#!/usr/bin/env python3
"""Erzeugt die Ordner android/ und ios/ und trägt alle nötigen
Einstellungen für Benachrichtigungen ein.

Aufruf (im Projektordner):  python3 tool/setup_platforms.py

Das Skript kann gefahrlos mehrmals ausgeführt werden.
"""
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ORG = "bq.p526"
BUNDLE_ID = "bq.p526.rede"  # Bundle-ID / applicationId (Android + iOS)



def run(cmd):
    print("$", " ".join(cmd))
    subprocess.run(cmd, cwd=ROOT, check=True)


def patch(path, fn):
    p = ROOT / path
    if not p.exists():
        print(f"! {path} nicht gefunden – übersprungen")
        return
    old = p.read_text(encoding="utf-8")
    new = fn(old)
    if new != old:
        p.write_text(new, encoding="utf-8")
        print(f"✓ {path} angepasst")
    else:
        print(f"· {path} bereits aktuell")


def write(path, content):
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content, encoding="utf-8")
    print(f"✓ {path} geschrieben")


# 1) Plattform-Ordner erzeugen (vorhandene Dateien bleiben unverändert)
run(["flutter", "create", "--org", ORG, "--project-name", "redewendix",
     "--platforms", "android,ios", "."])

# Von flutter create erzeugten Beispieltest entfernen (verweist auf MyApp)
wt = ROOT / "test" / "widget_test.dart"
if wt.exists() and "MyApp" in wt.read_text(encoding="utf-8"):
    wt.unlink()
    print("✓ test/widget_test.dart (Beispiel) entfernt")


# 2) Android: Gradle – Desugaring (für flutter_local_notifications)
def gradle_kts(s):
    if "isCoreLibraryDesugaringEnabled" not in s:
        s = s.replace("compileOptions {",
                      "compileOptions {\n        isCoreLibraryDesugaringEnabled = true", 1)
    if "desugar_jdk_libs" not in s:
        s = s.rstrip() + '\n\ndependencies {\n    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n}\n'
    return s


def gradle_groovy(s):
    if "coreLibraryDesugaringEnabled" not in s:
        s = s.replace("compileOptions {",
                      "compileOptions {\n        coreLibraryDesugaringEnabled true", 1)
    if "desugar_jdk_libs" not in s:
        s = s.rstrip() + "\n\ndependencies {\n    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n}\n"
    return s


def set_app_id(s):
    s = re.sub(r'namespace\s*=\s*"[^"]*"', f'namespace = "{BUNDLE_ID}"', s, count=1)
    s = re.sub(r'applicationId\s*=\s*"[^"]*"', f'applicationId = "{BUNDLE_ID}"', s, count=1)
    s = re.sub(r"namespace\s+['\"][^'\"]*['\"]", f'namespace "{BUNDLE_ID}"', s, count=1)
    s = re.sub(r"applicationId\s+['\"][^'\"]*['\"]", f'applicationId "{BUNDLE_ID}"', s, count=1)
    return s


# MainActivity in das Paket der Bundle-ID verschieben
kotlin = ROOT / "android/app/src/main/kotlin"
target = kotlin.joinpath(*BUNDLE_ID.split(".")) / "MainActivity.kt"
if not target.exists():
    for f in kotlin.rglob("MainActivity.kt"):
        target.parent.mkdir(parents=True, exist_ok=True)
        src = f.read_text(encoding="utf-8")
        target.write_text(re.sub(r"^package .*$", f"package {BUNDLE_ID}", src, count=1, flags=re.M), encoding="utf-8")
        f.unlink()
        print(f"✓ MainActivity nach {target.relative_to(ROOT)} verschoben")
        break

if (ROOT / "android/app/build.gradle.kts").exists():
    patch("android/app/build.gradle.kts", set_app_id)
else:
    patch("android/app/build.gradle", set_app_id)

if (ROOT / "android/app/build.gradle.kts").exists():
    patch("android/app/build.gradle.kts", gradle_kts)
else:
    patch("android/app/build.gradle", gradle_groovy)


# 3) Android: Manifest
PERMS = """    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
"""

APP_ENTRIES = """        <!-- Geplante Benachrichtigungen (flutter_local_notifications) -->
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
"""


def manifest(s):
    if "POST_NOTIFICATIONS" not in s:
        s = s.replace("<application", PERMS + "    <application", 1)
    if "ScheduledNotificationReceiver" not in s:
        s = s.replace("</application>", APP_ENTRIES + "    </application>", 1)
    s = s.replace('android:label="redewendix"', 'android:label="Redewendix"')
    return s


patch("android/app/src/main/AndroidManifest.xml", manifest)

# Monochromes Benachrichtigungs-Icon (Sprechblase mit Anführungszeichen)
write("android/app/src/main/res/drawable/ic_stat_redewendix.xml", """<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp" android:height="24dp"
    android:viewportWidth="24" android:viewportHeight="24">
    <path android:fillColor="#FFFFFFFF"
        android:pathData="M4,3h16a2,2 0,0 1,2 2v11a2,2 0,0 1,-2 2H9l-5,4v-4H4a2,2 0,0 1,-2 -2V5a2,2 0,0 1,2 -2zM7.5,8.5v3h1.5c0,1 -0.5,1.6 -1.5,1.8v1.2c1.9,-0.2 3,-1.5 3,-3.5V8.5zM13.5,8.5v3h1.5c0,1 -0.5,1.6 -1.5,1.8v1.2c1.9,-0.2 3,-1.5 3,-3.5V8.5z"/>
</vector>
""")

# Verhindert, dass R8 das Icon im Release-Build entfernt
write("android/app/src/main/res/raw/keep.xml", """<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_redewendix" />
""")


# 4) iOS: Info.plist
PLIST_ENTRIES = """	<key>CFBundleLocalizations</key>
	<array>
		<string>de</string>
	</array>
	<key>ITSAppUsesNonExemptEncryption</key>
	<false/>
"""


def plist(s):
    if "CFBundleLocalizations" not in s:
        idx = s.rfind("</dict>")
        s = s[:idx] + PLIST_ENTRIES + s[idx:]
    s = re.sub(r"(<key>CFBundleDisplayName</key>\s*<string>)[^<]*(</string>)",
               r"\1Redewendix\2", s)
    return s


patch("ios/Runner/Info.plist", plist)

patch("ios/Runner.xcodeproj/project.pbxproj", lambda s: re.sub(
    r"PRODUCT_BUNDLE_IDENTIFIER = [^;]*?(\.RunnerTests)?;",
    lambda m: f"PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}{m.group(1) or ''};", s))


# 5) iOS: AppDelegate – Delegate für Mitteilungen setzen
def app_delegate(s):
    if "UNUserNotificationCenter.current().delegate" in s:
        return s
    if "import UserNotifications" not in s:
        s = s.replace("import UIKit", "import UIKit\nimport UserNotifications", 1)
    return re.sub(
        r"(didFinishLaunchingWithOptions launchOptions: \[UIApplication\.LaunchOptionsKey: Any\]\?\s*\)\s*->\s*Bool\s*\{)",
        r"\1\n    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate",
        s, count=1)


patch("ios/Runner/AppDelegate.swift", app_delegate)

# 6) Pakete holen
run(["flutter", "pub", "get"])

print("\nFertig. Starten mit:  flutter run")
