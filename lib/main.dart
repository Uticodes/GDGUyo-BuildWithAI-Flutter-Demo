import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'chat/chat_screen.dart';



void main() async {
  await dotenv.load(fileName: ".env", mergeWith: Platform.environment);
  runApp(const GenerativeAIDemo());
}

class GenerativeAIDemo extends StatelessWidget {
  const GenerativeAIDemo({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter + Generative AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color.fromARGB(255, 171, 222, 244),
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(title: 'Flutter Generative AI Demo'),
    );
  }
}
