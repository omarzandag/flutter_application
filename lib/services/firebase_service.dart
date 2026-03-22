import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/player.dart';
import '../models/session.dart';

class FirebaseService {
  late final DatabaseReference _db;

  FirebaseService() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _db = FirebaseDatabase.instance.ref().child('users').child(uid);
    } else {
      // Fallback or error state if used while unauthenticated
      _db = FirebaseDatabase.instance.ref().child('anonymous');
    }
  }

  // ========== PLAYERS ==========
  Future<void> addPlayer(Player player) async {
    await _db.child('players').push().set(player.toMap());
  }

  Future<List<Player>> getPlayers() async {
    final snapshot = await _db.child('players').get();
    if (snapshot.exists && snapshot.value != null) {
      List<Player> players = [];
      if (snapshot.value is List) {
        final dataList = snapshot.value as List;
        for (int i = 0; i < dataList.length; i++) {
          if (dataList[i] != null) {
            final playerData = Map<String, dynamic>.from(dataList[i] as Map);
            players.add(Player.fromMap(i.toString(), playerData));
          }
        }
      } else {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value != null) {
            final playerData = Map<String, dynamic>.from(value as Map);
            players.add(Player.fromMap(key.toString(), playerData));
          }
        });
      }
      return players;
    }
    return [];
  }

  Future<Player?> getPlayer(String playerId) async {
    final snapshot = await _db.child('players').child(playerId).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return Player.fromMap(playerId, data);
    }
    return null;
  }

  Future<void> updatePlayer(Player player) async {
    if (player.id != null) {
      await _db.child('players').child(player.id!).set(player.toMap());
    }
  }

  Future<void> deletePlayer(String playerId) async {
    await _db.child('players').child(playerId).remove();
  }

  Future<void> updatePlayerStatus(String playerId, String status) async {
    await _db.child('players').child(playerId).update({'status': status});
  }

  Future<void> updatePlayerStats(String playerId, Map<String, dynamic> stats) async {
    await _db.child('players').child(playerId).update(stats);
  }

  // ========== SESSIONS ==========
  Future<void> addSession(Session session) async {
    await _db.child('sessions').push().set(session.toMap());
  }

  Future<List<Session>> getSessions() async {
    final snapshot = await _db.child('sessions').get();
    if (snapshot.exists && snapshot.value != null) {
      List<Session> sessions = [];
      if (snapshot.value is List) {
        final dataList = snapshot.value as List;
        for (int i = 0; i < dataList.length; i++) {
          if (dataList[i] != null) {
            final sessionData = Map<String, dynamic>.from(dataList[i] as Map);
            sessions.add(Session.fromMap(i.toString(), sessionData));
          }
        }
      } else {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          if (value != null) {
            final sessionData = Map<String, dynamic>.from(value as Map);
            sessions.add(Session.fromMap(key.toString(), sessionData));
          }
        });
      }
      return sessions;
    }
    return [];
  }

  Future<Session?> getSession(String sessionId) async {
    final snapshot = await _db.child('sessions').child(sessionId).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return Session.fromMap(sessionId, data);
    }
    return null;
  }

  Future<void> updateSession(Session session) async {
    if (session.id != null) {
      await _db.child('sessions').child(session.id!).set(session.toMap());
    }
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.child('sessions').child(sessionId).remove();
  }

  Future<void> updateSessionAttendance(String sessionId, List<String> players) async {
    await _db.child('sessions').child(sessionId).update({
      'attendingPlayers': players,
      'playerCount': players.length,
    });
  }

  // ========== FORMATION ==========
  Future<void> saveFormation(Map<String, dynamic> formation) async {
    await _db.child('formation').set(formation);
  }

  Future<Map<String, dynamic>?> getFormation() async {
    final snapshot = await _db.child('formation').get();
    if (snapshot.exists && snapshot.value != null) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  // ========== PLAYER RATINGS ==========
  Future<void> saveSessionRatings({
    required String sessionId,
    required Map<String, int> ratings,
    required Map<String, String> notes,
  }) async {
    await _db.child('ratings').child(sessionId).set({
      'ratings': ratings,
      'notes': notes,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getSessionRatings(String sessionId) async {
    final snapshot = await _db.child('ratings').child(sessionId).get();
    if (snapshot.exists && snapshot.value != null) {
      Map<String, dynamic> data;
      if (snapshot.value is List) {
        final list = snapshot.value as List;
        data = Map<String, dynamic>.from(list.isNotEmpty ? (list.first ?? {}) : {});
      } else {
        data = Map<String, dynamic>.from(snapshot.value as Map);
      }
      return {
        'ratings': data['ratings'] != null
            ? Map<String, int>.from(
                (data['ratings'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
              )
            : <String, int>{},
        'notes': data['notes'] != null
            ? Map<String, String>.from(
                (data['notes'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
              )
            : <String, String>{},
      };
    }
    return {'ratings': <String, int>{}, 'notes': <String, String>{}};
  }

  /// Returns a player's average rating across all sessions
  Future<double> getPlayerAverageRating(String playerId) async {
    final snapshot = await _db.child('ratings').get();
    if (!snapshot.exists || snapshot.value == null) return 0.0;
    final allRatings = Map<String, dynamic>.from(snapshot.value as Map);
    int total = 0, count = 0;
    for (final session in allRatings.values) {
      final sessionData = Map<String, dynamic>.from(session as Map);
      final ratings = sessionData['ratings'] as Map?;
      if (ratings != null && ratings.containsKey(playerId)) {
        total += (ratings[playerId] as num).toInt();
        count++;
      }
    }
    return count == 0 ? 0.0 : total / count;
  }
}