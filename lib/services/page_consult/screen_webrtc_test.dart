import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _initRenderers();
    _connectSignaling();
  }

  // ----------------------------
  // Media
  // ----------------------------
  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': {'facingMode': 'user'},
    });

    _localRenderer.srcObject = _localStream;
  }

  // ----------------------------
  // Signaling (FastAPI WebSocket)
  // ----------------------------
  void _connectSignaling() {
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://vincerebiohealth.kr/webrtc/ws'),
    );

    _channel.stream.listen((message) async {
      final data = jsonDecode(message);

      switch (data['type']) {
        case 'offer':
          await _createPeer();
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['sdp'], 'offer'),
          );
          final answer = await _peerConnection!.createAnswer();
          await _peerConnection!.setLocalDescription(answer);

          _send({
            'type': 'answer',
            'sdp': answer.sdp,
          });
          break;

        case 'answer':
          await _peerConnection!.setRemoteDescription(
            RTCSessionDescription(data['sdp'], 'answer'),
          );
          break;

        case 'candidate':
          await _peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
          break;
      }
    });
  }

  void _send(Map<String, dynamic> data) {
    _channel.sink.add(jsonEncode(data));
  }

  // ----------------------------
  // PeerConnection
  // ----------------------------
  Future<void> _createPeer() async {
    if (_peerConnection != null) return;

    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    });

    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (event) {
      _remoteRenderer.srcObject = event.streams.first;
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _send({
          'type': 'candidate',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };
  }

  // ----------------------------
  // Call
  // ----------------------------
  Future<void> _call() async {
    await _createPeer();
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    _send({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  // ----------------------------
  // Dispose
  // ----------------------------
  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _channel.sink.close();
    super.dispose();
  }

  // ----------------------------
  // UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebRTC 1:1 (FastAPI WS)')),
      body: Column(
        children: [
          Expanded(child: RTCVideoView(_localRenderer, mirror: true)),
          Expanded(child: RTCVideoView(_remoteRenderer)),
          ElevatedButton(onPressed: _call, child: const Text('Call')),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
