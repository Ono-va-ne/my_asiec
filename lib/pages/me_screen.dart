import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../pages/settings_screen.dart';

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          children: [
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Настройки', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ),
            ),
            // OneTap(
            //   scenario: OneTapTitleScenario.signIn,
            //   style: OneTapStyle(
            //     type: OneTapType.system,
            //     cornersStyle: const OneTapCornersDefault(),
            //     size: OneTapSize.standard,
            //   ),
            //   key: GlobalKey(), onAuth: (oAuth, data) {
                
            //   },
            // )
          ],
        ),
      ),
    );
  }
}