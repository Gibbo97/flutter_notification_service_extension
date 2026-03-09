import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

@pragma('vm:entry-point')
void notificationServiceExtension() {
  WidgetsFlutterBinding.ensureInitialized();
  print("Hello from Dart in NSE!");
  const MethodChannel channel = MethodChannel("com.example.nse/channel");
  channel.invokeMethod<void>("done");
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const MethodChannel _apnsChannel = MethodChannel("com.example.apns/token");

  int _counter = 0;
  String? _apnsToken;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _copyApnsToken() async {
    try {
      final String? token = await _apnsChannel.invokeMethod<String>("getApnsToken");
      if (token == null) {
        return;
      }
      if (mounted) {
        setState(() {
          _apnsToken = token;
        });
      }
      await Clipboard.setData(ClipboardData(text: token));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("APNS token copied")),
        );
      }
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("APNS token not yet available")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text("You have pushed the button this many times:"),
            Text(
              "$_counter",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _copyApnsToken,
              child: const Text("Copy APNS Token"),
            ),
            if (_apnsToken != null) ...[
              const SizedBox(height: 8),
              Text(
                "${_apnsToken!.substring(0, 16)}...",
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: "Increment",
        child: const Icon(Icons.add),
      ),
    );
  }
}
