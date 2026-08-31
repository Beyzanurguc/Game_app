/// Bilgi kartlarına bağlı çoktan seçmeli quiz soruları.
///
/// Her kart için elle yazılmış bir soru, tek bir kısa doğru cevap ve üç
/// çeldirici tutulur. Kartın kendi `question`/`answer` alanları öğretmek için
/// yazıldığından (uzun, açıklayıcı cümleler) doğrudan şık olarak kullanılamaz;
/// bu yüzden quiz metinleri burada ayrı tutulur.
///
/// Anahtar, `cardDeck` içindeki `InfoCard.id` değeridir. Bir kartın burada
/// karşılığı yoksa o kart quizde hiç sorulmaz — `quiz_bank_test.dart` her
/// kartın kapsandığını doğrular.
library;

/// Tek bir quiz sorusunun ham içeriği.
class QuizItem {
  const QuizItem({
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
  });

  /// Ekranda gösterilen soru metni.
  final String prompt;

  /// Tek doğru şık.
  final String correctAnswer;

  /// Üç yanlış şık. Hepsi soruya cevap olabilecek türden olmalı ki eleme
  /// mantıkla yapılabilsin.
  final List<String> distractors;
}

const Map<String, QuizItem> quizBank = {
  // --- Çevre ---------------------------------------------------------------
  'geri_donusum': QuizItem(
    prompt: 'Geri dönüşüm en çok neyi sağlar?',
    correctAnswer: 'Kullanılmış malzemenin yeniden hammadde olmasını',
    distractors: [
      'Çöplerin daha hızlı yanmasını',
      'Atıkların denize taşınmasını',
      'Yeni maden ocakları açılmasını',
    ],
  ),
  'sifir_atik': QuizItem(
    prompt: 'Sıfır atıkta adımların doğru sırası nedir?',
    correctAnswer: 'Önce azalt, sonra tekrar kullan, en son dönüştür',
    distractors: [
      'Önce dönüştür, sonra azalt, en son kullan',
      'Önce satın al, sonra at, en son topla',
      'Önce yak, sonra göm, en son kapat',
    ],
  ),
  'plastik_sise': QuizItem(
    prompt: 'Bir plastik şişe doğada yaklaşık ne kadar kalır?',
    correctAnswer: '450 yıl',
    distractors: ['45 gün', '5 yıl', '40 yıl'],
  ),
  'kagit_donusum': QuizItem(
    prompt: 'Bir ton kâğıdın geri dönüşmesi kaç ağacı kurtarır?',
    correctAnswer: 'Yaklaşık 17 ağaç',
    distractors: ['Yaklaşık 2 ağaç', 'Yaklaşık 170 ağaç', 'Sadece 1 ağaç'],
  ),
  'cam_sise': QuizItem(
    prompt: 'Cam kaç kez geri dönüştürülebilir?',
    correctAnswer: 'Sonsuz kez',
    distractors: ['Sadece bir kez', 'En fazla üç kez', 'Beş altı kez'],
  ),
  'metal_kutu': QuizItem(
    prompt: 'Alüminyum kutuyu dönüştürmek enerjinin yüzde kaçını korur?',
    correctAnswer: 'Yüzde 95',
    distractors: ['Yüzde 5', 'Yüzde 25', 'Yüzde 50'],
  ),
  'atik_pil': QuizItem(
    prompt: 'Bitmiş pil neden normal çöpe atılmaz?',
    correctAnswer: 'İçindeki ağır metaller toprağa ve suya karışır',
    distractors: [
      'Çöpte ıslanınca kendi kendine şarj olur',
      'Diğer çöplere göre çok ağır olduğu için',
      'Kokusu uzun süre geçmediği için',
    ],
  ),
  'kompost': QuizItem(
    prompt: 'Sebze kabukları toprakta çürüyünce neye dönüşür?',
    correctAnswer: 'Bitkileri besleyen doğal gübreye',
    distractors: [
      'Zehirli bir sıvıya',
      'Geri dönüşmüş plastiğe',
      'İçilebilir temiz suya',
    ],
  ),
  'gida_israfi': QuizItem(
    prompt: 'Tabakta kalan yemek çöpe gidince yalnızca yemek mi boşa gider?',
    correctAnswer: 'Hayır; suyu, emeği ve taşıma enerjisi de boşa gider',
    distractors: [
      'Evet, sadece yemeğin kendisi gider',
      'Hayır, sadece tabak fazladan kirlenir',
      'Evet, üstelik çöpte hemen yok olur',
    ],
  ),
  'bez_canta': QuizItem(
    prompt: 'Bir plastik poşet ortalama ne kadar süre kullanılır?',
    correctAnswer: 'Yaklaşık 15 dakika',
    distractors: ['Yaklaşık 15 gün', 'Yaklaşık 1 yıl', 'Yaklaşık 15 yıl'],
  ),
  'tek_kullanimlik': QuizItem(
    prompt: 'Pipet ve plastik çatalın en büyük sorunu nedir?',
    correctAnswer: 'Birkaç dakika kullanılıp yüzlerce yıl doğada kalmaları',
    distractors: [
      'Çok pahalı olmaları',
      'Kolayca kırılmaları',
      'Ağır oldukları için taşınamamaları',
    ],
  ),
  'ikinci_el': QuizItem(
    prompt: 'Küçülen bir oyuncağın en çevreci sonu nedir?',
    correctAnswer: 'Başka bir çocuğa verilmesi',
    distractors: [
      'Çöpe atılması',
      'Bahçeye gömülmesi',
      'Kutuda saklanıp unutulması',
    ],
  ),
  'tamir_et': QuizItem(
    prompt: 'Bozulan bir eşyayı tamir etmek neyi engeller?',
    correctAnswer: 'Yerine yeni bir eşya üretilmesini',
    distractors: [
      'Eşyanın zamanla eskimesini',
      'Elektrik kesintilerini',
      'Geri dönüşüm kutularının dolmasını',
    ],
  ),
  'su_tasarrufu': QuizItem(
    prompt: 'Diş fırçalarken musluğu kapatmak ne kadar su kazandırır?',
    correctAnswer: 'Her fırçalamada yaklaşık 6 litre',
    distractors: [
      'Yaklaşık yarım bardak',
      'Yaklaşık 60 litre',
      'Hiç kazandırmaz',
    ],
  ),
  'damla_sulama': QuizItem(
    prompt: 'Damla sulamada su nereye verilir?',
    correctAnswer: 'Doğrudan bitkinin kökünün dibine',
    distractors: [
      'Havadan yaprakların üstüne',
      'Tarlanın etrafındaki hendeklere',
      'Toprağın metrelerce altına',
    ],
  ),
  'yagmur_suyu': QuizItem(
    prompt: 'Çatıdan toplanan yağmur suyu en çok ne işe yarar?',
    correctAnswer: 'Bahçe sulamada ve temizlikte kullanılır',
    distractors: [
      'Doğrudan içme suyu olur',
      'Elektrik üretmekte kullanılır',
      'Hiçbir işe yaramaz',
    ],
  ),
  'temiz_su': QuizItem(
    prompt: 'Musluktan akan su nereden gelir?',
    correctAnswer: 'Barajlardan ve yer altı sularından',
    distractors: [
      'Doğrudan denizden',
      'Bulutlardan borularla',
      'Fabrikalarda üretilir',
    ],
  ),
  'gunes_paneli': QuizItem(
    prompt: 'Güneş paneli ne yapar?',
    correctAnswer: 'Güneş ışığını doğrudan elektriğe çevirir',
    distractors: [
      'Işığı depolayıp geceleri geri yansıtır',
      'Havayı ısıtıp buhar üretir',
      'Rüzgârı yakalayıp döner',
    ],
  ),
  'ruzgar_turbini': QuizItem(
    prompt: 'Rüzgâr türbini elektriği nasıl üretir?',
    correctAnswer: 'Dönen kanatlar jeneratörü çalıştırır',
    distractors: [
      'Rüzgârı sıkıştırıp yakar',
      'Havadaki elektriği toplar',
      'Güneş ışığını emer',
    ],
  ),
  'su_gucu': QuizItem(
    prompt: 'Barajda elektriği ne üretir?',
    correctAnswer: 'Yüksekten düşen suyun döndürdüğü çarklar',
    distractors: [
      'Suyun içindeki tuz',
      'Göl yüzeyine düşen güneş ışığı',
      'Barajın betonu',
    ],
  ),
  'led_ampul': QuizItem(
    prompt: 'LED ampulün en büyük avantajı nedir?',
    correctAnswer: 'Az elektrikle çok ışık verip yıllarca dayanması',
    distractors: [
      'Hiç ışık vermemesi',
      'Diğerlerinden çok daha fazla ısınması',
      'Elektriksiz de yanabilmesi',
    ],
  ),
  'bekleme_modu': QuizItem(
    prompt: 'Kırmızı ışığı yanan televizyon elektrik harcar mı?',
    correctAnswer: 'Evet, bekleme modunda sessizce elektrik çeker',
    distractors: [
      'Hayır, hiç harcamaz',
      'Sadece yaz aylarında harcar',
      'Sadece bozuksa harcar',
    ],
  ),
  'karbon_ayak_izi': QuizItem(
    prompt: 'Karbon ayak izi neyi ölçer?',
    correctAnswer: 'Havaya saldığımız karbondioksit miktarını',
    distractors: [
      'Ürettiğimiz çöpün ağırlığını',
      'Kullandığımız suyun litresini',
      'Yürüdüğümüz toplam mesafeyi',
    ],
  ),
  'sera_etkisi': QuizItem(
    prompt: 'Sera etkisi nedir?',
    correctAnswer: 'Atmosferdeki bazı gazların ısıyı tutması',
    distractors: [
      'Güneşin Dünyaya yaklaşması',
      'Buzulların erimesi',
      'Ozon tabakasının incelmesi',
    ],
  ),
  'iklim_degisikligi': QuizItem(
    prompt: 'İklim değişikliğinin başlıca nedeni nedir?',
    correctAnswer: 'Kömür, petrol ve doğal gaz yakmak',
    distractors: [
      'Ağaçların sonbaharda yaprak dökmesi',
      'Denizlerin tuzlu olması',
      'Kışın kar yağması',
    ],
  ),
  'eriyen_buzullar': QuizItem(
    prompt: 'Buzullar erirse ne olur?',
    correctAnswer: 'Deniz seviyesi yükselir, kıyı şehirleri risk altına girer',
    distractors: [
      'Denizler tatlı suya dönüşür',
      'Dünya hızla soğur',
      'Yağmurlar tamamen durur',
    ],
  ),
  'ozon_tabakasi': QuizItem(
    prompt: 'Ozon tabakası ne yapar?',
    correctAnswer: 'Güneşin zararlı morötesi ışınlarını süzer',
    distractors: [
      'Yağmur bulutlarını oluşturur',
      'Dünyayı ısıtıp yaşanabilir kılar',
      'Uyduları yörüngede tutar',
    ],
  ),
  'hava_kirliligi': QuizItem(
    prompt: 'Havayı en çok ne kirletir?',
    correctAnswer: 'Fabrika bacaları, egzozlar ve yakılan kömür',
    distractors: [
      'Çiçeklerin poleni',
      'Deniz suyunun buharı',
      'Yağmur damlaları',
    ],
  ),
  'agac_dikme': QuizItem(
    prompt: 'Bir ağaç havadan ne alır, yerine ne verir?',
    correctAnswer: 'Karbondioksit alır, oksijen verir',
    distractors: [
      'Oksijen alır, karbondioksit verir',
      'Su alır, duman verir',
      'Toz alır, metan verir',
    ],
  ),
  'yagmur_ormanlari': QuizItem(
    prompt: 'Yağmur ormanlarına neden dünyanın ciğerleri denir?',
    correctAnswer: 'Havayı temizleyip çok fazla karbondioksit depoladıkları için',
    distractors: [
      'Çok yağmur yağdığı için',
      'En çok hayvan orada yaşadığı için',
      'Havaları çok soğuk olduğu için',
    ],
  ),
  'orman_yangini': QuizItem(
    prompt: 'Orman yangınlarının çoğu neden çıkar?',
    correctAnswer: 'İnsan dikkatsizliği yüzünden',
    distractors: [
      'Yıldırım düştüğü için',
      'Güneş ağaçları tutuşturduğu için',
      'Hayvanlar ateş yaktığı için',
    ],
  ),
  'erozyon': QuizItem(
    prompt: 'Erozyon nedir?',
    correctAnswer: 'Verimli üst toprağın yağmur ve rüzgârla taşınması',
    distractors: [
      'Toprağın kış boyunca donması',
      'Kayaların sıcakta erimesi',
      'Yer altı sularının çekilmesi',
    ],
  ),
  'fitoplankton': QuizItem(
    prompt: 'Soluduğumuz oksijenin yarısından fazlasını kim üretir?',
    correctAnswer: 'Denizdeki minik fitoplanktonlar',
    distractors: [
      'Yağmur ormanlarındaki ağaçlar',
      'Çöl bitkileri',
      'Otlaklardaki çimenler',
    ],
  ),
  'deniz_copleri': QuizItem(
    prompt: 'Denize giden çöpler akıntılarla ne oluşturur?',
    correctAnswer: 'Dev çöp adaları',
    distractors: [
      'Yeni mercan resifleri',
      'Balıklara güvenli yuvalar',
      'Kalın tuz tabakaları',
    ],
  ),
  'mikroplastik': QuizItem(
    prompt: 'Mikroplastik nedir?',
    correctAnswer: 'Kum tanesinden küçük plastik parçacıklar',
    distractors: [
      'Yeni icat edilmiş bir plastik türü',
      'Denizde yaşayan minik bir canlı',
      'Geri dönüşmüş cam tozu',
    ],
  ),
  'biyocesitlilik': QuizItem(
    prompt: 'Biyoçeşitlilik ne demektir?',
    correctAnswer: 'Doğadaki canlı türlerinin çokluğu ve çeşitliliği',
    distractors: [
      'Bir ormandaki ağaçların boyu',
      'Bir gölün derinliği',
      'Havadaki oksijen oranı',
    ],
  ),
  'nesli_tukenenler': QuizItem(
    prompt: 'Bir hayvan türü çoğunlukla neden yok olur?',
    correctAnswer: 'Yaşam alanı yok edildiği için',
    distractors: [
      'Çok fazla yavru yaptığı için',
      'Kış uykusuna yattığı için',
      'Rengini değiştirdiği için',
    ],
  ),
  'mercan_resifi': QuizItem(
    prompt: 'Mercanlar neden beyazlaşır?',
    correctAnswer: 'Deniz ısınınca içlerindeki renkli yosunları dışarı atarlar',
    distractors: [
      'Güneş ışığı renklerini soldurur',
      'Yaşlandıkça renkleri değişir',
      'Deniz suyu kışın donar',
    ],
  ),
  'isik_kirliligi': QuizItem(
    prompt: 'Şehirde yıldızları neden göremeyiz?',
    correctAnswer: 'Gökyüzüne saçılan lamba ışığı yıldızların ışığını bastırır',
    distractors: [
      'Şehirlerin üstünde yıldız bulunmaz',
      'Binalar yıldızları kapatır',
      'Şehirde hava daha ağır olduğu için',
    ],
  ),
  'gurultu_kirliligi': QuizItem(
    prompt: 'Gürültü kirliliği hayvanlara nasıl zarar verir?',
    correctAnswer: 'Birbirlerini duymalarını ve avlanmalarını engeller',
    distractors: [
      'Tüylerini dökmelerine yol açar',
      'Renklerinin solmasına neden olur',
      'Daha hızlı büyümelerini sağlar',
    ],
  ),

  // --- Hayvanlar -----------------------------------------------------------
  'mavi_balina': QuizItem(
    prompt: 'Dünyanın en büyük hayvanı hangisi?',
    correctAnswer: 'Mavi balina',
    distractors: ['Afrika fili', 'Beyaz köpekbalığı', 'Zürafa'],
  ),
  'ahtapot': QuizItem(
    prompt: 'Ahtapotun kaç kalbi vardır?',
    correctAnswer: 'Üç',
    distractors: ['Bir', 'İki', 'Sekiz'],
  ),
  'ari_altigen': QuizItem(
    prompt: 'Arılar peteği neden altıgen yapar?',
    correctAnswer: 'Altıgenler boşluk bırakmadan dizilir, balmumu israf olmaz',
    distractors: [
      'Altıgen çizmek en kolay şekildir',
      'Altıgenler balı soğuk tutar',
      'Altıgen şekli arıları uçmaya iter',
    ],
  ),
  'penguen': QuizItem(
    prompt: 'İmparator penguenler dondurucu soğukta ne yapar?',
    correctAnswer: 'Kalabalık olup sırayla dıştan içe geçerler',
    distractors: [
      'Kar altına tek tek gömülürler',
      'Sıcak ülkelere göç ederler',
      'Kış boyunca uyurlar',
    ],
  ),
  'zurafa': QuizItem(
    prompt: 'Zürafanın boynunda kaç omur vardır?',
    correctAnswer: 'Yedi',
    distractors: ['Yirmi', 'Otuz iki', 'Yüz'],
  ),
  'kutup_ayisi': QuizItem(
    prompt: 'Kutup ayısının tüyleri aslında hangi renktir?',
    correctAnswer: 'Saydam',
    distractors: ['Bembeyaz', 'Açık sarı', 'Simsiyah'],
  ),
  'deniz_kaplumbagasi': QuizItem(
    prompt: 'Yavru deniz kaplumbağaları denizi nasıl bulur?',
    correctAnswer: 'Ayın deniz üzerindeki parıltısına doğru koşarak',
    distractors: [
      'Annelerini takip ederek',
      'Dalga sesini duyarak',
      'Kumdaki izleri koklayarak',
    ],
  ),
  'yarasa': QuizItem(
    prompt: 'Yarasalar zifiri karanlıkta yolu nasıl bulur?',
    correctAnswer: 'Ses gönderip yankısını dinleyerek',
    distractors: [
      'Gözleriyle karanlıkta net görerek',
      'Kokuyu takip ederek',
      'Yıldızlara bakarak',
    ],
  ),
  'karinca': QuizItem(
    prompt: 'Karıncalar yiyeceğe giden yolu nasıl bulur?',
    correctAnswer: 'Bıraktıkları koku izini takip ederek',
    distractors: [
      'Kraliçenin sesini duyarak',
      'Güneşin yönüne bakarak',
      'Toprağa çizgi çizerek',
    ],
  ),
  'kartal': QuizItem(
    prompt: 'Kartalın görüşü insanınkine göre nasıldır?',
    correctAnswer: 'Yaklaşık dört kat daha keskin',
    distractors: [
      'İnsanla tamamen aynı',
      'İnsandan daha zayıf',
      'Sadece geceleri iyi',
    ],
  ),
  'kelebek': QuizItem(
    prompt: 'Tırtılın kozada kelebeğe dönüşmesine ne denir?',
    correctAnswer: 'Başkalaşım',
    distractors: ['Göç', 'Kış uykusu', 'Tüy değişimi'],
  ),
  'fil': QuizItem(
    prompt: 'Filin hortumunda ne yoktur?',
    correctAnswer: 'Kemik',
    distractors: ['Kas', 'Kan damarı', 'Sinir'],
  ),
  'yunus': QuizItem(
    prompt: 'Yunuslar uyurken nefes almayı nasıl unutmaz?',
    correctAnswer: 'Beyinlerinin yarısı uyanık kalır',
    distractors: [
      'Uykuda solungaçlarını kullanırlar',
      'Sırtüstü yatıp burunlarını açık tutarlar',
      'Uyurken hiç nefes almazlar',
    ],
  ),
  'baykus': QuizItem(
    prompt: 'Baykuşlar neden sessiz uçar?',
    correctAnswer: 'Tüylerinin tırtıklı kenarları havayı yumuşatır',
    distractors: [
      'Çok yavaş uçtukları için',
      'Kanatlarını hiç çırpmadıkları için',
      'Kuş tüyü ses çıkarmadığı için',
    ],
  ),
  'kirpi': QuizItem(
    prompt: 'Bir kirpinin yaklaşık kaç dikeni vardır?',
    correctAnswer: '5000',
    distractors: ['50', '500', '50.000'],
  ),

  // --- Uzay ----------------------------------------------------------------
  'mars': QuizItem(
    prompt: 'Mars neden kırmızı görünür?',
    correctAnswer: 'Toprağındaki demir paslandığı için',
    distractors: [
      'Yüzeyi sürekli yandığı için',
      'Güneşe en yakın gezegen olduğu için',
      'Kırmızı bulutlarla kaplı olduğu için',
    ],
  ),
  'ay': QuizItem(
    prompt: 'Aydaki ayak izleri neden silinmiyor?',
    correctAnswer: 'Ayda izleri silecek rüzgâr ve yağmur yok',
    distractors: [
      'İzler kayaya kazındığı için',
      'Üzerleri camla kapatıldığı için',
      'Ay tozu yapışkan olduğu için',
    ],
  ),
  'gunes': QuizItem(
    prompt: 'Güneşin içine kaç Dünya sığar?',
    correctAnswer: 'Bir milyondan fazla',
    distractors: ['Yaklaşık on', 'Yaklaşık bin', 'Tam olarak yüz'],
  ),
  'saturn': QuizItem(
    prompt: 'Satürnün halkaları neyden oluşur?',
    correctAnswer: 'Buz ve kaya parçalarından',
    distractors: [
      'Sıkışmış gazdan',
      'Erimiş altından',
      'Tek parça dev bir taş levhadan',
    ],
  ),
  'yildizlar': QuizItem(
    prompt: 'Yıldızlar neden titrer gibi görünür?',
    correctAnswer: 'Işıkları atmosferden geçerken bükülür',
    distractors: [
      'Gerçekten yanıp sönerler',
      'Çok hızlı döndükleri için',
      'Ay ışığı önlerinden geçtiği için',
    ],
  ),
  'karadelik': QuizItem(
    prompt: 'Kara delik neden siyah görünür?',
    correctAnswer: 'Çekimi o kadar güçlü ki ışık bile kaçamaz',
    distractors: [
      'Yüzeyi siyah taştan olduğu için',
      'Çok uzakta olduğu için',
      'İçi tamamen boş olduğu için',
    ],
  ),
  'kuyruklu_yildiz': QuizItem(
    prompt: 'Kuyruklu yıldızın kuyruğu ne zaman oluşur?',
    correctAnswer: 'Güneşe yaklaşıp buzu buharlaşınca',
    distractors: [
      'Bir gezegene çarpınca',
      'Atmosfere girip yanınca',
      'Işık hızına ulaşınca',
    ],
  ),
  'samanyolu': QuizItem(
    prompt: 'Gökyüzündeki o beyaz şerit nedir?',
    correctAnswer: 'Kendi galaksimiz Samanyolu',
    distractors: [
      'İnce bir bulut kümesi',
      'Ayın bıraktığı iz',
      'Uzaydaki bir toz fırtınası',
    ],
  ),
  'astronot': QuizItem(
    prompt: 'Astronotlar uzay istasyonunda neden süzülür?',
    correctAnswer: 'İstasyonla birlikte sürekli Dünyaya doğru düştükleri için',
    distractors: [
      'Uzayda yer çekimi hiç olmadığı için',
      'Kıyafetleri çok hafif olduğu için',
      'İstasyonun içi havasız olduğu için',
    ],
  ),
  'uzay_istasyonu': QuizItem(
    prompt: 'Uzay istasyonu Dünyanın çevresini ne kadar sürede dolaşır?',
    correctAnswer: '90 dakikada',
    distractors: ['24 saatte', 'Bir haftada', '365 günde'],
  ),
  'jupiter': QuizItem(
    prompt: 'Jüpiterdeki dev kırmızı leke nedir?',
    correctAnswer: 'Yüzlerce yıldır dinmeyen bir fırtına',
    distractors: [
      'Kocaman bir çarpma krateri',
      'Kızgın bir lav gölü',
      'Kırmızı bir okyanus',
    ],
  ),
  'venus': QuizItem(
    prompt: 'En sıcak gezegen hangisidir?',
    correctAnswer: 'Venüs',
    distractors: ['Merkür', 'Mars', 'Jüpiter'],
  ),
  'yercekimi': QuizItem(
    prompt: 'Ayı yörüngesinde tutan nedir?',
    correctAnswer: 'Dünyanın çekim kuvveti',
    distractors: [
      'Güneş rüzgârı',
      'Ayın kendi ışığı',
      'Atmosferdeki hava basıncı',
    ],
  ),
  'meteor': QuizItem(
    prompt: 'Kayan yıldız aslında nedir?',
    correctAnswer: 'Atmosferde sürtünmeyle yanan küçük bir taş',
    distractors: [
      'Gökyüzünden düşen gerçek bir yıldız',
      'Yörüngeden çıkan bir uydu',
      'Çok uzaktaki bir galaksi',
    ],
  ),
  'teleskop': QuizItem(
    prompt: 'Teleskop nasıl çalışır?',
    correctAnswer: 'Mercek ve aynalarla çok fazla ışık toplar',
    distractors: [
      'Yıldızları yörüngesinden çekip yaklaştırır',
      'Sesle uzaklığı ölçer',
      'Karanlığı emip yok eder',
    ],
  ),

  // --- Doğa ----------------------------------------------------------------
  'mese_agaci': QuizItem(
    prompt: 'Bir meşe ağacı ne kadar yaşayabilir?',
    correctAnswer: '500 yıldan fazla',
    distractors: ['En fazla 20 yıl', 'Yaklaşık 50 yıl', 'Tam 100 yıl'],
  ),
  'gokkusagi': QuizItem(
    prompt: 'Gökkuşağı nasıl oluşur?',
    correctAnswer: 'Güneş ışığı yağmur damlalarında kırılıp renklerine ayrılır',
    distractors: [
      'Bulutlar içinde boya taşıdığı için',
      'Güneş batarken gökyüzü boyandığı için',
      'Rüzgâr renkleri savurduğu için',
    ],
  ),
  'kar_tanesi': QuizItem(
    prompt: 'İki kar tanesi birbirinin tıpatıp aynısı olur mu?',
    correctAnswer: 'Neredeyse imkânsız; her tane farklı bir yol izler',
    distractors: [
      'Evet, hepsi aynı kalıptan çıkar',
      'Evet, aynı buluttakiler aynıdır',
      'Sadece çok soğukta aynı olurlar',
    ],
  ),
  'simsek': QuizItem(
    prompt: 'Şimşeği neden gök gürültüsünden önce görürüz?',
    correctAnswer: 'Işık sesten çok daha hızlı yol alır',
    distractors: [
      'Şimşek önce oluşur, ses sonra çıkar',
      'Ses bulutun içinden çıkamaz',
      'Gözümüz kulağımızdan hızlı çalışır',
    ],
  ),
  'orman_agi': QuizItem(
    prompt: 'Ağaçlar yer altında birbiriyle nasıl haberleşir?',
    correctAnswer: 'Kökleri birbirine bağlayan mantar iplikleriyle',
    distractors: [
      'Yapraklarını sallayarak',
      'Rüzgârla tohum göndererek',
      'Gövdelerine vurarak',
    ],
  ),
  'yanardag': QuizItem(
    prompt: 'Erimiş kaya yeryüzüne çıkınca adı ne olur?',
    correctAnswer: 'Lav',
    distractors: ['Magma', 'Kül', 'Bazalt'],
  ),
  'deprem': QuizItem(
    prompt: 'Yer neden sallanır?',
    correctAnswer: 'Yer kabuğundaki dev levhalar aniden kaydığı için',
    distractors: [
      'Yer altı suları çekildiği için',
      'Dünya çok hızlı döndüğü için',
      'Yanardağlar soğuduğu için',
    ],
  ),
  'selale': QuizItem(
    prompt: 'Şelale nasıl oluşur?',
    correctAnswer: 'Su yumuşak kayayı hızla aşındırıp bir basamak bırakır',
    distractors: [
      'Yağmur tek bir noktaya yığıldığı için',
      'Deprem kayaları ikiye ayırdığı için',
      'Rüzgâr suyu yukarı kaldırdığı için',
    ],
  ),
  'col': QuizItem(
    prompt: 'Çöller geceleri neden hızla soğur?',
    correctAnswer: 'Kuru havada ısıyı tutacak nem yoktur',
    distractors: [
      'Gece rüzgârı buz taşır',
      'Kum ısıyı emip saklar',
      'Güneş geceleri çölden uzaklaşır',
    ],
  ),
  'tuzlu_deniz': QuizItem(
    prompt: 'Deniz suyu neden tuzludur?',
    correctAnswer: 'Nehirler kayalardan çözünen mineralleri denize taşır',
    distractors: [
      'Deniz dibinde tuz madenleri vardır',
      'Balıklar tuz üretir',
      'Yağmur tuzlu yağar',
    ],
  ),
  'ruzgar': QuizItem(
    prompt: 'Rüzgâr nasıl oluşur?',
    correctAnswer: 'Sıcak hava yükselir, soğuk hava onun yerini alır',
    distractors: [
      'Ağaçların sallanmasıyla',
      'Dünyanın dönüş sesiyle',
      'Bulutların birbirine çarpmasıyla',
    ],
  ),
  'sis': QuizItem(
    prompt: 'Sis nedir?',
    correctAnswer: 'Yere değen bir bulut',
    distractors: [
      'Havaya karışan ince toz',
      'Fabrika dumanı',
      'Havada donmuş yağmur',
    ],
  ),
  'mevsimler': QuizItem(
    prompt: 'Mevsimler neden değişir?',
    correctAnswer: 'Dünya eğik olduğu için Güneş bölgeleri farklı açıyla ısıtır',
    distractors: [
      'Dünya bazen Güneşe yaklaşıp bazen uzaklaştığı için',
      'Güneşin ısısı yıl içinde azalıp arttığı için',
      'Ayın konumu değiştiği için',
    ],
  ),
  'bulutlar': QuizItem(
    prompt: 'Bulutlar neden gökyüzünde durabilir?',
    correctAnswer: 'Damlacıkları o kadar küçük ki hava akımları onları taşır',
    distractors: [
      'Havadan hafif bir gaz oldukları için',
      'Yükseklerde yer çekimi olmadığı için',
      'Rüzgâr onları sürekli yukarı ittiği için',
    ],
  ),
  'gelgit': QuizItem(
    prompt: 'Denizin çekilip yükselmesine ne yol açar?',
    correctAnswer: 'Ayın çekim kuvveti',
    distractors: [
      'Rüzgârın yönü',
      'Yağmurun miktarı',
      'Denizin tuz oranı',
    ],
  ),

  // --- Bilim ---------------------------------------------------------------
  'kalp': QuizItem(
    prompt: 'Kalbimiz günde yaklaşık kaç kez atar?',
    correctAnswer: '100 bin',
    distractors: ['1000', '10 bin', '1 milyon'],
  ),
  'kemikler': QuizItem(
    prompt: 'Kimin daha çok kemiği vardır?',
    correctAnswer: 'Bebeklerin',
    distractors: ['Yetişkinlerin', 'İkisinde de aynı', 'Yaşlıların'],
  ),
  'buz_yuzer': QuizItem(
    prompt: 'Buz neden suda yüzer?',
    correctAnswer: 'Su donarken genişler ve hafifler',
    distractors: [
      'İçinde hava kabarcıkları olduğu için',
      'Sudan daha soğuk olduğu için',
      'Suyun yüzeyi buzu ittiği için',
    ],
  ),
  'ses': QuizItem(
    prompt: 'Uzayda ses duyulur mu?',
    correctAnswer: 'Duyulmaz, sesi taşıyacak hava yoktur',
    distractors: [
      'Duyulur ama çok kısık gelir',
      'Sadece çok yakından duyulur',
      'Duyulur, ışıkla birlikte gelir',
    ],
  ),
  'golge': QuizItem(
    prompt: 'Gölgemizin boyu neye göre değişir?',
    correctAnswer: 'Güneşin gökyüzündeki açısına göre',
    distractors: [
      'Boyumuzun gün içinde değişmesine göre',
      'Havanın sıcaklığına göre',
      'Rüzgârın yönüne göre',
    ],
  ),
  'beyin': QuizItem(
    prompt: 'Beynimiz vücudun enerjisinin ne kadarını kullanır?',
    correctAnswer: 'Beşte birini',
    distractors: ['Yüzde ikisini', 'Yarısını', 'Neredeyse hiç'],
  ),
  'hapsirma': QuizItem(
    prompt: 'Hapşırık saatte kaç kilometreye kadar çıkabilir?',
    correctAnswer: '150',
    distractors: ['5', '15', '1500'],
  ),
  'parmak_izi': QuizItem(
    prompt: 'İkizlerin parmak izleri aynı mıdır?',
    correctAnswer: 'Hayır, ikizlerde bile farklıdır',
    distractors: [
      'Evet, tıpatıp aynıdır',
      'Sadece tek yumurta ikizlerinde aynıdır',
      'Doğduklarında aynı, sonra değişir',
    ],
  ),
  'miknatis': QuizItem(
    prompt: 'Pusulanın iğnesi neden hep kuzeyi gösterir?',
    correctAnswer: 'Dünya dev bir mıknatıs gibi davranır',
    distractors: [
      'Kuzeyde çok büyük bir demir dağ vardır',
      'İğne hep soğuk tarafa döner',
      'Güneş sabahları kuzeyden doğar',
    ],
  ),
  'statik_elektrik': QuizItem(
    prompt: 'Sürtülen balon saça neden yapışır?',
    correctAnswer: 'Zıt yükler birbirini çeker',
    distractors: [
      'Balon ısınıp yapışkanlaşır',
      'Saçtaki yağ balonu tutar',
      'Havadaki nem ikisini birbirine yapıştırır',
    ],
  ),
  'kaldirac': QuizItem(
    prompt: 'Kaldıraçla daha ağır bir yükü nasıl kaldırırız?',
    correctAnswer: 'Destek noktasını yüke yaklaştırarak',
    distractors: [
      'Destek noktasını yükten uzaklaştırarak',
      'Çubuğu kısaltarak',
      'Yükü tam ortaya koyarak',
    ],
  ),
  'isik_renkler': QuizItem(
    prompt: 'Bir elma neden kırmızı görünür?',
    correctAnswer: 'Diğer renkleri yutup sadece kırmızıyı yansıttığı için',
    distractors: [
      'İçinde kırmızı boya olduğu için',
      'Kendisi kırmızı ışık ürettiği için',
      'Güneş ona kırmızı ışık gönderdiği için',
    ],
  ),
  'dna': QuizItem(
    prompt: 'Göz rengimizi ne belirler?',
    correctAnswer: 'Hücrelerimizdeki DNA',
    distractors: [
      'Doğduğumuz mevsim',
      'Yediğimiz besinler',
      'Aldığımız güneş ışığı',
    ],
  ),
  'ekmek_mayasi': QuizItem(
    prompt: 'Ekmek hamuru neden kabarır?',
    correctAnswer: 'Mayadaki minik mantarlar şekeri yiyip gaz üretir',
    distractors: [
      'Fırının sıcağı hamuru şişirir',
      'Un suyla temas edince genişler',
      'Tuz hamuru yukarı kaldırır',
    ],
  ),
  'uyku': QuizItem(
    prompt: 'Uykuda beynimiz ne yapar?',
    correctAnswer: 'Gün içinde öğrendiklerini düzenler',
    distractors: [
      'Tamamen kapanıp dinlenir',
      'Kas üretmeye başlar',
      'Sadece rüya izler, başka bir şey yapmaz',
    ],
  ),
};
