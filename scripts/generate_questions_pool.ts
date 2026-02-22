/**
 * generate_questions_pool.ts
 *
 * Expands app/assets/questions.json to a large, balanced pool.
 *
 * Goals:
 * - 1500+ total questions
 * - 120+ per intensity tier (1..10)
 * - 300+ NSFW entries (18+ only wording)
 * - Fully localized EN/DE/ES
 */

import { existsSync, readFileSync, writeFileSync } from 'fs';
import { dirname, resolve } from 'path';

type Energy = 'light' | 'medium' | 'heavy';

interface Question {
  id: string;
  text_en: string;
  text_de: string;
  text_es: string;
  category: string;
  subcategory: string;
  intensity: number;
  is_nsfw: boolean;
  is_premium: boolean;
  shock_factor: number;
  vulnerability_level: number;
  energy: Energy;
}

interface Triple {
  en: string;
  de: string;
  es: string;
}

const TARGET_PER_INTENSITY = 160; // 10 * 160 = 1600 total
const TOTAL_TARGET = TARGET_PER_INTENSITY * 10;

const CONTEXTS: Triple[] = [
  { en: 'at a house party', de: 'auf einer Hausparty', es: 'en una fiesta en casa' },
  { en: 'during a game night', de: 'bei einem Spieleabend', es: 'en una noche de juegos' },
  { en: 'on a weekend trip', de: 'auf einem Wochenendtrip', es: 'en un viaje de fin de semana' },
  { en: 'while everyone was watching', de: 'während alle zugeschaut haben', es: 'mientras todos miraban' },
  { en: 'in a group chat', de: 'in einem Gruppenchat', es: 'en un chat grupal' },
  { en: 'after midnight', de: 'nach Mitternacht', es: 'después de medianoche' },
  { en: 'during a birthday night', de: 'an einem Geburtstagsabend', es: 'en una noche de cumpleaños' },
  { en: 'on vacation', de: 'im Urlaub', es: 'de vacaciones' },
  { en: 'at a bar', de: 'in einer Bar', es: 'en un bar' },
  { en: 'on a first date', de: 'bei einem ersten Date', es: 'en una primera cita' },
  { en: 'at a festival', de: 'auf einem Festival', es: 'en un festival' },
  { en: 'during a team event', de: 'bei einem Team-Event', es: 'en un evento de equipo' },
  { en: 'at a friend gathering', de: 'bei einem Freundetreffen', es: 'en una reunión de amigos' },
  { en: 'while being stressed', de: 'als ich gestresst war', es: 'cuando estaba estresado' },
  { en: 'during a late night call', de: 'bei einem späten Telefonat', es: 'en una llamada nocturna' },
  { en: 'after one drink too many', de: 'nach einem Drink zu viel', es: 'después de una copa de más' },
  { en: 'before an important day', de: 'vor einem wichtigen Tag', es: 'antes de un día importante' },
  { en: 'while trying to impress someone', de: 'als ich jemanden beeindrucken wollte', es: 'mientras intentaba impresionar a alguien' },
  { en: 'when I felt lonely', de: 'als ich mich einsam gefühlt habe', es: 'cuando me sentí solo' },
  { en: 'when I felt jealous', de: 'als ich eifersüchtig war', es: 'cuando sentí celos' },
];

const MOTIVES: Triple[] = [
  { en: 'to avoid awkward silence', de: 'um peinliche Stille zu vermeiden', es: 'para evitar un silencio incómodo' },
  { en: 'to look cooler than I felt', de: 'um cooler zu wirken als ich mich gefühlt habe', es: 'para parecer más cool de lo que me sentía' },
  { en: 'to fit into the group', de: 'um in die Gruppe zu passen', es: 'para encajar en el grupo' },
  { en: 'to keep the mood up', de: 'um die Stimmung hochzuhalten', es: 'para mantener el ambiente arriba' },
  { en: 'because I panicked', de: 'weil ich in Panik war', es: 'porque entré en pánico' },
  { en: 'because I was curious', de: 'weil ich neugierig war', es: 'porque tenía curiosidad' },
  { en: 'because I wanted attention', de: 'weil ich Aufmerksamkeit wollte', es: 'porque quería atención' },
  { en: 'because I felt insecure', de: 'weil ich unsicher war', es: 'porque me sentía inseguro' },
  { en: 'to avoid conflict', de: 'um Streit zu vermeiden', es: 'para evitar conflicto' },
  { en: 'to protect my image', de: 'um mein Image zu schützen', es: 'para proteger mi imagen' },
  { en: 'to impress someone', de: 'um jemanden zu beeindrucken', es: 'para impresionar a alguien' },
  { en: 'without fully thinking it through', de: 'ohne alles zu Ende zu denken', es: 'sin pensarlo del todo' },
];

const NSFW_CONTEXTS: Triple[] = [
  { en: 'with someone I was very attracted to', de: 'mit jemandem, zu dem ich mich sehr hingezogen gefühlt habe', es: 'con alguien que me atraía mucho' },
  { en: 'after obvious flirting', de: 'nach eindeutigem Flirten', es: 'después de un coqueteo evidente' },
  { en: 'in a clearly charged moment', de: 'in einem eindeutig aufgeladenen Moment', es: 'en un momento claramente cargado' },
  { en: 'while crossing a personal boundary', de: 'während ich eine persönliche Grenze überschritten habe', es: 'mientras cruzaba un límite personal' },
  { en: 'in a situation that got intense fast', de: 'in einer Situation, die schnell intensiv wurde', es: 'en una situación que se volvió intensa rápido' },
  { en: 'with tension already in the room', de: 'während die Spannung im Raum schon da war', es: 'con tensión ya presente en la habitación' },
  { en: 'with feelings I did not fully admit', de: 'mit Gefühlen, die ich nicht ganz zugeben wollte', es: 'con sentimientos que no quería admitir del todo' },
  { en: 'while keeping it secret from someone', de: 'während ich es vor jemandem geheim gehalten habe', es: 'mientras lo mantenía en secreto de alguien' },
];

const NSFW_MOTIVES: Triple[] = [
  { en: 'because the chemistry felt intense', de: 'weil die Chemie intensiv war', es: 'porque la química se sentía intensa' },
  { en: 'because I wanted the thrill', de: 'weil ich den Kick wollte', es: 'porque quería la adrenalina' },
  { en: 'even though I knew it was risky', de: 'obwohl ich wusste, dass es riskant war', es: 'aunque sabía que era arriesgado' },
  { en: 'while ignoring my better judgment', de: 'während ich mein besseres Urteilsvermögen ignoriert habe', es: 'ignorando mi mejor juicio' },
  { en: 'because I was chasing validation', de: 'weil ich Bestätigung gesucht habe', es: 'porque buscaba validación' },
  { en: 'while keeping emotions hidden', de: 'während ich Gefühle versteckt habe', es: 'mientras ocultaba emociones' },
];

const TAIL_MOODS: Triple[] = [
  { en: 'on impulse', de: 'aus einem Impuls heraus', es: 'por impulso' },
  { en: 'for the plot', de: 'für die Story', es: 'por la trama' },
  { en: 'for the vibe', de: 'für den Vibe', es: 'por el ambiente' },
  { en: 'for fun', de: 'zum Spaß', es: 'por diversión' },
  { en: 'for attention', de: 'für Aufmerksamkeit', es: 'por atención' },
  { en: 'to feel brave', de: 'um mich mutig zu fühlen', es: 'para sentirme valiente' },
  { en: 'to feel included', de: 'um dazuzugehören', es: 'para sentirme incluido' },
  { en: 'to dodge awkwardness', de: 'um Peinlichkeit auszuweichen', es: 'para evitar incomodidad' },
  { en: 'without thinking twice', de: 'ohne lange nachzudenken', es: 'sin pensarlo mucho' },
  { en: 'to test my limits', de: 'um meine Grenzen zu testen', es: 'para probar mis límites' },
  { en: 'to keep up', de: 'um mitzuhalten', es: 'para seguir el ritmo' },
  { en: 'to avoid being boring', de: 'um nicht langweilig zu wirken', es: 'para no parecer aburrido' },
  { en: 'to prove a point', de: 'um etwas zu beweisen', es: 'para demostrar algo' },
  { en: 'to avoid conflict', de: 'um Konflikte zu vermeiden', es: 'para evitar conflicto' },
  { en: 'to feel seen', de: 'um gesehen zu werden', es: 'para sentirme visto' },
  { en: 'to match the mood', de: 'um zur Stimmung zu passen', es: 'para encajar con el ambiente' },
  { en: 'to break the silence', de: 'um die Stille zu brechen', es: 'para romper el silencio' },
  { en: 'to seem chill', de: 'um locker zu wirken', es: 'para parecer relajado' },
  { en: 'for the adrenaline', de: 'für den Adrenalinkick', es: 'por la adrenalina' },
  { en: 'because I was curious', de: 'weil ich neugierig war', es: 'porque tenía curiosidad' },
];

const TAIL_SCENES: Triple[] = [
  { en: 'in a crowded room', de: 'in einem vollen Raum', es: 'en una sala llena' },
  { en: 'on a random Tuesday', de: 'an einem zufälligen Dienstag', es: 'un martes cualquiera' },
  { en: 'during a long night', de: 'während einer langen Nacht', es: 'durante una noche larga' },
  { en: 'before sunrise', de: 'vor Sonnenaufgang', es: 'antes del amanecer' },
  { en: 'at the worst timing', de: 'zum schlechtesten Zeitpunkt', es: 'en el peor momento' },
  { en: 'at the perfect timing', de: 'zum perfekten Zeitpunkt', es: 'en el momento perfecto' },
  { en: 'when nobody expected it', de: 'als es niemand erwartet hat', es: 'cuando nadie lo esperaba' },
  { en: 'with bad reception', de: 'mit schlechtem Empfang', es: 'con mala señal' },
  { en: 'while multitasking', de: 'während ich mehrere Dinge gleichzeitig gemacht habe', es: 'mientras hacía varias cosas a la vez' },
  { en: 'with low battery', de: 'mit niedrigem Akku', es: 'con poca batería' },
  { en: 'in weekend chaos', de: 'im Wochenendchaos', es: 'en caos de fin de semana' },
  { en: 'in holiday mode', de: 'im Urlaubsmodus', es: 'en modo vacaciones' },
  { en: 'when everyone was loud', de: 'als alle laut waren', es: 'cuando todos estaban ruidosos' },
  { en: 'when everyone was quiet', de: 'als alle leise waren', es: 'cuando todos estaban callados' },
  { en: 'after a bold dare', de: 'nach einer mutigen Herausforderung', es: 'después de un reto atrevido' },
  { en: 'after too much overthinking', de: 'nach zu viel Grübeln', es: 'después de pensar demasiado' },
  { en: 'during a weird moment', de: 'in einem seltsamen Moment', es: 'en un momento raro' },
  { en: 'while things escalated fast', de: 'als alles schnell eskaliert ist', es: 'cuando todo escaló rápido' },
  { en: 'without a backup plan', de: 'ohne Plan B', es: 'sin plan B' },
  { en: 'with everyone watching', de: 'während alle zugeschaut haben', es: 'con todos mirando' },
];

function clamp01(n: number): number {
  return Math.max(0, Math.min(1, n));
}

function round2(n: number): number {
  return Math.round(n * 100) / 100;
}

function lcg(seed: number): () => number {
  let s = seed >>> 0;
  return () => {
    s = (1664525 * s + 1013904223) >>> 0;
    return s / 0xffffffff;
  };
}

function uniquePush(set: Set<string>, value: string): boolean {
  const key = value.toLowerCase().trim();
  if (set.has(key)) return false;
  set.add(key);
  return true;
}

function choose<T>(arr: T[], idx: number): T {
  return arr[idx % arr.length];
}

function stripPrefix(text: string, lang: 'en' | 'de' | 'es'): string {
  const prefix = lang === 'en'
    ? 'never have i ever'
    : lang === 'de'
      ? 'ich hab noch nie'
      : 'yo nunca nunca';

  let out = text.trim();
  while (out.toLowerCase().startsWith(prefix)) {
    out = out.slice(prefix.length).trim();
  }
  return out;
}

function compose(
  prefix: string,
  stem: string,
  parts: string[],
  requiredParts: string[] = [],
  max = 149,
): string {
  let out = `${prefix}${stem}`.trim();
  const requiredSet = new Set(requiredParts.filter(Boolean));
  for (const p of parts) {
    if (requiredSet.has(p)) continue;
    if (!p) continue;
    const next = `${out} ${p}`.trim();
    if (next.length <= max) out = next;
  }

  for (const p of requiredParts) {
    if (!p || out.includes(p)) continue;
    const next = `${out} ${p}`.trim();
    if (next.length <= max) {
      out = next;
      continue;
    }
    const budget = max - p.length - 1;
    if (budget > prefix.length + 5) {
      out = `${out.slice(0, budget).trim()} ${p}`.trim();
    }
  }

  return out.slice(0, max).trim();
}

function buildVariant(
  base: Question,
  intensity: number,
  variantIndex: number,
  isNsfw: boolean,
): Question {
  const context = choose(isNsfw ? NSFW_CONTEXTS : CONTEXTS, variantIndex * 7 + intensity);
  const motive = choose(isNsfw ? NSFW_MOTIVES : MOTIVES, variantIndex * 11 + intensity);
  const tailMood = choose(TAIL_MOODS, variantIndex * 13 + intensity);
  const tailScene = choose(TAIL_SCENES, variantIndex * 17 + intensity);
  const mode = variantIndex % 6;

  const stemEn = stripPrefix(base.text_en, 'en');
  const stemDe = stripPrefix(base.text_de, 'de');
  const stemEs = stripPrefix(base.text_es, 'es');

  let partsEn: string[] = [];
  let partsDe: string[] = [];
  let partsEs: string[] = [];

  if (mode === 0) {
    partsEn = [context.en, tailMood.en, tailScene.en];
    partsDe = [context.de, tailMood.de, tailScene.de];
    partsEs = [context.es, tailMood.es, tailScene.es];
  } else if (mode === 1) {
    partsEn = [motive.en, tailScene.en, tailMood.en];
    partsDe = [motive.de, tailScene.de, tailMood.de];
    partsEs = [motive.es, tailScene.es, tailMood.es];
  } else if (mode === 2) {
    partsEn = [motive.en, context.en, tailMood.en];
    partsDe = [motive.de, context.de, tailMood.de];
    partsEs = [motive.es, context.es, tailMood.es];
  } else if (mode === 3) {
    partsEn = [tailScene.en, context.en, tailMood.en];
    partsDe = [tailScene.de, context.de, tailMood.de];
    partsEs = [tailScene.es, context.es, tailMood.es];
  } else if (mode === 4) {
    partsEn = [tailMood.en, motive.en, context.en];
    partsDe = [tailMood.de, motive.de, context.de];
    partsEs = [tailMood.es, motive.es, context.es];
  } else {
    partsEn = [tailMood.en, tailScene.en, context.en];
    partsDe = [tailMood.de, tailScene.de, context.de];
    partsEs = [tailMood.es, tailScene.es, context.es];
  }

  const textEn = compose(
    'Never have I ever ',
    stemEn,
    partsEn,
    [tailMood.en, tailScene.en],
  );
  const textDe = compose(
    'Ich hab noch nie ',
    stemDe,
    partsDe,
    [tailMood.de, tailScene.de],
  );
  const textEs = compose(
    'Yo nunca nunca ',
    stemEs,
    partsEs,
    [tailMood.es, tailScene.es],
  );

  const jitter = ((variantIndex % 9) - 4) * 0.015;
  const baseShock = 0.08 + intensity * 0.07;
  const baseVuln = 0.06 + intensity * 0.065;
  let shock = clamp01(baseShock + jitter);
  let vulnerability = clamp01(baseVuln + jitter * 0.7);

  if (isNsfw) {
    shock = Math.max(shock, clamp01(0.45 + intensity * 0.045 + jitter));
    vulnerability = Math.max(vulnerability, clamp01(0.4 + intensity * 0.04 + jitter));
  }

  let energy: Energy = 'light';
  if (intensity >= 4 && intensity <= 7) energy = 'medium';
  if (intensity >= 8) energy = 'heavy';

  // Keep early rounds (1-4) capable of reaching all 3 energies for diversity.
  if (intensity <= 2 && variantIndex % 5 === 0) energy = 'medium';
  if (intensity <= 4 && variantIndex % 11 === 0) energy = 'heavy';
  if (isNsfw && intensity >= 7 && variantIndex % 4 === 0) energy = 'medium';

  const nsfwCategoryCycle = ['sexual', 'taboo', 'relationships', 'power_dynamics', 'confessions'];
  const nsfwSubCycle = ['flirting', 'boundaries', 'desire', 'secrets', 'temptation', 'situationship'];
  const safeCategoryCycle = ['food', 'embarrassing', 'social', 'moral_gray', 'risk_behavior', 'relationships', 'confessions', 'secrets', 'party', 'alcohol'];
  const safeSubCycle = ['habits', 'awkward', 'white_lies', 'faux_pas', 'private', 'public', 'heartbreak', 'guilt', 'boundaries', 'status'];

  let category = base.category;
  let subcategory = base.subcategory;
  if (isNsfw) {
    category = choose(nsfwCategoryCycle, variantIndex + intensity);
    subcategory = choose(nsfwSubCycle, variantIndex * 3 + intensity);
  } else if (intensity <= 4) {
    category = choose(safeCategoryCycle, variantIndex + intensity * 5);
    subcategory = choose(safeSubCycle, variantIndex * 2 + intensity * 3);
  }

  return {
    ...base,
    id: '',
    text_en: textEn,
    text_de: textDe,
    text_es: textEs,
    category,
    subcategory,
    intensity,
    is_nsfw: isNsfw,
    is_premium: isNsfw ? true : base.is_premium,
    shock_factor: round2(shock),
    vulnerability_level: round2(vulnerability),
    energy,
  };
}

function chooseNsfw(base: Question, intensity: number, variantIndex: number, rand: () => number): boolean {
  if (base.is_nsfw) return true;
  if (intensity <= 5) return false;
  const ratioByIntensity: Record<number, number> = {
    6: 0.2,
    7: 0.6,
    8: 0.75,
    9: 0.9,
    10: 0.95,
  };
  const ratio = ratioByIntensity[intensity] ?? 0;
  // mix deterministic pseudo-random with variant index for spread
  const r = (rand() + (variantIndex % 7) / 10) % 1;
  return r < ratio;
}

function expectedId(index: number, total: number): string {
  const width = Math.max(3, String(total).length);
  return `q${String(index + 1).padStart(width, '0')}`;
}

function main() {
  const root = resolve(dirname(new URL(import.meta.url).pathname), '..');
  const seedPath = resolve(root, 'app/assets/questions.seed.json');
  const outputPath = resolve(root, 'app/assets/questions.json');
  const inputPath = existsSync(seedPath) ? seedPath : outputPath;
  const raw = readFileSync(inputPath, 'utf-8');
  const source: Question[] = JSON.parse(raw);

  const byIntensity = new Map<number, Question[]>();
  for (const q of source) {
    byIntensity.set(q.intensity, [...(byIntensity.get(q.intensity) ?? []), q]);
  }
  const safePool = source.filter((q) => !q.is_nsfw);
  const nsfwPool = source.filter((q) => q.is_nsfw);

  const rand = lcg(0x1a2b3c4d);
  const out: Question[] = [];
  const seenEn = new Set<string>();
  const seenDe = new Set<string>();
  const seenEs = new Set<string>();

  for (let intensity = 1; intensity <= 10; intensity++) {
    const local: Question[] = [];
    const nearbyPool = byIntensity.get(intensity) ?? source.filter((q) => Math.abs(q.intensity - intensity) <= 1);
    if (nearbyPool.length === 0) {
      throw new Error(`No source questions available for intensity ${intensity}`);
    }

    let cursor = 0;
    let guard = 0;
    while (local.length < TARGET_PER_INTENSITY && guard < TARGET_PER_INTENSITY * 200) {
      guard++;
      const seedBase = nearbyPool[cursor % nearbyPool.length];
      const isNsfw = chooseNsfw(seedBase, intensity, cursor, rand);
      const basePool = isNsfw
        ? (nsfwPool.length > 0 ? nsfwPool : nearbyPool)
        : (safePool.length > 0 ? safePool : nearbyPool);
      const base = basePool[(cursor * 5 + intensity * 7) % basePool.length];
      const candidate = buildVariant(base, intensity, cursor, isNsfw);
      cursor++;

      // Ensure strict multilingual uniqueness.
      if (!uniquePush(seenEn, candidate.text_en)) continue;
      if (!uniquePush(seenDe, candidate.text_de)) continue;
      if (!uniquePush(seenEs, candidate.text_es)) continue;

      local.push(candidate);
    }

    if (local.length < TARGET_PER_INTENSITY) {
      throw new Error(
        `Could not generate enough unique questions for intensity ${intensity}. ` +
          `Generated ${local.length}/${TARGET_PER_INTENSITY}`,
      );
    }

    out.push(...local);
  }

  if (out.length !== TOTAL_TARGET) {
    throw new Error(`Unexpected total count ${out.length}, expected ${TOTAL_TARGET}`);
  }

  const withIds = out.map((q, i) => ({
    ...q,
    id: expectedId(i, TOTAL_TARGET),
  }));

  writeFileSync(outputPath, `${JSON.stringify(withIds, null, 2)}\n`, 'utf-8');

  const byI = new Map<number, number>();
  let nsfwCount = 0;
  for (const q of withIds) {
    byI.set(q.intensity, (byI.get(q.intensity) ?? 0) + 1);
    if (q.is_nsfw) nsfwCount++;
  }

  console.log(`Generated ${withIds.length} questions.`);
  for (let i = 1; i <= 10; i++) {
    console.log(`  intensity ${i}: ${byI.get(i) ?? 0}`);
  }
  console.log(`  nsfw=true: ${nsfwCount}`);
}

const isMain = process.argv[1] && (
  process.argv[1].endsWith('generate_questions_pool.ts') ||
  process.argv[1].endsWith('generate_questions_pool.js')
);

if (isMain) main();
