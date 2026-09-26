class Idiom {
  const Idiom({
    required this.id,
    required this.text,
    required this.meaning,
    required this.origin,
    required this.example,
  });

  final int id;

  /// Die Redewendung selbst, z. B. „Tomaten auf den Augen haben“.
  final String text;

  /// Kurze Bedeutung in einem Satz.
  final String meaning;

  /// Herkunft / Erklärung.
  final String origin;

  /// Beispielsatz.
  final String example;

  factory Idiom.fromJson(Map<String, dynamic> json) => Idiom(
        id: json['id'] as int,
        text: json['text'] as String,
        meaning: json['meaning'] as String,
        origin: json['origin'] as String,
        example: json['example'] as String,
      );
}
