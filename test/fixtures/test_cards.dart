import 'package:game_app/cards/info_card.dart';

/// Davranış testleri için sentetik bilgi kartı destesi.
///
/// Gerçek içerik artık Firestore'da; uygulamada gömülü deste yok. Testler
/// içeriğe değil davranışa baktığı için burada bilinçli olarak sahte ama
/// belirlenimci bir deste üretiliyor: kategori dağılımı ve sıralaması sabit,
/// her kartın kullanılabilir bir quiz sorusu var.
///
/// Firestore'a yüklenecek gerçek içeriğin doğruluğu `seed_test.dart` içinde
/// `seed/cards.json` üzerinden ayrıca kontrol edilir.
List<InfoCard> buildTestDeck({int count = 20}) => [
  for (var index = 0; index < count; index++) _card(index),
];

/// Testlerin çoğunun kullandığı varsayılan deste.
final List<InfoCard> testDeck = buildTestDeck();

InfoCard _card(int index) {
  final category = CardCategory.values[index % CardCategory.values.length];
  return InfoCard(
    id: 'kart_$index',
    title: 'Kart $index',
    question: '$index numaralı soru nedir?',
    answer: '$index numaralı kartın açıklaması.',
    facts: ['$index hakkında birinci bilgi', '$index hakkında ikinci bilgi'],
    category: category,
    emoji: '🦊',
    order: index,
    quiz: QuizItem(
      prompt: '$index numaralı quiz sorusu?',
      correctAnswer: 'Doğru $index',
      distractors: ['Yanlış ${index}a', 'Yanlış ${index}b', 'Yanlış ${index}c'],
    ),
  );
}

/// Quiz sorusu olmayan kart — motorun bunları elediğini doğrulamak için.
InfoCard cardWithoutQuiz(String id) => InfoCard(
  id: id,
  title: 'Sorusuz $id',
  question: 'Soru',
  answer: 'Cevap',
  facts: const [],
  category: CardCategory.bilim,
  emoji: '❓',
);

/// Şıkları eksik, bu yüzden sorulamaz bir kart.
InfoCard cardWithBrokenQuiz(String id) => InfoCard(
  id: id,
  title: 'Bozuk $id',
  question: 'Soru',
  answer: 'Cevap',
  facts: const [],
  category: CardCategory.bilim,
  emoji: '❓',
  quiz: const QuizItem(
    prompt: 'Yarım soru?',
    correctAnswer: 'Doğru',
    distractors: ['Sadece bir çeldirici'],
  ),
);
