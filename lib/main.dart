import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whatsapp_chat_direct/adaptive_ui_core.dart';
import 'package:whatsapp_chat_direct/app_launcher/app_launcher.dart';
import 'package:whatsapp_chat_direct/audio_eq/equalizer_screen.dart';
import 'package:whatsapp_chat_direct/custome_pain_cliper/custome_pain_cliper.dart';
import 'package:whatsapp_chat_direct/firebase_options.dart';
import 'package:whatsapp_chat_direct/text_style_copy/text_style_copy.dart';
import 'package:whatsapp_chat_direct/video_call/JoinScreen.dart';
import 'package:whatsapp_chat_direct/video_edit/video_edit.dart';


Future<void> main() async {

  // 🔑 Flutter engine + plugins ready
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase initialize
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home:  CustomePainCliper(),
    );
  }
}

class OpenWhatsapp extends StatelessWidget {
   OpenWhatsapp({super.key});
  TextEditingController number =TextEditingController();

  Future<void> openWhatsappChat(String phone) async {
    final Uri url = Uri.parse("https://wa.me/$phone");
   print(url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch WhatsApp';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AdaptiveUI.of(context);


    return Scaffold(
      appBar: AppBar(title: const Text("WhatsApp Open")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding:  EdgeInsets.all(ui.w(20)),
              child: TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(hint: Text("number"),border: OutlineInputBorder()),
                controller: number,
              ),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () {
                openWhatsappChat("91${number.text}");
              },
              child:  Text("Open WhatsApp Chat",style:  TextStyle(fontSize: ui.sp(10)),),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () {
             Navigator.push(context, DialogRoute(context: context, builder: (context) => EqualizerScreen(),));
              },
              child: const Text("EQ"),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, DialogRoute(context: context, builder: (context) => JoinScreen(),));
              },
              child: const Text("youtube video playe"),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.video,
                );
                if (result != null) {
                  File file = File(result.files.single.path!);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) {
                      return TrimmerView(file);
                    }),
                  );
                }



              },
              child: const Text("edit video"),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return AppLauncherScreen();
                  }),
                );

              },
              child: const Text("App launcher"),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return FontScannerPage();
                  }),
                );

              },
              child: const Text("fast dev"),
            ),
            SizedBox(height: ui.h(50),),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    return CustomePainCliper();
                  }),
                );

              },
              child: const Text("paint"),
            ),
          ],
        ),
      ),
    );
  }
}

