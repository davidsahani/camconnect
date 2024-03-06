import 'package:flutter_webrtc/flutter_webrtc.dart';

class Signaling {
  MediaStream? _remoteStream;
  RTCPeerConnection? _peerConnection;

  void Function()? onClose;
  void Function(String)? onError;
  void Function(Map<String, dynamic>)? onMessageSend;

  void Function(MediaStream)? onRemoteStream;

  bool get isConnected =>
      _peerConnection?.connectionState ==
      RTCPeerConnectionState.RTCPeerConnectionStateConnected;

  MediaStream? get remoteStream => _remoteStream;

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

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      onRemoteStream?.call(stream);
    };
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
    await _remoteStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
  }
}
