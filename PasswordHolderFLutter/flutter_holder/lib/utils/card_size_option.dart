enum CardSizeOption {
  compact,
  normal,
  spacious,
}

extension CardSizeOptionX on CardSizeOption {
  String get label => switch (this) {
        CardSizeOption.compact => 'Küçük',
        CardSizeOption.normal => 'Orta',
        CardSizeOption.spacious => 'Büyük',
      };

  String get description => switch (this) {
        CardSizeOption.compact => 'Listeyi daha sıkı göster',
        CardSizeOption.normal => 'Varsayılan kart boyutu',
        CardSizeOption.spacious => 'Daha geniş satırlar kullan',
      };

  double get scale => switch (this) {
        CardSizeOption.compact => 0.9,
        CardSizeOption.normal => 1.0,
        CardSizeOption.spacious => 1.1,
      };

  String get storageKey => switch (this) {
        CardSizeOption.compact => 'compact',
        CardSizeOption.normal => 'normal',
        CardSizeOption.spacious => 'spacious',
      };
}

CardSizeOption cardSizeOptionFromString(String? value) {
  switch (value) {
    case 'compact':
      return CardSizeOption.compact;
    case 'spacious':
      return CardSizeOption.spacious;
    case 'normal':
    default:
      return CardSizeOption.normal;
  }
}

