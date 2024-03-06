import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'preferences.dart';

class Signaling {
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;

  void Function()? onClose;
  void Function(String)? onError;
  void Function(Map<String, dynamic>)? onMessageSend;

  void Function(String)? onPermissionError;
  void Function(MediaStream)? onLocalStream;

  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  MediaStream? get localStream => _localStream;

  Future<MediaStream?> getLocalStream() async {
    if (_localStream != null) return _localStream;

    try {
      await _initLocalStream();
      onPermissionError?.call("");
    } catch (e) {
      onPermissionError?.call(
        "Permission Denied. Cannot access "
        "${Preferences.getMicEnabled() ? 'camera/microphone' : 'camera'}"
        " without permission, Please grant permission.",
      );
    }
    return _localStream;
  }

  Future<void> updateConstrains() async {
    if (_localStream == null) return;

    _localStream!.getTracks().forEach((track) {
      track.stop();
    });

    await _initLocalStream();
    onLocalStream?.call(_localStream!);

    final senders = await _peerConnection?.getSenders();
    if (senders == null) return;

    // replace sending stream tracks
    _localStream!.getTracks().forEach((track) {
      for (final sender in senders) {
        if (sender.track?.kind == track.kind) {
          sender.replaceTrack(track);
        }
      }
    });
  }

  Future<void> _initLocalStream() async {
    final dimensions =
        Preferences.getResolution().split('x').map((res) => int.parse(res));
    // Initialize the local camera stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': Preferences.getMicEnabled(),
      'video': {
        'deviceId': Preferences.getCameraId().toString(),
        'width': dimensions.first,
        'height': dimensions.last,
        'frameRate': Preferences.getFps().toDouble(),
      },
    });
  }

  Future<void> setupPeerConnection() async {
    _peerConnection = await createPeerConnection(
      {'iceServers': [], 'sdpSemantics': 'plan-b'},
    );

    _peerConnection!.onIceCandidate = (candidate) {
      onMessageSend?.call({
        'type': 'ice_candidate',
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onIceConnectionState = (connectionState) {
      switch (connectionState) {
        case RTCIceConnectionState.RTCIceConnectionStateDisconnected:
          onClose?.call();
          break;
        case RTCIceConnectionState.RTCIceConnectionStateFailed:
          onError?.call("WebRTC connection failed.");
          break;
        default:
      }
    };
  }

  Future<void> addLocalStream() async {
    final stream = await getLocalStream();
    if (stream == null) return;

    // sdpSemantics: 'plan-b'
    await _peerConnection!.addStream(stream);

    // sdpSemantics: 'unified-plan'
    // stream.getTracks().forEach((track) {
    //   _peerConnection!.addTrack(track, stream);
    // });
  }

  Future<void> updateLocalStream() async {
    final stream = await getLocalStream();
    if (stream == null) return;

    onLocalStream?.call(stream);

    if ((await _peerConnection?.getSenders())?.isEmpty ?? false) {
      // restart peer connection, if not sending any streams.
      await close();
      await setupPeerConnection();
      _peerConnection!.addStream(stream);
      createOffer();
    }
  }

  static const _mediaConstraints = <String, dynamic>{
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Future<void> createOffer() async {
    final desc = await _peerConnection!.createOffer(_mediaConstraints);
    await _peerConnection!.setLocalDescription(desc);
    onMessageSend?.call({'type': 'offer', 'sdp': desc.sdp});
  }

  Future<void> _createAnswer() async {
    final desc = await _peerConnection!.createAnswer(_mediaConstraints);
    await _peerConnection!.setLocalDescription(desc);
    onMessageSend?.call({'type': 'answer', 'sdp': desc.sdp});
  }

  /// Returns true if the signaling message was handled, otherwise false.
  bool handleSignalingMessage(Map<String, dynamic> message) {
    assert(_peerConnection != null,
        'setupPeerConnection() must be called before calling this method.');

    switch (message['type']) {
      case 'offer':
        // Handle incoming offer
        final offer = RTCSessionDescription(message['sdp'], 'offer');
        _peerConnection!.setRemoteDescription(offer);
        _createAnswer();
        break;
      case 'answer':
        // Handle incoming answer
        final answer = RTCSessionDescription(message['sdp'], 'answer');
        _peerConnection!.setRemoteDescription(answer);
        break;
      case 'ice_candidate':
        // Handle incoming ICE candidates
        final candidate = RTCIceCandidate(
          message['candidate'],
          message['sdpMid'],
          message['sdpMLineIndex'],
        );
        _peerConnection!.addCandidate(candidate);
        break;
      default:
        return false;
    }
    return true;
  }

  Future<void> close() async {
    await _peerConnection?.close();
    _peerConnection = null;
  }

  Future<void> dispose() async {
    await _localStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
  }
}
