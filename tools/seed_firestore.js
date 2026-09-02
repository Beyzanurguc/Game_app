#!/usr/bin/env node
/**
 * Tohum veriyi Firebase'e yükler.
 *
 *   seed/cards.json    -> Firestore `cards` koleksiyonu
 *   seed/puzzles.json  -> Firestore `puzzles` koleksiyonu
 *   seed/puzzles/*.jpg -> ilgili yapboz belgesinin `image` alanı (Bytes)
 *
 * Görseller Firebase Storage'a değil belgenin içine yazılıyor: Storage ücretli
 * plan (Blaze) gerektiriyor. 1200x1200 JPEG'ler 50-300 KB; Firestore'un 1 MiB
 * belge sınırının epey altında.
 *
 * Kurulum (proje kökünden):
 *   1. Firebase konsolu > Project settings > Service accounts >
 *      "Generate new private key". İnen dosyayı proje dışına, ör.
 *      C:/keys/foxy-admin.json olarak kaydet. Bu dosya depoya GİRMEMELİ.
 *   2. npm install --prefix tools firebase-admin
 *   3. node tools/seed_firestore.js --key=C:/keys/foxy-admin.json
 *
 * Anahtar yolu ortam değişkeniyle de verilebilir
 * (GOOGLE_APPLICATION_CREDENTIALS) ama --key her kabukta aynı çalıştığı için
 * önerilen yol o: PowerShell, cmd ve Git Bash ortam değişkenini farklı
 * sözdizimiyle ayarlıyor.
 *
 * Seçenekler:
 *   --key=<yol>   Servis hesabı anahtarı (JSON).
 *   --dry-run     Hiçbir şey yazmaz, ne yapacağını söyler.
 *   --cards-only  Yalnızca kartları yükler.
 *   --skip-images Yapboz belgelerini yazar ama görselleri gömmez.
 *
 * Betik yeniden çalıştırılabilir: belgeler kimliğe göre üzerine yazılır,
 * konsoldan elle eklenmiş başka kartlara dokunulmaz (silme yapmaz).
 */

const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'foxy-f429b';

const ROOT = path.resolve(__dirname, '..');
const SEED_DIR = path.join(ROOT, 'seed');

const argv = process.argv.slice(2);
const args = new Set(argv);
const dryRun = args.has('--dry-run');
const cardsOnly = args.has('--cards-only');
const skipImages = args.has('--skip-images');

/** --key=<yol> ya da GOOGLE_APPLICATION_CREDENTIALS. */
function keyPath() {
  const flag = argv.find((a) => a.startsWith('--key='));
  if (flag) return flag.slice('--key='.length).replace(/^["']|["']$/g, '');
  return process.env.GOOGLE_APPLICATION_CREDENTIALS || '';
}

/**
 * Kendi doğrulamalarımızın hatası.
 *
 * Ayrı tutuluyor: mesajı zaten ne yapılacağını söylüyor, üstüne bir de
 * Firebase ipucu eklenirse yanlış yöne gönderiyor.
 */
function fail(message) {
  const error = new Error(message);
  error.selfExplanatory = true;
  return error;
}

function readSeed(name) {
  const file = path.join(SEED_DIR, name);
  if (!fs.existsSync(file)) {
    throw fail(`${file} yok. seed/ klasörü depoda mı?`);
  }
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

// Firestore belge sınırı 1 MiB; metin alanlarına da pay bırakıp erken uyar.
const MAX_IMAGE_BYTES = 900 * 1024;

/** Firestore'a gruplar halinde yazar (toplu yazma sınırı). */
async function writeAll(db, collection, entries, chunk = 400) {
  const items = Object.entries(entries);
  for (let i = 0; i < items.length; i += chunk) {
    const batch = db.batch();
    for (const [id, data] of items.slice(i, i + chunk)) {
      batch.set(db.collection(collection).doc(id), data, { merge: true });
    }
    await batch.commit();
    console.log(`  ${collection}: ${Math.min(i + chunk, items.length)}/${items.length}`);
  }
}

async function main() {
  const key = keyPath();

  if (!dryRun) {
    if (!key) {
      throw fail(
        'Servis hesabı anahtarı verilmedi.\n' +
          '  node tools/seed_firestore.js --key=C:/keys/foxy-admin.json\n' +
          'Anahtarı Firebase konsolu > Project settings > Service accounts > ' +
          '"Generate new private key" ile indirirsin.'
      );
    }
    if (!fs.existsSync(key)) {
      throw fail(
        `Anahtar dosyası bulunamadı: ${key}\n` +
          'Yolu tam yaz ve ters bölü yerine düz bölü kullan (C:/keys/...).'
      );
    }
  }

  const cards = readSeed('cards.json');
  const puzzles = readSeed('puzzles.json');

  console.log(`Kart: ${Object.keys(cards).length}`);
  console.log(`Yapboz: ${Object.keys(puzzles).length}`);

  // Yüklemeden önce görsellerin yerinde olduğunu doğrula; yarım yükleme
  // uygulamada "seçilebilir ama açılmayan yapboz" demek.
  const missing = [];
  for (const [id, puzzle] of Object.entries(puzzles)) {
    const source = path.join(ROOT, puzzle.sourceAsset);
    if (!fs.existsSync(source)) missing.push(`${id}: ${puzzle.sourceAsset}`);
  }
  if (missing.length && !skipImages) {
    throw fail(`Eksik görsel:\n  ${missing.join('\n  ')}`);
  }

  if (dryRun) {
    console.log('\n--dry-run: hiçbir şey yazılmadı.');
    return;
  }

  // firebase-admin bilerek burada yükleniyor: --dry-run doğrulaması hiçbir
  // paket kurmadan, kimlik ayarlamadan çalışsın.
  const admin = require('firebase-admin');

  admin.initializeApp({
    credential: admin.credential.cert(path.resolve(key)),
    projectId: PROJECT_ID,
  });
  const db = admin.firestore();

  console.log('\nKartlar yükleniyor...');
  await writeAll(db, 'cards', cards);

  if (cardsOnly) {
    console.log('\n--cards-only: yapbozlar atlandı.');
    return;
  }

  console.log('\nYapboz belgeleri yazılıyor...');
  // sourceAsset yalnızca yükleme için; uygulamanın işine yaramaz.
  const documents = {};
  for (const [id, puzzle] of Object.entries(puzzles)) {
    const { sourceAsset, ...rest } = puzzle;

    if (!skipImages) {
      const bytes = fs.readFileSync(path.join(ROOT, sourceAsset));
      if (bytes.length > MAX_IMAGE_BYTES) {
        throw fail(
          `${id}: görsel ${Math.round(bytes.length / 1024)} KB, sınır ` +
            `${Math.round(MAX_IMAGE_BYTES / 1024)} KB.\n` +
            'tools/prepare_puzzle_images.py içindeki QUALITY değerini düşür ' +
            'ya da TARGET boyutunu küçült.'
        );
      }
      // Node SDK'da ayrı bir Bytes sarmalayıcısı yok: Buffer (ve Uint8Array)
      // doğrudan Firestore'un bytes alanına yazılıyor. Dart tarafı bunu Blob
      // olarak okuyor.
      rest.image = bytes;
      console.log(`  ${id}: ${Math.round(bytes.length / 1024)} KB gömüldü`);
    }

    documents[id] = rest;
  }
  // Görseller belgenin içinde olduğu için gruplar küçük: bir toplu yazma
  // isteği en fazla 10 MiB olabiliyor.
  await writeAll(db, 'puzzles', documents, 5);

  console.log('\nTamamlandı.');
}

/**
 * Firebase hatalarını ne yapılacağını söyleyen bir ipucuna çevirir.
 *
 * Ham hatalar ("5 NOT_FOUND", "Invalid PEM") tek başına hangi konsol adımının
 * eksik olduğunu söylemiyor.
 */
function hintFor(error) {
  const text = `${error.code || ''} ${error.message || ''}`;

  if (/INVALID_ARGUMENT|too large|exceeds the maximum/i.test(text)) {
    return (
      'Bir belge Firestore sınırını aştı. Görsel çok büyük olabilir; ' +
      'tools/prepare_puzzle_images.py içindeki QUALITY değerini düşür.'
    );
  }
  if (/NOT_FOUND|does not exist.*database|database.*does not exist/i.test(text)) {
    return (
      'Firestore veritabanı henüz oluşturulmamış görünüyor.\n' +
      'Konsol > Firestore Database > "Create database" (production mode).'
    );
  }
  if (/PERMISSION_DENIED|caller does not have permission/i.test(text)) {
    return (
      'Servis hesabının yetkisi yok. Anahtarı doğru projeden (foxy-f429b) ' +
      'indirdiğinden ve hesabın "Firebase Admin SDK" rolünde olduğundan emin ol.'
    );
  }
  if (/PEM|private key|Invalid.*credential|Failed to parse/i.test(text)) {
    return (
      'Anahtar dosyası okunamadı. Bu, Service accounts sayfasından inen ' +
      '"private key" JSON dosyası olmalı — google-services.json DEĞİL.'
    );
  }
  if (/UNAUTHENTICATED|invalid_grant|Invalid JWT/i.test(text)) {
    return (
      'Kimlik doğrulanamadı. Bilgisayarın saati doğru mu? Anahtar iptal ' +
      'edilmiş olabilir; konsoldan yeni bir tane üret.'
    );
  }
  if (/ENOTFOUND|ETIMEDOUT|ECONNREFUSED|network/i.test(text)) {
    return 'Ağa çıkılamadı. İnternet bağlantını kontrol et.';
  }
  return '';
}

main().catch((error) => {
  console.error(`\nHata: ${error.message}`);

  const hint = error.selfExplanatory ? '' : hintFor(error);
  if (hint) console.error(`\n${hint}`);
  else if (error.code) console.error(`\n(kod: ${error.code})`);

  process.exit(1);
});
