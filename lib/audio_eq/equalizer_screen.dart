import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/services.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final AudioPlayer _player = AudioPlayer();
  static const MethodChannel _channel =
  MethodChannel('real_equalizer');
  double bassBoost = 0;
  List<double> bands = [0, 0, 0, 0, 0];
  bool isBoomOn = false;
  bool bassEnabled = false;

  int? sessionId;

  @override
  void initState() {
    super.initState();
    pickAndPlayAudio();
  }

  Future<void> pickAndPlayAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result == null) return;

    final filePath = result.files.single.path!;
    await _player.setFilePath(filePath);

     sessionId = await _player.androidAudioSessionId;
    await _channel.invokeMethod('init', {
      "sessionId": sessionId,
    });

    _player.play();
  }


  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void applyDeepBass() {
    List<int> deepBass = [
      1300,   // 60Hz (subwoofer)
      600,    // bass body
      -300,   // mid cut
      -500,   // high cut
      -800,   // treble cut
    ];

    for (int i = 0; i < deepBass.length; i++) {
      bands[i] = deepBass[i].toDouble();
      _channel.invokeMethod('setBand', {
        "band": i,
        "level": deepBass[i],
      });
    }

    bassBoost = 850;
    _channel.invokeMethod('setBassBoost', {
      "strength": 850,
    });

    setState(() {});
  }


  void enableSystemBass() {
    _channel.invokeMethod('initSystem');

    // Deep bass preset
    List<int> deepBass = [1300, 600, -300, -500, -800];

    for (int i = 0; i < deepBass.length; i++) {
      _channel.invokeMethod('setBand', {
        "band": i,
        "level": deepBass[i],
      });
    }

    _channel.invokeMethod('setBassBoost', {
      "strength": 850,
    });
  }
  void disableSystemBass() {
    _channel.invokeMethod('disableSystem');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Real Equalizer")),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: enableSystemBass,
                child: const Text("Apply System Deep Bass"),
              ),
              ElevatedButton(
                onPressed: disableSystemBass,
                child: const Text("Disable System Bass"),
              ),
            ],
          ),

          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: pickAndPlayAudio,
            child: const Text("Pick Audio & Play"),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
            ElevatedButton(
              onPressed: () {
                _player.play();
              },
              child: const Text("Play"),
            ),  ElevatedButton(
              onPressed: () {
                _player.pause();
              },
              child: const Text("Pause"),
            ),
          ],),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RotatedBox(
                    quarterTurns: -1,
                    child: Slider(
                      min: -1500,
                      max: 1500,
                      value: bands[index],
                      onChanged: (value) {
                        setState(() => bands[index] = value);
                        _channel.invokeMethod('setBand', {
                          "band": index,
                          "level": value.toInt(),
                        });
                      },
                    ),
                  ),
                  Text("Band ${index + 1}")
                ],
              );
            }),
          ),
          const SizedBox(height: 10),
          const Text(
            "Bass Boost",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Slider(
            min: 0,
            max: 1000,
            value: bassBoost,
            onChanged: (value) {
              setState(() => bassBoost = value);
              _channel.invokeMethod('setBassBoost', {
                "strength": value.toInt(),
              });
            },
          ),
          ElevatedButton(
            onPressed: applyDeepBass,
            child: const Text("Deep Bass"),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isBoomOn ? Colors.green : Colors.grey,
            ),
            onPressed: () async {
              if (!isBoomOn) {
                await    _channel.invokeMethod(
                  'enableBoomSurround',
                  {'sessionId': sessionId},
                );
              } else {
                await    _channel.invokeMethod('disableBoomSurround');
              }

              setState(() {
                isBoomOn = !isBoomOn;
              });
            },
            child: Text(
              isBoomOn ? "Boom Surround ON 🎧🔥" : "Boom Surround OFF ❌",
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              if (sessionId == null) return;

              if (!bassEnabled) {
                await  _channel.invokeMethod(
                  "enableBassEnhancement",
                  {"sessionId": sessionId},
                );
              } else {
                await  _channel.invokeMethod("disableBassEnhancement");
              }

              setState(() {
                bassEnabled = !bassEnabled;
              });
            },
            child: Text(
              bassEnabled ? "Disable Bass Enhancement" : "Enable Bass Enhancement",
            ),
          ),

        ],
      )
    );
  }
}
