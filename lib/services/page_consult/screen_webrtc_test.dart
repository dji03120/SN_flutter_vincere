// pubspec.yaml
// dependencies:
//   flutter_webrtc: ^0.11.0
//   socket_io_client: ^2.0.3

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class WebRTCSample extends StatefulWidget {
  const WebRTCSample({super.key});

  @override
  State<WebRTCSample> createState() => _WebRTCSampleState();
}

class _WebRTCSampleState extends State<WebRTCSample> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    _initRenderers();
    _connectSignaling();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });
    _localRenderer.srcObject = _localStream;
  }

  void _connectSignaling() {
    socket = IO.io('https://YOUR_SIGNALING_SERVER', IO.OptionBuilder().setTransports(['websocket']).build());

    socket.on('offer', (data) async {
      await _createPeer();
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      socket.emit('answer', {'sdp': answer.sdp});
    });

    socket.on('answer', (data) async {
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
    });

    socket.on('candidate', (data) async {
      await _peerConnection!.addCandidate(RTCIceCandidate(data['candidate'], data['sdpMid'], data['sdpMLineIndex']));
    });
  }

  Future<void> _createPeer() async {
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'}
      ]
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (event) {
      _remoteRenderer.srcObject = event.streams.first;
    };

    _peerConnection!.onIceCandidate = (candidate) {
      socket.emit('candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };
  }

  Future<void> _call() async {
    await _createPeer();
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    socket.emit('offer', {'sdp': offer.sdp});
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebRTC 1:1 Example')),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
          Expanded(child: RTCVideoView(_remoteRenderer)),
          ElevatedButton(onPressed: _call, child: const Text('Call')),
        ],
      ),
    );
  }
}
