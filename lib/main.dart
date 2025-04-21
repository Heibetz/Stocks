import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/buysell_page.dart';
import 'pages/AI_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

//I think this will take around 18 hours to make.
//This took about 13 hours
void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Trading App',
      theme: ThemeData(
        primarySwatch: Colors.lightBlue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 219, 232, 239), // Very light blue
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const String userId = 'lJhseiwItLLty57EMdk6';
  final List<Widget> _widgetOptions = <Widget>[
    Page1(userId: userId),
    BuySellPage(userId: userId),
    ChatPage(userId: userId),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock Trading App'),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 10.0, left: 0, right: 0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 43, 43, 43), width: 1.5),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.0),
            child: Stack(
              children: [
                BottomNavigationBar(
                  type: BottomNavigationBarType.fixed, // Ensure items are evenly distributed
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.computer),
                      label: 'AI',
                    ),
                  ],
                  currentIndex: _selectedIndex,
                  selectedItemColor: Colors.lightBlue,
                  onTap: _onItemTapped,
                ),
                Positioned(
                  left: _selectedIndex == 0 ? 0 : _selectedIndex == 1 ? MediaQuery.of(context).size.width / 3 : 2 * MediaQuery.of(context).size.width / 3,
                  top: 0,
                  bottom: 0,
                  width: MediaQuery.of(context).size.width / 3,
                  child: Container(
                    color: Colors.lightBlue.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
