import 'package:flutter/material.dart';
import 'package:vkid_flutter_sdk/library_vkid.dart';

class VkScreen extends StatelessWidget {
  const VkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return OneTap(
        key: GlobalKey(),
        onAuth: (oAuth, data) {
            // ...
        },
    );
  }
}