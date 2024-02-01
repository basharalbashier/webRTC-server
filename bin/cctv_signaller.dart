import 'dart:convert';
import 'dart:io';

_format(String type, data) =>
    json.encoder.convert({"type": type, "data": data});
Map<String, dynamic> candidates = {};

class CctvSockitManager {
  final _peer = <dynamic, WebSocket>{};
  String get updatetdPeersList =>
      _format("peers", _peer.entries.map((e) => e.key).toList());

  void init(WebSocket socket) {
    socket.listen((event) async {
      var message = jsonDecode(event);
      switch (message['type']) {
        case 'new':
          subscribe(message['data'], socket);
          break;
        case 'candidate':
          print(message);
          message['data']['to'] == "any"
              ? broadcastMessage(_format("candidateList",
                      candidates.entries.map((e) => e.value).toList()))
                  .then((value) =>
                      candidates[message['data']['from']] = message['data'])
              : sendToOne(message);
          break;
        default:
          sendToOne(message);
          break;
      }
      await socket.done
          .then((value) => remove(message['data']))
          .catchError((e) => {});
    });
  }

  void subscribe(dynamic peer, WebSocket socket) async {
    _peer[peer] = socket;
    await broadcastMessage(updatetdPeersList);
    await broadcastMessage(
        _format("candidateList", candidates.entries.map((e) => e.value).toList()));
  }

  void sendToOne(dynamic message) {
    switch (message['data']['to']) {
      case (null):
        {
          var ids = message['data']['session_id'].toString().split("-");
          var to = ids[0];
          var from = ids[1];
          _peer.forEach((key, value) => key['id'] == to || key['id'] == from
              ? value.add(json.encoder.convert(message))
              : null);
        }
        break;
      default:
        {
          var to = message['data']['to'];
          _peer.forEach((key, value) => key['id'] == to
              ? value.add(json.encoder.convert(message))
              : null);
        }
        break;
    }
  }

  Future<void> broadcastMessage(message) async {
    _peer.forEach((peer, socket) => socket.add(message));
  }

  void remove(dynamic peer) async {
    try {
      await _peer[peer]!.close().then((value) => _peer.remove(peer));
    } catch (e) {
      rethrow;
    }
    // broadcastMessage(_format("leave", peer["id"]));
    broadcastMessage(updatetdPeersList);
  }
}
