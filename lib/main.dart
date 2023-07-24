import 'dart:developer';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:phone_state_background/phone_state_background.dart';
import 'package:system_alert_window/system_alert_window.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

String _platformVersion = 'Unknown';

Future<void> showOverlayWindow(String phoneNumber) async {
  String callerName = await getCallerName(phoneNumber);

  SystemWindowHeader header = SystemWindowHeader(
    title: SystemWindowText(text: callerName, fontSize: 20, textColor: Colors.black, fontWeight: FontWeight.BOLD),
    padding: SystemWindowPadding.setSymmetricPadding(12, 12),
    subTitle: SystemWindowText(text: phoneNumber, fontSize: 14, fontWeight: FontWeight.BOLD, textColor: Colors.black87),
    decoration: SystemWindowDecoration(startColor: Colors.grey[100]),
  );
  SystemWindowBody body = SystemWindowBody(
    rows: [
      EachRow(
        columns: [EachColumn(text: SystemWindowText(text: 'هل تريد حفظ مهمة لجهة الاتصال', fontSize: 20, textColor: Colors.black, fontWeight: FontWeight.BOLD))],
        gravity: ContentGravity.CENTER,
      ),
      EachRow(
        columns: [
          EachColumn(
            text: SystemWindowText(text: "Some random description.", fontSize: 20, textColor: Colors.grey, fontWeight: FontWeight.BOLD),
          ),
        ],
        gravity: ContentGravity.CENTER,
      ),
    ],
    padding: SystemWindowPadding(left: 16, right: 16, bottom: 10, top: 10),
  );
  SystemWindowFooter footer = SystemWindowFooter(
    buttons: [
      SystemWindowButton(
        text: SystemWindowText(text: "نعم", fontSize: 15, textColor: Colors.white),
        tag: "focus_button",
        width: 0,
        padding: SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
        height: SystemWindowButton.WRAP_CONTENT,
        decoration: SystemWindowDecoration(startColor: Colors.blue, endColor: Colors.blueAccent, borderWidth: 0, borderRadius: 18.0),
      ),
      SystemWindowButton(
        text: SystemWindowText(text: "لا", fontSize: 15, textColor: Colors.white),
        tag: "simple_button",
        width: 0,
        padding: SystemWindowPadding(left: 10, right: 10, bottom: 10, top: 10),
        height: SystemWindowButton.WRAP_CONTENT,
        decoration: SystemWindowDecoration(
          startColor: Colors.blue,
          endColor: Colors.blueAccent,
          borderWidth: 0,
          borderRadius: 18.0,
        ),
      ),
    ],
    padding: SystemWindowPadding(left: 16, right: 16, bottom: 12, top: 10),
    decoration: SystemWindowDecoration(startColor: Colors.white),
    buttonsPosition: ButtonPosition.CENTER,
  );
  SystemAlertWindow.showSystemWindow(
    height: 230,
    header: header,
    body: body,
    footer: footer,
    margin: SystemWindowMargin(left: 8, right: 8, top: 200, bottom: 0),
    gravity: SystemWindowGravity.TOP,
    notificationTitle: "Incoming Call",
    notificationBody: "+1 646 980 4741",
    prefMode: SystemWindowPrefMode.OVERLAY,
    backgroundColor: Colors.grey,
    isDisableClicks: false,
  );
}

Future<String> getCallerName(String phoneNumber) async {
  String callerName = '';
  final contacts = await ContactsService.getContacts(withThumbnails: false);

  try {
    final contact = contacts.where((c1) => c1.phones!.any((phone) => phone.value!.replaceAll(' ', '').contains(phoneNumber))).firstOrNull;
    if (contact != null) {
      callerName = contact.displayName!;
      log('Incoming call from $callerName ($phoneNumber)');
      return contact.displayName!;
    } else {
      log('Incoming call from unknown number ($phoneNumber)');
    }
  } catch (e) {
    log('error');
  }

  return '';
}

@pragma('vm:entry-point')
Future<void> phoneStateBackgroundCallbackHandler(PhoneStateBackgroundEvent event, String number, int duration) async {
  switch (event) {
    case PhoneStateBackgroundEvent.incomingstart:
      log('Incoming call start, number: $number, duration: $duration s');
      break;
    case PhoneStateBackgroundEvent.incomingmissed:
      showOverlayWindow(number);
      log('Incoming call missed, number: $number, duration: $duration s');
      break;
    case PhoneStateBackgroundEvent.incomingreceived:
      log('Incoming call received, number: $number, duration: $duration s');
      break;
    case PhoneStateBackgroundEvent.incomingend:
      log('Incoming call ended, number: $number, duration $duration s');
      break;
    case PhoneStateBackgroundEvent.outgoingstart:
      log('Ougoing call start, number: $number, duration: $duration s');
      break;
    case PhoneStateBackgroundEvent.outgoingend:
      log('Ougoing call ended, number: $number, duration: $duration s');
      break;
  }
}

@pragma('vm:entry-point')
void callBack(String tag) {
  WidgetsFlutterBinding.ensureInitialized();
  log(tag);
  switch (tag) {
    case "simple_button":
    case "updated_simple_button":
      SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
      break;
    case "focus_button":
      log("Focus button has been called");
      SystemAlertWindow.closeSystemWindow(prefMode: SystemWindowPrefMode.OVERLAY);
      break;
    default:
      log("OnClick event of $tag");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phone State Background',
      theme: ThemeData(primarySwatch: Colors.blueGrey),
      home: const MyHomePage(title: 'Phone State Background'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  bool hasPermission = false;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      await _hasPermission();
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    _hasPermission();
    super.initState();
    _initPlatformState();
    _requestPermissions();
    SystemAlertWindow.registerOnClickListener(callBack);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _hasPermission() async {
    final permission = await PhoneStateBackground.checkPermission();
    if (mounted) {
      setState(() => hasPermission = permission);
    }
  }

  Future<void> _requestPermission() async {
    await PhoneStateBackground.requestPermissions();
  }

  Future<void> _stop() async {
    await PhoneStateBackground.stopPhoneStateBackground();
  }

  Future<void> _init() async {
    if (hasPermission != true) return;
    await PhoneStateBackground.initialize(phoneStateBackgroundCallbackHandler);
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initPlatformState() async {
    await SystemAlertWindow.enableLogs(true);
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = (await SystemAlertWindow.platformVersion)!;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _requestPermissions() async {
    await SystemAlertWindow.requestPermissions(prefMode: SystemWindowPrefMode.OVERLAY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Has Permission: $hasPermission',
              style: TextStyle(fontSize: 16, color: hasPermission ? Colors.green : Colors.red),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () => _requestPermission(),
                child: const Text('Check Permission'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: () => _init(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Start Listener'),
                ),
              ),
            ),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () => _stop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Background color
                ),
                child: const Text('Stop Listener'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
