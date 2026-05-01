// Turkish labels for backend enum codes. Single source for UI display strings.

const Map<String, String> _teamCategory = {
  'u13': 'U13', 'u14': 'U14', 'u15': 'U15', 'u16': 'U16',
  'u17': 'U17', 'u18': 'U18', 'u19': 'U19', 'u21': 'U21',
  'senior': 'A Takımı',
  'amateur': 'Amatör',
  'veteran': 'Veteran',
};

const Map<String, String> _position = {
  'goalkeeper': 'Kaleci',
  'defender': 'Defans',
  'midfielder': 'Orta saha',
  'forward': 'Forvet',
};

const Map<String, String> _detailedPosition = {
  'GK': 'Kaleci',
  'CB': 'Stoper', 'LB': 'Sol bek', 'RB': 'Sağ bek',
  'LWB': 'Sol kanat bek', 'RWB': 'Sağ kanat bek',
  'CDM': 'Defansif orta saha', 'CM': 'Orta saha', 'CAM': 'Ofansif orta saha',
  'LM': 'Sol orta saha', 'RM': 'Sağ orta saha',
  'LW': 'Sol kanat', 'RW': 'Sağ kanat',
  'ST': 'Santrfor', 'CF': 'Forvet', 'SS': 'İkinci forvet',
};

const Map<String, String> _foot = {
  'left': 'Sol',
  'right': 'Sağ',
  'both': 'Her ikisi',
};

const Map<String, String> _employment = {
  'full_time_pro': 'Tam profesyonel',
  'semi_pro': 'Yarı profesyonel',
  'amateur': 'Amatör',
  'student': 'Öğrenci',
  'working': 'Çalışan',
};

const Map<String, String> _facilityType = {
  'natural_grass': 'Çim saha',
  'artificial_turf': 'Sentetik saha',
  'indoor_pitch': 'Kapalı saha',
  'gym': 'Spor salonu',
  'weight_room': 'Ağırlık odası',
  'sprint_track': 'Sürat pisti',
  'pool': 'Havuz',
  'recovery_room': 'Toparlanma odası',
};

const Map<String, String> _equipment = {
  'barbell': 'Halter', 'dumbbell': 'Dumbbell', 'kettlebell': 'Kettlebell',
  'bench': 'Bench', 'squat_rack': 'Squat rack', 'pull_up_bar': 'Barfiks',
  'resistance_band': 'Direnç bandı', 'medicine_ball': 'Sağlık topu',
  'trx': 'TRX', 'swiss_ball': 'Pilates topu', 'bosu': 'Bosu',
  'weighted_vest': 'Ağırlıklı yelek', 'speed_parachute': 'Sürat paraşütü',
  'cones': 'Koni', 'agility_ladder': 'Agility merdiveni',
  'hurdles': 'Mini engel', 'plyo_box': 'Plyo kutu',
  'goal': 'Kale', 'rebounder': 'Rebounder', 'mannequin': 'Mankenler',
  'rowing_machine': 'Kürek makinesi', 'treadmill': 'Koşu bandı',
  'stationary_bike': 'Sabit bisiklet',
};

const Map<String, String> _trainingCategory = {
  'endurance': 'Dayanıklılık',
  'sprint_agility': 'Sürat & çeviklik',
  'strength': 'Kuvvet',
  'plyometric': 'Plyometrik',
  'technical': 'Teknik',
  'tactical': 'Taktik',
  'goalkeeper_specific': 'Kaleci özel',
  'recovery': 'Toparlanma',
  'warmup': 'Isınma',
  'cooldown': 'Soğuma',
  'small_sided_game': 'Mini oyun (SSG)',
  'set_piece': 'Duran top',
};

const Map<String, String> _sessionType = {
  'team': 'Takım',
  'individual': 'Bireysel',
  'position_group': 'Mevki grubu',
  'recovery': 'Toparlanma',
};

const Map<String, String> _microcycle = {
  'match_week': 'Maç haftası',
  'preseason': 'Hazırlık dönemi',
  'recovery_week': 'Toparlanma haftası',
  'off_season': 'Sezon arası',
};

const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
const _dayNamesLong = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];

String teamCategoryLabel(String code) => _teamCategory[code] ?? code.toUpperCase();
String positionLabel(String code) => _position[code] ?? code;
String detailedPositionLabel(String code) => _detailedPosition[code.toUpperCase()] ?? code;
String footLabel(String code) => _foot[code] ?? code;
String employmentLabel(String code) => _employment[code] ?? code;
String facilityTypeLabel(String code) => _facilityType[code] ?? code;
String equipmentLabel(String code) => _equipment[code] ?? code;
String roleLabel(String role) => role == 'coach' ? 'Antrenör' : (role == 'player' ? 'Oyuncu' : role);
const Map<String, String> _availability = {
  'ready': 'Hazır',
  'doubtful': 'Şüpheli',
  'limited': 'Sınırlı',
  'injured': 'Sakat',
  'ill': 'Hasta',
  'suspended': 'Cezalı',
  'away': 'İzinli',
};

const Map<String, String> _injuryType = {
  'muscle': 'Kas',
  'ligament': 'Bağ',
  'joint': 'Eklem',
  'bone': 'Kemik',
  'tendon': 'Tendon',
  'concussion': 'Sarsıntı',
  'other': 'Diğer',
};

const Map<String, String> _injurySeverity = {
  'minor': 'Hafif',
  'moderate': 'Orta',
  'major': 'Ciddi',
  'severe': 'Şiddetli',
};

const Map<String, String> _perfTest = {
  'sprint_10m': '10m sürat',
  'sprint_20m': '20m sürat',
  'sprint_30m': '30m sürat',
  'agility_505': '505 çeviklik',
  'agility_t_test': 'T testi',
  'yo_yo_ir1': 'Yo-Yo IR1',
  'yo_yo_ir2': 'Yo-Yo IR2',
  'beep_test': 'Beep test',
  'cooper_test': 'Cooper testi',
  'vertical_jump': 'Dikey sıçrama',
  'broad_jump': 'Uzun atlama',
  'bench_press_1rm': 'Bench 1RM',
  'squat_1rm': 'Squat 1RM',
  'pull_ups_max': 'Maks. barfiks',
  'push_ups_max': 'Maks. şınav',
  'flexibility_sit_reach': 'Esneklik (otur-uzan)',
  'body_fat_percent': 'Yağ %',
};

String trainingCategoryLabel(String code) => _trainingCategory[code] ?? code;
String sessionTypeLabel(String code) => _sessionType[code] ?? code;
String microcycleLabel(String code) => _microcycle[code] ?? code;
String availabilityLabel(String code) => _availability[code] ?? code;
String injuryTypeLabel(String code) => _injuryType[code] ?? code;
String injurySeverityLabel(String code) => _injurySeverity[code] ?? code;
String perfTestLabel(String code) => _perfTest[code] ?? code;

// DateTime weekday is 1=Mon..7=Sun
String dayShort(int weekday) => _dayNames[(weekday - 1).clamp(0, 6)];
String dayLong(int weekday) => _dayNamesLong[(weekday - 1).clamp(0, 6)];

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
