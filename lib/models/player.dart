class Player {
  String? id;
  String fullName;
  int age;
  int shirtNumber;
  String position;
  String team;
  String status; // Available, Absent, Injured
  int goals;
  int assists;
  int yellowCards;
  int redCards;
  List<String> trainingHistory;
  double xPos;
  double yPos;

  Player({
    this.id,
    required this.fullName,
    required this.age,
    required this.shirtNumber,
    required this.position,
    required this.team,
    this.status = 'Available',
    this.goals = 0,
    this.assists = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.trainingHistory = const [],
    this.xPos = 0,
    this.yPos = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'fullName': fullName,
      'age': age,
      'shirtNumber': shirtNumber,
      'position': position,
      'team': team,
      'status': status,
      'goals': goals,
      'assists': assists,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'trainingHistory': trainingHistory,
      'xPos': xPos,
      'yPos': yPos,
    };
  }

  factory Player.fromMap(String id, Map<String, dynamic> map) {
    return Player(
      id: id,
      fullName: map['fullName']?.toString() ?? '',
      age: map['age'] is int ? map['age'] : int.tryParse(map['age']?.toString() ?? '0') ?? 0,
      shirtNumber: map['shirtNumber'] is int ? map['shirtNumber'] : int.tryParse(map['shirtNumber']?.toString() ?? '0') ?? 0,
      position: map['position']?.toString() ?? '',
      team: map['team']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Available',
      goals: map['goals'] is int ? map['goals'] : int.tryParse(map['goals']?.toString() ?? '0') ?? 0,
      assists: map['assists'] is int ? map['assists'] : int.tryParse(map['assists']?.toString() ?? '0') ?? 0,
      yellowCards: map['yellowCards'] is int ? map['yellowCards'] : int.tryParse(map['yellowCards']?.toString() ?? '0') ?? 0,
      redCards: map['redCards'] is int ? map['redCards'] : int.tryParse(map['redCards']?.toString() ?? '0') ?? 0,
      trainingHistory: List<String>.from(map['trainingHistory'] ?? []),
      xPos: (map['xPos'] ?? 0).toDouble(),
      yPos: (map['yPos'] ?? 0).toDouble(),
    );
  }
}