import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                "https://i.pravatar.cc/150?img=3",
              ),
            ),
            SizedBox(height: 10),
            Text("Rabin Chaudhary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("rabin@email.com"),
          ],
        ),
      ),
    );
  }
}