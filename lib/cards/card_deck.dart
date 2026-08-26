import 'info_card.dart';

/// Uygulamadaki bilgi kartı destesi.
///
/// Deste çevre ağırlıklıdır: 100 kartın 40 tanesi Çevre kategorisinde.
///
/// Yeni kart eklemek için listeye bir [InfoCard] eklemek yeterli; albümdeki
/// toplam sayı, kategori filtreleri ve "hepsi toplandı" durumu kendiliğinden
/// güncellenir.
const List<InfoCard> cardDeck = [
  // --- Çevre -------------------------------------------------------------
  InfoCard(
    id: 'geri_donusum',
    title: 'Geri Dönüşüm',
    question: 'Geri dönüşüm ne işe yarar?',
    answer:
        'Kullanılmış kâğıt, cam, metal ve plastik yeniden hammadde olur. '
        'Böylece doğadan daha az şey almak zorunda kalırız.',
    facts: [
      'Geri dönüştürülmüş malzemeden üretim yapmak, sıfırdan üretmekten çok '
          'daha az enerji harcıyor.',
      'Atıkları evde ayırmak geri dönüşümün en önemli adımı.',
    ],
    category: CardCategory.cevre,
    emoji: '♻️',
  ),
  InfoCard(
    id: 'sifir_atik',
    title: 'Sıfır Atık',
    question: 'Sıfır atık ne demek?',
    answer:
        'Bir şeyi çöpe atmadan önce azaltmak, tekrar kullanmak ve dönüştürmek '
        'demek. Amaç çöp kutusuna en az şeyi göndermek.',
    facts: [
      'Kuralı hatırlamak kolay: önce azalt, sonra tekrar kullan, en son '
          'dönüştür.',
      'Bir okulun sıfır atık kutuları yılda tonlarca atığı çöpten '
          'kurtarabiliyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🗑️',
  ),
  InfoCard(
    id: 'plastik_sise',
    title: 'Plastik Şişe',
    question: 'Bir plastik şişe doğada ne kadar kalır?',
    answer:
        'Yaklaşık 450 yıl. Yani bugün attığın şişe, torunlarının torunları '
        'büyürken hâlâ orada olabilir.',
    facts: [
      'Geri dönüşen şişeler polar kumaşa, halı ipliğine ya da yeni şişeye '
          'dönüşebiliyor.',
      'Şişeyi ezip kapağını takarak atmak taşımayı kolaylaştırıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🧴',
  ),
  InfoCard(
    id: 'kagit_donusum',
    title: 'Kâğıt Geri Dönüşümü',
    question: 'Kâğıdı dönüştürmek ağaçları nasıl kurtarır?',
    answer:
        'Bir ton kâğıdın geri dönüşmesi, yaklaşık 17 ağacın kesilmemesi demek.',
    facts: [
      'Bir kâğıt beş altı kez geri dönüştürülebiliyor; sonra lifleri çok '
          'kısalıyor.',
      'Kâğıdın iki yüzünü de kullanmak, dönüştürmekten bile iyi.',
    ],
    category: CardCategory.cevre,
    emoji: '📄',
  ),
  InfoCard(
    id: 'cam_sise',
    title: 'Cam Şişe',
    question: 'Cam kaç kez geri dönüştürülebilir?',
    answer:
        'Sonsuz kere! Cam eridiğinde hiçbir şey kaybetmez, aynı kalitede yeni '
        'şişe olur.',
    facts: [
      'Bir cam şişenin doğada yok olması 4000 yıldan uzun sürüyor.',
      'Geri dönüşen cam, kumdan cam üretmeye göre çok daha az enerji harcıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🍶',
  ),
  InfoCard(
    id: 'metal_kutu',
    title: 'Metal Kutu',
    question: 'Alüminyum kutuyu dönüştürmek ne kazandırır?',
    answer:
        'Enerjinin yüzde 95\'ini. Kutuyu dönüştürmek, sıfırdan üretmenin '
        'yirmide biri kadar enerji harcar.',
    facts: [
      'Attığın bir kutu iki ay içinde raftaki yeni bir kutu olarak geri '
          'dönebiliyor.',
      'Alüminyum, geri dönüşümde en değerli atıklardan biri.',
    ],
    category: CardCategory.cevre,
    emoji: '🥫',
  ),
  InfoCard(
    id: 'atik_pil',
    title: 'Atık Pil',
    question: 'Bitmiş pil neden normal çöpe atılmaz?',
    answer:
        'İçindeki ağır metaller toprağa ve suya karışır. Tek bir kalem pil '
        'binlerce litre suyu kirletebilir.',
    facts: [
      'Marketlerde ve okullarda atık pil kutuları bulunuyor.',
      'Şarj edilebilir piller yüzlerce kez kullanıldığı için çok daha az atık '
          'üretir.',
    ],
    category: CardCategory.cevre,
    emoji: '🔋',
  ),
  InfoCard(
    id: 'kompost',
    title: 'Kompost',
    question: 'Sebze kabukları çöp müdür?',
    answer:
        'Hayır, hazinedir! Toprakta çürüyünce bitkileri besleyen bedava '
        'gübreye dönüşür.',
    facts: [
      'Solucanlar kompostun en hızlı işçileri; kabukları haftalar içinde '
          'toprağa çevirirler.',
      'Evsel çöpün neredeyse yarısı aslında kompost olabilecek mutfak atığı.',
    ],
    category: CardCategory.cevre,
    emoji: '🪱',
  ),
  InfoCard(
    id: 'gida_israfi',
    title: 'Gıda İsrafı',
    question: 'Tabakta kalan yemek nereye gider?',
    answer:
        'Çöpe. Üstelik o yemeğin suyu, emeği ve taşıma enerjisi de birlikte '
        'boşa gider.',
    facts: [
      'Dünyada üretilen yiyeceğin yaklaşık üçte biri hiç yenmeden atılıyor.',
      'Tabağına yiyebileceğin kadar koymak en kolay çevre hareketi.',
    ],
    category: CardCategory.cevre,
    emoji: '🍽️',
  ),
  InfoCard(
    id: 'bez_canta',
    title: 'Bez Çanta',
    question: 'Bez çanta poşetten neden iyidir?',
    answer:
        'Yüzlerce kez kullanılabilir. Bir poşet ise ortalama 15 dakika '
        'kullanılıp yüzyıllarca doğada kalır.',
    facts: [
      'Poşetler suda denizanasına benzediği için kaplumbağaları yanıltıyor.',
      'Bez çantayı çantanın içinde taşımak, markette poşet almayı '
          'unutturmuyor.',
    ],
    category: CardCategory.cevre,
    emoji: '👜',
  ),
  InfoCard(
    id: 'tek_kullanimlik',
    title: 'Tek Kullanımlıklar',
    question: 'Pipet, çatal ve bardak neden sorun?',
    answer:
        'Birkaç dakika kullanılıp atılıyorlar ama doğada yüzlerce yıl '
        'kalıyorlar.',
    facts: [
      'Kendi matarası ve çelik pipeti olan biri yılda yüzlerce plastiği çöpe '
          'göndermiyor.',
      'Birçok ülkede tek kullanımlık plastikler artık yasak.',
    ],
    category: CardCategory.cevre,
    emoji: '🥤',
  ),
  InfoCard(
    id: 'ikinci_el',
    title: 'İkinci El',
    question: 'Küçülen oyuncak ve kıyafetler ne olmalı?',
    answer:
        'Bir başkasına gitmeli. Eşyanın ikinci hayatı, hiç üretilmeyen yeni '
        'bir eşya demek.',
    facts: [
      'Tek bir tişörtü üretmek için yaklaşık 2700 litre su gerekiyor.',
      'Takas günleri hem eğlenceli hem de çöpü azaltan bir gelenek.',
    ],
    category: CardCategory.cevre,
    emoji: '🧸',
  ),
  InfoCard(
    id: 'tamir_et',
    title: 'Tamir Etmek',
    question: 'Bozulanı tamir etmek neden çevreci?',
    answer:
        'Tamir edilen her eşya, üretilmeyen bir yeni eşyadır; onun madeni, '
        'suyu ve enerjisi de doğada kalır.',
    facts: [
      'Kopan bir düğmeyi dikmek bile bir kıyafeti yıllarca kurtarabiliyor.',
      'Bazı şehirlerde insanların eşyalarını birlikte onardığı tamir kafeleri '
          'var.',
    ],
    category: CardCategory.cevre,
    emoji: '🧵',
  ),
  InfoCard(
    id: 'su_tasarrufu',
    title: 'Su Tasarrufu',
    question: 'Diş fırçalarken musluğu kapatmak ne kazandırır?',
    answer:
        'Her fırçalamada yaklaşık 6 litre su. Günde iki kez yaparsan yılda bir '
        'küvet dolusundan çok daha fazla eder.',
    facts: [
      'Dünyadaki suyun sadece yüzde biri içilebilir tatlı su.',
      'Beş dakikalık duş, küvet doldurmaya göre çok daha az su harcıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🚿',
  ),
  InfoCard(
    id: 'damla_sulama',
    title: 'Damla Sulama',
    question: 'Tarlalar nasıl daha az suyla sulanır?',
    answer:
        'İnce borularla su doğrudan kökün dibine damlatılır. Böylece su '
        'buharlaşıp boşa gitmez.',
    facts: [
      'Damla sulama, klasik sulamaya göre yarı yarıya su tasarrufu '
          'sağlayabiliyor.',
      'Sabah erken sulanan bitkilerin suyu daha az buharlaşıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '💧',
  ),
  InfoCard(
    id: 'yagmur_suyu',
    title: 'Yağmur Suyu',
    question: 'Yağmur suyu toplanabilir mi?',
    answer:
        'Evet. Çatıdan inen su bir depoda biriktirilip bahçe sulamada ve '
        'temizlikte kullanılabilir.',
    facts: [
      'Orta büyüklükte bir çatı, tek bir sağanakta yüzlerce litre su '
          'toplayabiliyor.',
      'Yağmur suyu kireçsiz olduğu için bitkiler onu çok seviyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🌧️',
  ),
  InfoCard(
    id: 'temiz_su',
    title: 'Temiz Su',
    question: 'Musluktan akan su nereden gelir?',
    answer:
        'Barajlardan ve yer altı sularından. Borularla taşınır, arıtılır ve '
        'pompalarla evine ulaşır.',
    facts: [
      'Suyu taşımak ve arıtmak enerji harcar; su tasarrufu aynı zamanda enerji '
          'tasarrufudur.',
      'Dünyada her dört kişiden biri güvenli içme suyuna kolayca ulaşamıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🚰',
  ),
  InfoCard(
    id: 'gunes_paneli',
    title: 'Güneş Paneli',
    question: 'Güneşten elektrik nasıl üretilir?',
    answer:
        'Panellerin içindeki hücreler güneş ışığını yakalayıp doğrudan '
        'elektriğe çevirir. Ne duman çıkar ne gürültü.',
    facts: [
      'Güneş bir saatte dünyaya, insanlığın bir yılda harcadığından fazla '
          'enerji gönderiyor.',
      'Paneller bulutlu havada da çalışır, sadece daha az üretir.',
    ],
    category: CardCategory.cevre,
    emoji: '🔆',
  ),
  InfoCard(
    id: 'ruzgar_turbini',
    title: 'Rüzgâr Türbini',
    question: 'Rüzgâr gülleri nasıl elektrik yapar?',
    answer:
        'Rüzgâr kanatları döndürür, dönen mil jeneratörü çalıştırır ve '
        'elektrik üretilir.',
    facts: [
      'Tek bir büyük türbin, bir kasabanın evlerine yetecek elektrik '
          'üretebiliyor.',
      'Kanatları 80 metreye kadar uzayabiliyor; neredeyse bir futbol sahasının '
          'yarısı.',
    ],
    category: CardCategory.cevre,
    emoji: '🌬️',
  ),
  InfoCard(
    id: 'su_gucu',
    title: 'Su Gücü',
    question: 'Barajlar elektriği nasıl üretir?',
    answer:
        'Yüksekten düşen su devasa çarkları döndürür, bu dönüş elektriğe '
        'çevrilir.',
    facts: [
      'Su gücü, insanların binlerce yıldır kullandığı en eski enerji '
          'kaynaklarından biri.',
      'Su değirmenleri de aynı fikirle, akan suyla çalışıyordu.',
    ],
    category: CardCategory.cevre,
    emoji: '🏞️',
  ),
  InfoCard(
    id: 'led_ampul',
    title: 'LED Ampul',
    question: 'LED ampul neden tercih edilir?',
    answer: 'Aynı ışık için çok daha az elektrik harcar ve yıllarca dayanır.',
    facts: [
      'Eski ampuller enerjinin çoğunu ışığa değil ısıya çeviriyordu.',
      'Bir LED ampul 15 yıldan uzun süre kullanılabiliyor.',
    ],
    category: CardCategory.cevre,
    emoji: '💡',
  ),
  InfoCard(
    id: 'bekleme_modu',
    title: 'Bekleme Modu',
    question: 'Kapalı görünen cihaz elektrik harcar mı?',
    answer:
        'Evet. Kırmızı ışığı yanan televizyon, prizde unutulan şarj aleti '
        'sessizce elektrik çeker.',
    facts: [
      'Bu gizli tüketime hayalet enerji deniyor; faturanın onda birine kadar '
          'çıkabiliyor.',
      'Çoklu prizin düğmesini kapatmak hepsini bir anda durdurur.',
    ],
    category: CardCategory.cevre,
    emoji: '🔌',
  ),
  InfoCard(
    id: 'karbon_ayak_izi',
    title: 'Karbon Ayak İzi',
    question: 'Karbon ayak izi nedir?',
    answer:
        'Bir kişinin yaptıklarıyla havaya saldığı karbondioksit miktarı. '
        'Yolculuk, elektrik ve yediklerimiz bu izi büyütür.',
    facts: [
      'Yürümek ve bisiklet sürmek karbon ayak izi sıfır olan yolculuklar.',
      'Bir ağaç yılda ortalama 20 kilo karbondioksiti havadan alıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '👣',
  ),
  InfoCard(
    id: 'sera_etkisi',
    title: 'Sera Etkisi',
    question: 'Sera etkisi nedir?',
    answer:
        'Atmosferdeki bazı gazlar ısıyı tutar ve dünyayı yaşanabilir '
        'sıcaklıkta tutar. Ama gaz çoğalınca dünya fazla ısınır.',
    facts: [
      'Sera etkisi hiç olmasaydı dünyanın ortalaması eksi 18 derece olurdu.',
      'Adı seralardan geliyor: cam da ısıyı içeride tutar.',
    ],
    category: CardCategory.cevre,
    emoji: '🌡️',
  ),
  InfoCard(
    id: 'iklim_degisikligi',
    title: 'İklim Değişikliği',
    question: 'İklim değişikliği neden oluyor?',
    answer:
        'Kömür, petrol ve doğal gaz yakınca havaya çok fazla karbondioksit '
        'karışıyor; bu da dünyayı ısıtıyor.',
    facts: [
      'İklim ile hava aynı şey değil: hava bugünü, iklim onlarca yılı anlatır.',
      'Isınma arttıkça seller, kuraklıklar ve orman yangınları da artıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🌍',
  ),
  InfoCard(
    id: 'eriyen_buzullar',
    title: 'Eriyen Buzullar',
    question: 'Buzullar erirse ne olur?',
    answer:
        'Deniz seviyesi yükselir ve kıyıdaki şehirler su altında kalma riskine '
        'girer.',
    facts: [
      'Beyaz buz güneş ışığını yansıtır; buz azalınca dünya daha da hızlı '
          'ısınır.',
      'Kutup ayıları avlanmak için deniz buzuna muhtaç.',
    ],
    category: CardCategory.cevre,
    emoji: '🏔️',
  ),
  InfoCard(
    id: 'ozon_tabakasi',
    title: 'Ozon Tabakası',
    question: 'Ozon tabakası ne yapar?',
    answer:
        'Güneşin zararlı morötesi ışınlarını süzer; dünyanın görünmez güneş '
        'gözlüğü gibidir.',
    facts: [
      '1980\'lerde spreylerdeki gazlar ozon tabakasında bir delik açmıştı.',
      'Ülkeler o gazları yasaklayınca delik yavaş yavaş kapanmaya başladı.',
    ],
    category: CardCategory.cevre,
    emoji: '🛡️',
  ),
  InfoCard(
    id: 'hava_kirliligi',
    title: 'Hava Kirliliği',
    question: 'Havayı en çok ne kirletir?',
    answer:
        'Fabrika bacaları, egzozlar ve ısınmak için yakılan kömür. Havadaki '
        'minik parçacıklar ciğerlere kadar iner.',
    facts: [
      'Ağaçlar ve yeşil alanlar havadaki tozu tutarak filtre görevi görüyor.',
      'Bazı şehirler havayı ölçüp kirlilik yükselince trafiği sınırlıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🏭',
  ),
  InfoCard(
    id: 'agac_dikme',
    title: 'Ağaç Dikmek',
    question: 'Bir fidan dikmek neyi değiştirir?',
    answer:
        'Ağaç havadaki karbondioksiti alır, oksijen verir, toprağı tutar ve '
        'gölgesiyle şehri serinletir.',
    facts: [
      'Ağaç gölgesindeki hava, güneşteki havadan birkaç derece daha serin '
          'oluyor.',
      'Fidanın ilk iki yıl düzenli sulanması yaşama şansını çok artırıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🌱',
  ),
  InfoCard(
    id: 'yagmur_ormanlari',
    title: 'Yağmur Ormanları',
    question: 'Yağmur ormanlarına neden dünyanın ciğerleri denir?',
    answer:
        'Yoğun bitki örtüsüyle havayı temizler ve çok büyük miktarda '
        'karbondioksiti içlerinde saklarlar.',
    facts: [
      'Karada yaşayan canlı türlerinin yarısından fazlası yağmur ormanlarında.',
      'Kullandığımız birçok ilacın kaynağı bu ormanlardaki bitkiler.',
    ],
    category: CardCategory.cevre,
    emoji: '🌴',
  ),
  InfoCard(
    id: 'orman_yangini',
    title: 'Orman Yangını',
    question: 'Orman yangınlarının çoğu neden çıkar?',
    answer:
        'Çoğu insan yüzünden: söndürülmemiş bir ateş, atılan bir izmarit, '
        'hatta bir cam parçası bile yeterli olabiliyor.',
    facts: [
      'Yanan bir orman, yıllarca içinde sakladığı karbonu bir anda havaya '
          'bırakır.',
      'Yanan alanın eski hâline dönmesi onlarca yıl sürüyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🔥',
  ),
  InfoCard(
    id: 'erozyon',
    title: 'Erozyon',
    question: 'Toprak nasıl kaybolur?',
    answer:
        'Bitki örtüsü yok olunca yağmur ve rüzgâr verimli üst toprağı alıp '
        'götürür. Buna erozyon denir.',
    facts: [
      'Bir santimetre verimli toprağın oluşması yüzlerce yıl sürüyor.',
      'Ağaç kökleri toprağı bir ağ gibi tutarak erozyonu durduruyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🪨',
  ),
  InfoCard(
    id: 'fitoplankton',
    title: 'Denizdeki Oksijen',
    question: 'Soluduğumuz oksijenin çoğu nereden gelir?',
    answer:
        'Ormanlardan değil, denizden! Yüzeydeki minik fitoplanktonlar '
        'oksijenin yarısından fazlasını üretir.',
    facts: [
      'Gözle görülemeyecek kadar küçükler ama toplulukları uzaydan fark '
          'edilebiliyor.',
      'Aynı zamanda deniz besin zincirinin ilk halkasılar.',
    ],
    category: CardCategory.cevre,
    emoji: '🫧',
  ),
  InfoCard(
    id: 'deniz_copleri',
    title: 'Deniz Çöpleri',
    question: 'Denize giden çöpler nereye gider?',
    answer:
        'Akıntılar onları toplayıp dev çöp adaları oluşturur. En büyüğü '
        'Pasifik Okyanusu\'nda.',
    facts: [
      'Denizdeki çöpün büyük bölümü karadan, nehirler yoluyla geliyor.',
      'Kıyı temizliğine katılan gönüllüler bir günde tonlarca atık '
          'çıkarabiliyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🌊',
  ),
  InfoCard(
    id: 'mikroplastik',
    title: 'Mikroplastik',
    question: 'Mikroplastik nedir?',
    answer:
        'Parçalanan plastiklerden kalan, kum tanesinden küçük parçacıklar. '
        'Suya, balıklara ve oradan tabağımıza karışıyorlar.',
    facts: [
      'Sentetik kıyafetler yıkanırken bile minik plastik lifler bırakıyor.',
      'En yüksek dağın tepesinde ve okyanusun en derininde bile mikroplastik '
          'bulundu.',
    ],
    category: CardCategory.cevre,
    emoji: '🔬',
  ),
  InfoCard(
    id: 'biyocesitlilik',
    title: 'Biyoçeşitlilik',
    question: 'Biyoçeşitlilik neden önemli?',
    answer:
        'Doğa bir örgü gibidir, her canlı bir ilmiktir. Bir tür kaybolunca '
        'örgünün tamamı zayıflar.',
    facts: [
      'Yediğimiz bitkilerin çoğu arı, kelebek ve kuşlar polen taşıdığı için '
          'ürün veriyor.',
      'Tek çeşit bitki ekilen tarlalar hastalıklara çok daha açık oluyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🌼',
  ),
  InfoCard(
    id: 'nesli_tukenenler',
    title: 'Nesli Tükenenler',
    question: 'Bir tür neden yok olur?',
    answer:
        'Çoğunlukla evi elinden alındığı için: ormanlar kesilir, sular '
        'kirlenir, iklim değişir.',
    facts: [
      'Dev pandalar koruma çalışmaları sayesinde kritik tehlike listesinden '
          'çıktı.',
      'Milli parklar, türleri eviyle birlikte korumanın en etkili yolu.',
    ],
    category: CardCategory.cevre,
    emoji: '🐼',
  ),
  InfoCard(
    id: 'mercan_resifi',
    title: 'Mercan Resifi',
    question: 'Mercanlar neden beyazlaşır?',
    answer:
        'Deniz fazla ısınınca mercanlar içlerinde yaşayan renkli yosunları '
        'dışarı atar ve bembeyaz kalırlar.',
    facts: [
      'Resifler denizin yüzde birini kaplar ama deniz canlılarının dörtte '
          'birine ev sahipliği yapar.',
      'Bazı güneş kremlerindeki maddeler mercanlara zarar veriyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🪸',
  ),
  InfoCard(
    id: 'isik_kirliligi',
    title: 'Işık Kirliliği',
    question: 'Şehirde neden yıldız göremeyiz?',
    answer:
        'Gökyüzüne saçılan lamba ışığı havayı aydınlatır; bu parlaklık '
        'yıldızların ışığını bastırır.',
    facts: [
      'Deniz kaplumbağası yavruları bu ışığı denizle karıştırıp yanlış yöne '
          'gidebiliyor.',
      'Lambaların başlığını aşağı çevirmek hem gökyüzünü hem elektriği '
          'kurtarıyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🌃',
  ),
  InfoCard(
    id: 'gurultu_kirliligi',
    title: 'Gürültü Kirliliği',
    question: 'Gürültü de bir kirlilik midir?',
    answer:
        'Evet. Sürekli yüksek ses insanı yorar; hayvanların ise birbirini '
        'duymasını ve avlanmasını engeller.',
    facts: [
      'Gemi motorlarının sesi balinaların birbiriyle iletişimini bozuyor.',
      'Yol kenarındaki ağaç şeritleri gürültüyü de bir miktar süzüyor.',
    ],
    category: CardCategory.cevre,
    emoji: '🔇',
  ),
  // --- Hayvanlar ---------------------------------------------------------
  InfoCard(
    id: 'mavi_balina',
    title: 'Mavi Balina',
    question: 'Dünyanın en büyük hayvanı hangisi?',
    answer:
        'Mavi balina! Dev dinozorlardan bile daha ağır ve hâlâ okyanuslarda '
        'yaşıyor.',
    facts: [
      'Kalbi bir otomobil büyüklüğünde ve atışları kilometrelerce öteden '
          'duyulabiliyor.',
      'Dili tek başına bir fil kadar ağır olabiliyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐋',
  ),
  InfoCard(
    id: 'ahtapot',
    title: 'Ahtapot',
    question: 'Ahtapotun kaç kalbi var?',
    answer: 'Üç kalbi var. Kanı da kırmızı değil, mavi renkte.',
    facts: [
      'Sekiz kolunun her biri kendi başına hareket edebiliyor.',
      'Bulunduğu yerin rengine ve dokusuna bürünerek saklanabiliyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐙',
  ),
  InfoCard(
    id: 'ari_altigen',
    title: 'Arı Peteği',
    question: 'Arılar neden altıgen seçer?',
    answer:
        'Altıgenler boşluk bırakmadan yan yana dizilir. Böylece arılar en az '
        'balmumuyla en çok bal saklar.',
    facts: [
      'Bir işçi arı bir günde binlerce çiçeği gezebiliyor.',
      'Arılar dans ederek arkadaşlarına çiçeğin yerini tarif ediyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐝',
  ),
  InfoCard(
    id: 'penguen',
    title: 'İmparator Penguen',
    question: 'Penguenler neden birbirine sokulur?',
    answer:
        'Soğukta ısınmak için kalabalık olurlar ve sırayla dıştan içe geçerek '
        'herkesin ısınmasını sağlarlar.',
    facts: [
      'İmparator penguenler 500 metreden derine dalabiliyor.',
      'Tüylerinin üzerindeki yağ tabakası suyu geçirmiyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐧',
  ),
  InfoCard(
    id: 'zurafa',
    title: 'Zürafa',
    question: 'Zürafanın boynunda kaç omur var?',
    answer: 'İnsanla aynı: yedi. Ama zürafanın omurlarının her biri kocaman.',
    facts: [
      'Dili 45 santime kadar uzayabiliyor.',
      'Günde sadece yarım saat kadar uyuyabiliyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🦒',
  ),
  InfoCard(
    id: 'kutup_ayisi',
    title: 'Kutup Ayısı',
    question: 'Kutup ayısının tüyleri gerçekten beyaz mı?',
    answer:
        'Hayır! Tüyleri saydam, derisi ise simsiyah. Işığı yansıttıkları için '
        'bize beyaz görünüyorlar.',
    facts: [
      'Siyah deri güneş ısısını daha iyi tutuyor.',
      'Kokuyu kilometrelerce öteden alabiliyorlar.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐻‍❄️',
  ),
  InfoCard(
    id: 'deniz_kaplumbagasi',
    title: 'Deniz Kaplumbağası',
    question: 'Yavru kaplumbağalar denizi nasıl bulur?',
    answer:
        'Ayın deniz üzerindeki parıltısına doğru koşarlar. Işık kirliliği bu '
        'yüzden onlar için tehlikeli.',
    facts: [
      'Doğdukları kumsalı hatırlayıp yumurtlamak için yıllar sonra oraya '
          'dönüyorlar.',
      'Yuvadaki sıcaklık, yavruların dişi mi erkek mi olacağını belirliyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐢',
  ),
  InfoCard(
    id: 'yarasa',
    title: 'Yarasa',
    question: 'Yarasalar karanlıkta nasıl yol bulur?',
    answer:
        'Ses gönderip yankısını dinleyerek. Bu yönteme yankıyla yer bulma, '
        'yani ekolokasyon deniyor.',
    facts: [
      'Tek bir yarasa bir gecede binlerce sivrisinek yiyebiliyor.',
      'Uçabilen tek memeli hayvan yarasadır.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🦇',
  ),
  InfoCard(
    id: 'karinca',
    title: 'Karınca',
    question: 'Karıncalar yolu nasıl buluyor?',
    answer:
        'Arkalarında koku izi bırakırlar. Diğer karıncalar bu izi takip ederek '
        'yiyeceğe ulaşır.',
    facts: [
      'Kendi ağırlıklarının 50 katını taşıyabiliyorlar.',
      'Bir karınca yuvasında milyonlarca karınca yaşayabiliyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐜',
  ),
  InfoCard(
    id: 'kartal',
    title: 'Kartal',
    question: 'Kartallar ne kadar iyi görür?',
    answer:
        'Bizden yaklaşık dört kat keskin. Kilometrelerce yüksekten yerdeki bir '
        'tavşanı seçebiliyorlar.',
    facts: [
      'Sıcak hava akımlarına binerek kanat çırpmadan saatlerce süzülüyorlar.',
      'Yuvalarını yıllarca kullanıp her yıl biraz daha büyütüyorlar.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🦅',
  ),
  InfoCard(
    id: 'kelebek',
    title: 'Kelebek',
    question: 'Tırtıl kelebeğe nasıl dönüşür?',
    answer:
        'Kozanın içinde neredeyse tümüyle çözülür ve yeniden kurulur. Bu '
        'değişime başkalaşım denir.',
    facts: [
      'Kelebekler tadı ayaklarıyla alıyor.',
      'Bazı kelebekler göç için binlerce kilometre uçuyor.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🦋',
  ),
  InfoCard(
    id: 'fil',
    title: 'Fil',
    question: 'Filler hortumuyla neler yapar?',
    answer:
        'Koklar, su içer, duş alır, yiyecek toplar ve birbirini selamlar. '
        'Hortumda kemik yok ama binlerce kas var.',
    facts: [
      'Kulaklarını yelpaze gibi sallayarak serinliyorlar.',
      'Ayaklarıyla yerin titreşimini hissedip uzaktaki sürüyü duyabiliyorlar.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐘',
  ),
  InfoCard(
    id: 'yunus',
    title: 'Yunus',
    question: 'Yunuslar uyurken nasıl nefes alır?',
    answer:
        'Beyinlerinin yarısı uyurken diğer yarısı uyanık kalır. Böylece nefes '
        'almayı hiç unutmazlar.',
    facts: [
      'Birbirlerine isim gibi kullandıkları özel ıslıklarla sesleniyorlar.',
      'Suyun içinde ses göndererek etraflarını haritalıyorlar.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🐬',
  ),
  InfoCard(
    id: 'baykus',
    title: 'Baykuş',
    question: 'Baykuşlar neden sessiz uçar?',
    answer:
        'Tüylerinin kenarları tırtıklıdır ve havayı yumuşatır. Av onların '
        'geldiğini duymaz.',
    facts: [
      'Başlarını neredeyse dörtte üç tur çevirebiliyorlar.',
      'Gözleri kafalarında sabit olduğu için bakmak yerine başlarını '
          'çeviriyorlar.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🦉',
  ),
  InfoCard(
    id: 'kirpi',
    title: 'Kirpi',
    question: 'Kirpinin kaç dikeni var?',
    answer:
        'Yaklaşık 5000. Tehlike anında top gibi kıvrılıp hepsini dışarı diker.',
    facts: [
      'Dikenleri saç ve tırnakla aynı maddeden, keratinden yapılmış.',
      'Bahçedeki salyangoz ve böcekleri yediği için bahçıvanların dostu.',
    ],
    category: CardCategory.hayvanlar,
    emoji: '🦔',
  ),
  // --- Uzay --------------------------------------------------------------
  InfoCard(
    id: 'mars',
    title: 'Mars',
    question: 'Mars neden kırmızı görünür?',
    answer:
        'Toprağı pas doludur. Demirin paslanması gezegene kırmızı rengini '
        'verir.',
    facts: [
      'Güneş Sistemi\'nin en yüksek dağı Mars\'ta: Olympus Mons.',
      'Bir Mars günü 24 saat 37 dakika, yani bizim günümüze çok yakın.',
    ],
    category: CardCategory.uzay,
    emoji: '🪐',
  ),
  InfoCard(
    id: 'ay',
    title: 'Ay',
    question: 'Ay\'daki ayak izleri neden silinmiyor?',
    answer: 'Ay\'da rüzgâr ve yağmur yok; izleri silecek bir şey bulunmuyor.',
    facts: [
      'Ay her yıl Dünya\'dan yaklaşık 4 santim uzaklaşıyor.',
      'Ay\'ın çekimi Dünya\'nın altıda biri kadar; orada zıplamak çok kolay.',
    ],
    category: CardCategory.uzay,
    emoji: '🌙',
  ),
  InfoCard(
    id: 'gunes',
    title: 'Güneş',
    question: 'Güneş ne kadar büyük?',
    answer: 'İçine bir milyondan fazla Dünya sığar.',
    facts: [
      'Güneş\'in ışığı bize 8 dakikada ulaşıyor.',
      'Sarı görünse de aslında beyaz ışık yayıyor.',
    ],
    category: CardCategory.uzay,
    emoji: '☀️',
  ),
  InfoCard(
    id: 'saturn',
    title: 'Satürn',
    question: 'Satürn\'ün halkaları neyden yapılmış?',
    answer:
        'Milyarlarca buz ve kaya parçasından. Hepsi gezegenin çevresinde '
        'dönüyor.',
    facts: [
      'Satürn o kadar hafif ki kocaman bir havuza koysan yüzerdi.',
      'Bilinen 140\'tan fazla ayı var.',
    ],
    category: CardCategory.uzay,
    emoji: '🪐',
  ),
  InfoCard(
    id: 'yildizlar',
    title: 'Yıldızlar',
    question: 'Yıldızlar neden titrer gibi görünür?',
    answer:
        'Işıkları atmosferdeki hava katmanlarından geçerken bükülür; bize '
        'titriyormuş gibi görünür.',
    facts: [
      'Uzaydan bakıldığında yıldızlar titremez, sabit parlar.',
      'Güneş\'ten sonra en yakın yıldız 4 ışık yılı uzakta.',
    ],
    category: CardCategory.uzay,
    emoji: '⭐',
  ),
  InfoCard(
    id: 'karadelik',
    title: 'Kara Delik',
    question: 'Kara delik neden siyah görünür?',
    answer:
        'Çekimi o kadar güçlü ki ışık bile kaçamıyor. Işık gelmeyince biz de '
        'onu göremiyoruz.',
    facts: [
      'İlk kara delik fotoğrafı 2019\'da, dünyanın dört bir yanındaki '
          'teleskoplar birleşince çekildi.',
      'Galaksimizin merkezinde de dev bir kara delik var.',
    ],
    category: CardCategory.uzay,
    emoji: '🕳️',
  ),
  InfoCard(
    id: 'kuyruklu_yildiz',
    title: 'Kuyruklu Yıldız',
    question: 'Kuyruklu yıldızın kuyruğu neden oluşur?',
    answer:
        'Güneş\'e yaklaşınca buzu buharlaşır; gaz ve toz arkada uzun bir '
        'kuyruk bırakır.',
    facts: [
      'Kuyruk her zaman Güneş\'in ters yönüne bakar.',
      'Halley kuyruklu yıldızı 76 yılda bir görünüyor.',
    ],
    category: CardCategory.uzay,
    emoji: '☄️',
  ),
  InfoCard(
    id: 'samanyolu',
    title: 'Samanyolu',
    question: 'Gökyüzündeki o beyaz şerit nedir?',
    answer:
        'Kendi galaksimiz. Milyarlarca yıldızın ışığı uzaktan tek bir bulanık '
        'şerit gibi görünüyor.',
    facts: [
      'Samanyolu\'nda 100 milyardan fazla yıldız olduğu düşünülüyor.',
      'Karanlık bir köyde onu çıplak gözle görebilirsin.',
    ],
    category: CardCategory.uzay,
    emoji: '🌌',
  ),
  InfoCard(
    id: 'astronot',
    title: 'Astronot',
    question: 'Astronotlar uzayda neden süzülür?',
    answer:
        'Aslında sürekli Dünya\'ya doğru düşüyorlar; istasyon da onlarla '
        'birlikte düştüğü için ağırlıksız hissederler.',
    facts: [
      'Uzayda omurga rahatladığı için astronotlar birkaç santim uzuyor.',
      'Uyurken uçmasınlar diye uyku tulumlarını duvara bağlıyorlar.',
    ],
    category: CardCategory.uzay,
    emoji: '🧑‍🚀',
  ),
  InfoCard(
    id: 'uzay_istasyonu',
    title: 'Uzay İstasyonu',
    question: 'Uzay istasyonu ne kadar hızlı gider?',
    answer:
        'Saatte yaklaşık 28.000 kilometre. Dünya\'nın çevresini 90 dakikada '
        'bir dolaşır.',
    facts: [
      'Mürettebat bir günde 16 gün doğumu görüyor.',
      'İstasyondaki su, terden ve nemden tekrar tekrar arıtılıyor.',
    ],
    category: CardCategory.uzay,
    emoji: '🛰️',
  ),
  InfoCard(
    id: 'jupiter',
    title: 'Jüpiter',
    question: 'Jüpiter\'deki kırmızı leke nedir?',
    answer:
        'Yüzlerce yıldır dinmeyen dev bir fırtına. İçine Dünya rahatça sığar.',
    facts: [
      'Jüpiter, Güneş Sistemi\'nin bütün gezegenlerinden daha ağır.',
      'Bir Jüpiter günü sadece 10 saat sürüyor.',
    ],
    category: CardCategory.uzay,
    emoji: '🌪️',
  ),
  InfoCard(
    id: 'venus',
    title: 'Venüs',
    question: 'En sıcak gezegen hangisi?',
    answer:
        'Venüs. Güneş\'e en yakın gezegen olmasa da kalın bulutları ısıyı '
        'hapsettiği için 460 dereceye çıkıyor.',
    facts: [
      'Venüs\'te bir gün, bir yıldan uzun sürüyor.',
      'Bulutları kükürt asidinden yapılmış.',
    ],
    category: CardCategory.uzay,
    emoji: '☁️',
  ),
  InfoCard(
    id: 'yercekimi',
    title: 'Yer Çekimi',
    question: 'Her şey neden yere düşer?',
    answer:
        'Dünya kütlesiyle her şeyi kendine çeker. Aynı çekim Ay\'ı da '
        'yörüngesinde tutar.',
    facts: [
      'Ay\'da bir taş, Dünya\'dakinden altı kat hafif hissedilir.',
      'Tüy ile taş, hava olmayan bir yerde aynı anda düşer.',
    ],
    category: CardCategory.uzay,
    emoji: '🍎',
  ),
  InfoCard(
    id: 'meteor',
    title: 'Meteor',
    question: 'Kayan yıldız gerçekten yıldız mı?',
    answer:
        'Hayır. Atmosfere giren küçük bir taş parçasının sürtünmeyle '
        'yanmasıdır.',
    facts: [
      'Her gün dünyaya tonlarca uzay tozu yağıyor.',
      'Yere ulaşabilen parçalara göktaşı deniyor.',
    ],
    category: CardCategory.uzay,
    emoji: '💫',
  ),
  InfoCard(
    id: 'teleskop',
    title: 'Teleskop',
    question: 'Teleskop nasıl çalışır?',
    answer:
        'Büyük mercek ve aynalarla çok fazla ışık toplar; gözümüzün göremediği '
        'sönük şeyleri görünür kılar.',
    facts: [
      'Uzak yıldızlara bakmak aslında geçmişe bakmaktır; ışıkları yıllar önce '
          'yola çıktı.',
      'Uzaydaki teleskoplar atmosfer bulanıklığı olmadığı için çok daha net '
          'görüyor.',
    ],
    category: CardCategory.uzay,
    emoji: '🔭',
  ),
  // --- Doğa --------------------------------------------------------------
  InfoCard(
    id: 'mese_agaci',
    title: 'Meşe Ağacı',
    question: 'Bir meşe ağacı ne kadar yaşar?',
    answer: 'Yüzlerce yıl. Bazı meşeler 500 yaşını geçiyor.',
    facts: [
      'Bir meşe yılda binlerce palamut verebiliyor.',
      'Sincaplar sakladıkları palamutları unutunca yeni ağaçlar filizleniyor.',
    ],
    category: CardCategory.doga,
    emoji: '🌳',
  ),
  InfoCard(
    id: 'gokkusagi',
    title: 'Gökkuşağı',
    question: 'Gökkuşağı nasıl oluşur?',
    answer:
        'Güneş ışığı yağmur damlalarının içinde kırılır ve renklerine ayrılır.',
    facts: [
      'Gökkuşağını görmek için güneş her zaman arkanda olmalı.',
      'Uçaktan bakıldığında gökkuşağı tam bir daire görünebiliyor.',
    ],
    category: CardCategory.doga,
    emoji: '🌈',
  ),
  InfoCard(
    id: 'kar_tanesi',
    title: 'Kar Tanesi',
    question: 'İki kar tanesi birbirinin aynısı olur mu?',
    answer:
        'Neredeyse imkânsız. Her tane buluttan yere farklı bir yol izler ve '
        'deseni o yolda şekillenir.',
    facts: [
      'Kar tanelerinin hemen hepsi altı kolludur.',
      'Çok soğuk havada taneler küçük, ılık havada daha iri olur.',
    ],
    category: CardCategory.doga,
    emoji: '❄️',
  ),
  InfoCard(
    id: 'simsek',
    title: 'Şimşek',
    question: 'Şimşeği neden gök gürültüsünden önce görürüz?',
    answer: 'Işık, sesten çok daha hızlı yol alır.',
    facts: [
      'Şimşeği gördükten sonra saymaya başla: her 3 saniye yaklaşık 1 '
          'kilometre.',
      'Bir şimşek Güneş\'in yüzeyinden bile sıcak olabiliyor.',
    ],
    category: CardCategory.doga,
    emoji: '⚡',
  ),
  InfoCard(
    id: 'orman_agi',
    title: 'Orman Ağı',
    question: 'Ağaçlar birbiriyle haberleşir mi?',
    answer:
        'Evet! Kökleri mantar iplikleriyle birbirine bağlıdır; besin ve uyarı '
        'sinyalleri paylaşırlar.',
    facts: [
      'Bilim insanları bu ağa orman interneti diyor.',
      'Güçlü ağaçlar gölgede kalan yavru ağaçlara besin gönderebiliyor.',
    ],
    category: CardCategory.doga,
    emoji: '🍄',
  ),
  InfoCard(
    id: 'yanardag',
    title: 'Yanardağ',
    question: 'Lav nereden geliyor?',
    answer:
        'Yerin kilometrelerce altındaki erimiş kayadan. Yeryüzüne çıkınca adı '
        'magmadan lava dönüşür.',
    facts: [
      'Yanardağ külü toprağı çok verimli yaptığı için etekleri tarıma '
          'elverişli.',
      'Dünyadaki yanardağların çoğu okyanus tabanında.',
    ],
    category: CardCategory.doga,
    emoji: '🌋',
  ),
  InfoCard(
    id: 'deprem',
    title: 'Deprem',
    question: 'Yer neden sallanır?',
    answer:
        'Dünyanın kabuğu dev levhalardan oluşur. Levhalar birbirini itip '
        'aniden kayınca yer sarsılır.',
    facts: [
      'Aynı levha hareketi dağları da yükseltiyor.',
      'Depremin gücü sismograf denen aletle ölçülüyor.',
    ],
    category: CardCategory.doga,
    emoji: '⛰️',
  ),
  InfoCard(
    id: 'selale',
    title: 'Şelale',
    question: 'Şelaleler nasıl oluşur?',
    answer:
        'Akan su yumuşak kayayı sert kayadan daha hızlı aşındırır; arada bir '
        'basamak oluşur ve su oradan dökülür.',
    facts: [
      'Şelaleler zamanla geriye doğru yürüyor, çünkü kenar aşınmaya devam '
          'ediyor.',
      'Dökülen suyun kırdığı hava kabarcıkları köpüğü beyaz gösteriyor.',
    ],
    category: CardCategory.doga,
    emoji: '💦',
  ),
  InfoCard(
    id: 'col',
    title: 'Çöl',
    question: 'Çöller neden geceleri soğur?',
    answer:
        'Kuru havada ısıyı tutacak nem yoktur; gündüz biriken sıcaklık gece '
        'hızla uçup gider.',
    facts: [
      'Bir çölün çöl sayılması için sıcak olması şart değil, az yağmur alması '
          'yeterli.',
      'Antarktika dünyanın en büyük çölü.',
    ],
    category: CardCategory.doga,
    emoji: '🏜️',
  ),
  InfoCard(
    id: 'tuzlu_deniz',
    title: 'Tuzlu Deniz',
    question: 'Deniz suyu neden tuzlu?',
    answer:
        'Yağmur kayalardaki mineralleri çözüp nehirlerle denize taşır. Su '
        'buharlaşır, tuz kalır.',
    facts: [
      'Nehirler de tuz taşır ama denizde biriktiği için orada tuzluluk '
          'artıyor.',
      'Ölü Deniz o kadar tuzlu ki insan içinde batmadan yüzüyor.',
    ],
    category: CardCategory.doga,
    emoji: '🧂',
  ),
  InfoCard(
    id: 'ruzgar',
    title: 'Rüzgâr',
    question: 'Rüzgâr nasıl oluşur?',
    answer:
        'Güneş havayı her yerde eşit ısıtmaz. Sıcak hava yükselir, soğuk hava '
        'onun yerini almaya koşar; bu koşuşa rüzgâr deriz.',
    facts: [
      'Deniz kenarında gündüz denizden karaya, gece ters yönde eser.',
      'Rüzgâr tohumları kilometrelerce uzağa taşıyabiliyor.',
    ],
    category: CardCategory.doga,
    emoji: '🍃',
  ),
  InfoCard(
    id: 'sis',
    title: 'Sis',
    question: 'Sis nedir?',
    answer:
        'Yere değen bir bulut. Hava soğuyunca içindeki su buharı minik '
        'damlacıklara dönüşür.',
    facts: [
      'Sisin içinde yürürken aslında bulutun içindesin.',
      'Bazı bölgelerde sis toplayan filelerle içme suyu elde ediliyor.',
    ],
    category: CardCategory.doga,
    emoji: '🌫️',
  ),
  InfoCard(
    id: 'mevsimler',
    title: 'Mevsimler',
    question: 'Mevsimler neden değişir?',
    answer:
        'Dünya eğik durduğu için Güneş yılın farklı zamanlarında farklı '
        'bölgeleri daha dik ışıtır.',
    facts: [
      'Kuzey yarımkürede yaz olurken güneyde kış oluyor.',
      'Mevsimler Güneş\'e olan uzaklıktan değil, eğiklikten kaynaklanıyor.',
    ],
    category: CardCategory.doga,
    emoji: '🍂',
  ),
  InfoCard(
    id: 'bulutlar',
    title: 'Bulutlar',
    question: 'Bulutlar neden gökyüzünde durur?',
    answer:
        'İçlerindeki su damlacıkları o kadar küçük ki hava akımları onları '
        'kolayca havada tutar.',
    facts: [
      'Orta boy bir bulut yüzlerce ton su taşıyabiliyor.',
      'Damlacıklar birleşip ağırlaşınca yağmur olarak düşüyor.',
    ],
    category: CardCategory.doga,
    emoji: '☁️',
  ),
  InfoCard(
    id: 'gelgit',
    title: 'Gelgit',
    question: 'Deniz neden çekilip yükselir?',
    answer:
        'Ay\'ın çekimi denizleri kendine doğru hafifçe kaldırır. Dünya '
        'döndükçe bu kabarma kıyıları dolaşır.',
    facts: [
      'Günde genellikle iki kez gelgit oluyor.',
      'Bazı kıyılarda su seviyesi 15 metreye kadar değişebiliyor.',
    ],
    category: CardCategory.doga,
    emoji: '🌊',
  ),
  // --- Bilim -------------------------------------------------------------
  InfoCard(
    id: 'kalp',
    title: 'Kalbimiz',
    question: 'Kalbimiz günde kaç kez atar?',
    answer: 'Yaklaşık 100 bin kez. Hiç ara vermeden çalışır.',
    facts: [
      'Kalbin büyüklüğü senin yumruğun kadar.',
      'Kan, vücudunun tamamını yaklaşık bir dakikada dolaşıyor.',
    ],
    category: CardCategory.bilim,
    emoji: '❤️',
  ),
  InfoCard(
    id: 'kemikler',
    title: 'Kemikler',
    question: 'Bebeklerin mi yetişkinlerin mi daha çok kemiği var?',
    answer:
        'Bebeklerin! Yaklaşık 300 kemikle doğuyoruz, bazıları büyürken '
        'birleşip 206\'ya iniyor.',
    facts: [
      'En küçük kemiğimiz kulağımızın içinde.',
      'En uzun kemiğimiz uyluk kemiği.',
    ],
    category: CardCategory.bilim,
    emoji: '🦴',
  ),
  InfoCard(
    id: 'buz_yuzer',
    title: 'Yüzen Buz',
    question: 'Buz neden suda yüzer?',
    answer:
        'Su donarken genişler ve hafifler. Bu yüzden buz suyun üstünde kalır.',
    facts: [
      'Bu sayede göllerin yüzeyi donsa da altında canlılar yaşamaya devam '
          'eder.',
      'Su, bu şekilde davranan çok az maddeden biri.',
    ],
    category: CardCategory.bilim,
    emoji: '🧊',
  ),
  InfoCard(
    id: 'ses',
    title: 'Ses',
    question: 'Uzayda ses duyulur mu?',
    answer: 'Duyulmaz. Sesin yayılması için hava gibi bir taşıyıcı gerekir.',
    facts: [
      'Ses suda havadan yaklaşık 4 kat hızlı yol alır.',
      'Bu yüzden balinalar kilometrelerce öteden birbirini duyabiliyor.',
    ],
    category: CardCategory.bilim,
    emoji: '🔊',
  ),
  InfoCard(
    id: 'golge',
    title: 'Gölge',
    question: 'Gölgemiz neden bazen uzun bazen kısa?',
    answer: 'Güneş\'in gökyüzündeki açısı değiştikçe gölgenin boyu da değişir.',
    facts: [
      'Öğle vakti Güneş tepedeyken gölgen en kısa olur.',
      'Sabah ve akşam güneş yandan geldiği için gölgen uzar.',
    ],
    category: CardCategory.bilim,
    emoji: '🌓',
  ),
  InfoCard(
    id: 'beyin',
    title: 'Beyin',
    question: 'Beynimiz ne kadar enerji harcar?',
    answer:
        'Vücut ağırlığının sadece yüzde ikisi kadar olmasına rağmen '
        'enerjimizin beşte birini kullanır.',
    facts: [
      'Beyinde milyarlarca sinir hücresi birbirine sinyal gönderiyor.',
      'Yeni bir şey öğrendiğinde beyindeki bağlantılar gerçekten değişiyor.',
    ],
    category: CardCategory.bilim,
    emoji: '🧠',
  ),
  InfoCard(
    id: 'hapsirma',
    title: 'Hapşırma',
    question: 'Hapşırık ne kadar hızlıdır?',
    answer:
        'Saatte 150 kilometreye kadar çıkabilir. Burnu rahatsız eden şeyi '
        'dışarı atmak için ani bir patlama gibidir.',
    facts: [
      'Hapşırırken gözleri açık tutmak neredeyse imkânsız.',
      'Bazı insanlar parlak ışığa bakınca hapşırıyor.',
    ],
    category: CardCategory.bilim,
    emoji: '🤧',
  ),
  InfoCard(
    id: 'parmak_izi',
    title: 'Parmak İzi',
    question: 'Parmak izleri neden herkeste farklı?',
    answer:
        'Doğmadan önce, ana rahmindeki minik hareketler ve baskılarla '
        'şekillenirler. İkizlerde bile aynı değildir.',
    facts: [
      'Parmak izleri ıslak yüzeyleri daha iyi kavramamıza yardım ediyor.',
      'Koalaların parmak izleri insanınkine şaşırtıcı derecede benziyor.',
    ],
    category: CardCategory.bilim,
    emoji: '👆',
  ),
  InfoCard(
    id: 'miknatis',
    title: 'Mıknatıs',
    question: 'Pusula neden hep kuzeyi gösterir?',
    answer:
        'Dünyanın kendisi dev bir mıknatıstır. Pusulanın iğnesi bu görünmez '
        'alana göre yönelir.',
    facts: [
      'Bazı kuşlar göç ederken bu manyetik alanı hissediyor.',
      'Mıknatısın aynı kutupları birbirini iter, zıt kutupları çeker.',
    ],
    category: CardCategory.bilim,
    emoji: '🧲',
  ),
  InfoCard(
    id: 'statik_elektrik',
    title: 'Statik Elektrik',
    question: 'Balon saça neden yapışır?',
    answer:
        'Sürtününce balon saçtan minik yükler alır. Zıt yükler birbirini '
        'çektiği için saç balona koşar.',
    facts: [
      'Kapı koluna dokununca çarpan minik şok da aynı statik yük.',
      'Şimşek, bulutlarda biriken devasa bir statik boşalmadır.',
    ],
    category: CardCategory.bilim,
    emoji: '🎈',
  ),
  InfoCard(
    id: 'kaldirac',
    title: 'Kaldıraç',
    question: 'Ağır bir şeyi nasıl kolayca kaldırırız?',
    answer:
        'Bir kaldıraçla. Destek noktasını yüke yaklaştırınca aynı kuvvetle çok '
        'daha ağırını kaldırabilirsin.',
    facts: [
      'Makas, cımbız ve tahterevalli birer kaldıraç.',
      'Arşimet, yeterince uzun bir kaldıraçla dünyayı kaldırabileceğini '
          'söylemişti.',
    ],
    category: CardCategory.bilim,
    emoji: '🛠️',
  ),
  InfoCard(
    id: 'isik_renkler',
    title: 'Işık ve Renkler',
    question: 'Bir elma neden kırmızı görünür?',
    answer:
        'Üzerine düşen beyaz ışığın diğer renklerini yutar, sadece kırmızıyı '
        'geri yansıtır.',
    facts: [
      'Beyaz ışık aslında bütün renklerin karışımı.',
      'Siyah şeyler ışığın neredeyse tamamını yuttuğu için daha çabuk '
          'ısınıyor.',
    ],
    category: CardCategory.bilim,
    emoji: '🎨',
  ),
  InfoCard(
    id: 'dna',
    title: 'DNA',
    question: 'Gözümüzün rengini ne belirler?',
    answer:
        'Hücrelerimizdeki DNA. İçinde vücudumuzun nasıl kurulacağını anlatan '
        'talimatlar var.',
    facts: [
      'Bir hücredeki DNA açılsa yaklaşık iki metre uzunluğunda olurdu.',
      'İnsanların DNA\'sının yüzde 99\'dan fazlası birbirinin aynısı.',
    ],
    category: CardCategory.bilim,
    emoji: '🧬',
  ),
  InfoCard(
    id: 'ekmek_mayasi',
    title: 'Ekmek Mayası',
    question: 'Ekmek neden kabarır?',
    answer:
        'Mayadaki minik mantarlar şekeri yiyip gaz üretir. Hamurun içinde '
        'kalan gaz kabarcıkları onu şişirir.',
    facts: [
      'Maya canlıdır; sıcak suda uyanır, çok sıcakta ölür.',
      'Ekmeğin içindeki küçük delikler o gaz kabarcıklarının izi.',
    ],
    category: CardCategory.bilim,
    emoji: '🍞',
  ),
  InfoCard(
    id: 'uyku',
    title: 'Uyku',
    question: 'Neden uyumamız gerekir?',
    answer:
        'Uykuda beyin gün içinde öğrendiklerini düzenler, vücut ise kendini '
        'onarır.',
    facts: [
      'Yeni öğrenilen bilgiler en çok uyku sırasında kalıcı hâle geliyor.',
      'Çocukların büyüme hormonu en çok gece uykusunda salgılanıyor.',
    ],
    category: CardCategory.bilim,
    emoji: '😴',
  ),
];
