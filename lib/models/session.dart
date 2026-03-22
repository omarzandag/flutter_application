class Session {
  String? id;
  String title;
  String teamA;
  String teamB;
  String date;
  String timeStart;
  String duration;
  String stadium;
  List<String> attendingPlayers;
  int playerCount;

  Session({
    this.id,
    required this.title,
    this.teamA = '',
    this.teamB = '',
    required this.date,
    required this.timeStart,
    this.duration = '90 min',
    this.stadium = 'Main Field',
    this.attendingPlayers = const [],
    this.playerCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'teamA': teamA,
      'teamB': teamB,
      'date': date,
      'timeStart': timeStart,
      'duration': duration,
      'stadium': stadium,
      'attendingPlayers': attendingPlayers,
      'playerCount': playerCount,
    };
  }

  factory Session.fromMap(String id, Map<String, dynamic> map) {
    return Session(
      id: id,
      title: map['title']?.toString() ?? 'Training Session',
      teamA: map['teamA']?.toString() ?? '',
      teamB: map['teamB']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      timeStart: map['timeStart']?.toString() ?? '',
      duration: map['duration']?.toString() ?? '90 min',
      stadium: map['stadium']?.toString() ?? 'Main Field',
      attendingPlayers: List<String>.from(map['attendingPlayers'] ?? []),
      playerCount: map['playerCount'] is int ? map['playerCount'] : int.tryParse(map['playerCount']?.toString() ?? '0') ?? 0,
    );
  }

  DateTime? get scheduledDateTime {
    try {
      final dateParts = date.split('/');
      if (dateParts.length != 3) return null;
      
      final day = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final year = int.parse(dateParts[2]);

      int hour = 0;
      int minute = 0;
      
      final timeRegex = RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false);
      final match = timeRegex.firstMatch(timeStart);
      
      if (match != null) {
        hour = int.parse(match.group(1)!);
        minute = int.parse(match.group(2)!);
        final period = match.group(3)?.toUpperCase();
        
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
      }

      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  bool get isPassed {
    final dt = scheduledDateTime;
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }
}