import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class CallScreen extends StatefulWidget {
  final String roomId;
  const CallScreen({super.key, required this.roomId});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();

  final Map<String, RTCPeerConnection> peerConnections = {};
  final Map<String, RTCVideoRenderer> remoteRenderers = {};

  late MediaStream localStream;
  final String userId = const Uuid().v4();

  final Map<String, dynamic> rtcConfig = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'}
    ]
  };

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    await localRenderer.initialize();

    localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    localRenderer.srcObject = localStream;

    firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('users')
        .doc(userId)
        .set({'joined': true});

    listenForUsers();
  }

  void listenForUsers() {
    firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      for (var doc in snapshot.docs) {
        if (doc.id != userId && !peerConnections.containsKey(doc.id)) {
          createPeer(doc.id);
        }
      }
    });
  }

  Future<void> createPeer(String remoteUserId) async {
    RTCPeerConnection pc = await createPeerConnection(rtcConfig);

    peerConnections[remoteUserId] = pc;

    localStream.getTracks().forEach((track) {
      pc.addTrack(track, localStream);
    });

    pc.onTrack = (event) async {
      RTCVideoRenderer renderer = RTCVideoRenderer();
      await renderer.initialize();
      renderer.srcObject = event.streams[0];
      setState(() {
        remoteRenderers[remoteUserId] = renderer;
      });
    };

    pc.onIceCandidate = (candidate) {
      firestore
          .collection('rooms')
          .doc(widget.roomId)
          .collection('signals')
          .add({
        'from': userId,
        'to': remoteUserId,
        'candidate': candidate.toMap(),
      });
    };

    RTCSessionDescription offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('signals')
        .add({
      'from': userId,
      'to': remoteUserId,
      'sdp': offer.toMap(),
    });

    listenForSignals(pc, remoteUserId);
  }

  void listenForSignals(
      RTCPeerConnection pc, String remoteUserId) {
    firestore
        .collection('rooms')
        .doc(widget.roomId)
        .collection('signals')
        .where('to', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      for (var doc in snapshot.docs) {
        var data = doc.data();

        if (data['from'] != remoteUserId) continue;

        if (data['sdp'] != null) {
          RTCSessionDescription sdp =
          RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
          await pc.setRemoteDescription(sdp);

          if (sdp.type == 'offer') {
            RTCSessionDescription answer =
            await pc.createAnswer();
            await pc.setLocalDescription(answer);

            firestore
                .collection('rooms')
                .doc(widget.roomId)
                .collection('signals')
                .add({
              'from': userId,
              'to': remoteUserId,
              'sdp': answer.toMap(),
            });
          }
        }

        if (data['candidate'] != null) {
          await pc.addCandidate(
            RTCIceCandidate(
              data['candidate']['candidate'],
              data['candidate']['sdpMid'],
              data['candidate']['sdpMLineIndex'],
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    localRenderer.dispose();
    for (var r in remoteRenderers.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Group Video Call")),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          RTCVideoView(localRenderer, mirror: true),
          ...remoteRenderers.values
              .map((r) => RTCVideoView(r))
              .toList(),
        ],
      ),
    );
  }
}
