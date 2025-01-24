import 'dart:math' as math;

/// Representa um pacote de dados que chegou do hardware
class DataPacket {
  DateTime timestamp;
  double xg, yg, zg, xa, ya, za; // se precisar
  double latitude;
  double longitude;

  DataPacket({
    required this.timestamp,
    required this.xg,
    required this.yg,
    required this.zg,
    required this.xa,
    required this.ya,
    required this.za,
    required this.latitude,
    required this.longitude,
  });
}

/// Essa classe guarda o estado acumulado e faz o cálculo incremental
class DataProcessor {
  // Último pacote recebido (para comparar com o próximo)
  DataPacket? _lastPacket;

  // Guarda a velocidade anterior (para calcular aceleração)
  double _lastVelocityMS = 0.0;

  // Para distância total
  double _totalDistance = 0.0;

  // Tempo total (soma dos timeSteps)
  int _accumulatedTime = 0;

  // Distâncias para calcular "distancePerMinute" (janela de 60 pacotes)
  final List<double> _recentDistances = [];

  // Se quiser calcular faixas
  double _band4Distance = 0.0; // 4.0 m/s ~ 5.5 m/s
  double _band5Distance = 0.0; // 5.5 m/s ~ 7.0 m/s

  // Se quiser armazenar “pontos de sprint” etc.
  // final List<DataPacket> _sprintPoints = [];
  // final List<DataPacket> _accelPoints = [];
  // final List<DataPacket> _decelPoints = [];

  /// Retorna a distância total já acumulada
  double get totalDistance => _totalDistance;

  /// Distância percorrida na faixa 4
  double get band4Distance => _band4Distance;

  /// Distância percorrida na faixa 5
  double get band5Distance => _band5Distance;

  /// Atualiza o processamento com um novo pacote
  /// Retorna um objeto [PacketResult] com as métricas calculadas
  PacketResult updateWithNewPacket(DataPacket current) {
    // Se for o primeiro pacote, não calcula nada, só inicializa
    if (_lastPacket == null) {
      _lastPacket = current;
      return PacketResult(
        velocityMS: 0,
        velocityKMH: 0,
        accelerationMS2: 0,
        totalDistance: 0,
        timeStep: 0,
        band4Distance: 0,
        band5Distance: 0,
      );
    }

    final prev = _lastPacket!;

    // 1. Calcular delta tempo (segundos)
    int dt = current.timestamp.difference(prev.timestamp).inSeconds;
    if (dt < 0) dt = dt.abs(); // caso problema de ordenação
    if (dt == 0) dt = 1; // se 0, forçamos 1

    // 2. Calcular distância incremental (m)
    double dist = _calculateDistance(
      prev.latitude, prev.longitude,
      current.latitude, current.longitude,
    );

    // Filtrar outliers
    if (dist > 100.0) {
      dist = 0.0; // descarta como fazia no Python
      dt = 0;
    }

    // 3. Velocidade
    double velocityMS = 0.0;
    if (dt > 0 && dist > 0) {
      velocityMS = dist / dt;
    }
    double velocityKMH = velocityMS * 3.6;

    // Se velocidade > 40km/h => descartar
    if (velocityKMH > 40) {
      velocityMS = 0.0;
      velocityKMH = 0.0;
      dist = 0.0;
      dt = 0;
    }

    // 4. Atualizar distância e tempo total
    _totalDistance += dist;
    _accumulatedTime += dt;

    // 5. Aceleração = (v2 - v1) / dt
    double accelMS2 = 0.0;
    if (dt > 0) {
      accelMS2 = (velocityMS - _lastVelocityMS) / dt;
    }

    // 6. Faixas
    if (velocityMS >= 4.0 && velocityMS < 5.5) {
      _band4Distance += dist;
    }
    if (velocityMS >= 5.5 && velocityMS < 7.0) {
      _band5Distance += dist;
    }

    // 7. Atualiza estado interno
    _lastPacket = current;
    _lastVelocityMS = velocityMS;

    // Retorna valores calculados nesta iteração
    return PacketResult(
      velocityMS: velocityMS,
      velocityKMH: velocityKMH,
      accelerationMS2: accelMS2,
      totalDistance: _totalDistance,
      timeStep: dt,
      band4Distance: _band4Distance,
      band5Distance: _band5Distance,
    );
  }

  double _deg2rad(double deg){
    return deg * (math.pi / 180.0);
  }
  
  double _calculateDistance(
      double lat1, double lon1,
      double lat2, double lon2,
  ) {
    const R = 6371000.0; // raio da terra em metros
    double dLat = _deg2rad(lat2 - lat1);
    double dLon = _deg2rad(lon2 - lon1);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2)
      + math.cos(_deg2rad(lat1)) * math.cos(_deg2rad(lat2)) 
      * math.sin(dLon / 2) * math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
}

/// Só para agrupar o resultado do processamento de um único pacote
class PacketResult {
  final double velocityMS;
  final double velocityKMH;
  final double accelerationMS2;
  final double totalDistance;
  final int timeStep;
  final double band4Distance; // 4.0 m/s ~ 5.5 m/s
  final double band5Distance; // 5.5 m/s ~ 7.0 m/s

  PacketResult({
    required this.velocityMS,
    required this.velocityKMH,
    required this.accelerationMS2,
    required this.totalDistance,
    required this.timeStep,
    required this.band4Distance,
    required this.band5Distance,
  });
}