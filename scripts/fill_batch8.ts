#!/usr/bin/env npx tsx
/**
 * BATCH 8 — LAST 46 to reach 1600+
 * Gaps: 8:5, 9:15, 10:26 = 46
 * Extra buffer of ~4 in case of skips
 */

import * as fs from 'fs';
import * as path from 'path';

type Energy = 'light' | 'medium' | 'heavy';
interface QuestionDef { en: string; de: string; es: string; category: string; subcategory: string; intensity: number; is_nsfw: boolean; }

function computeMetadata(q: QuestionDef) {
  const i = q.intensity;
  let energy: Energy = i <= 3 ? 'light' : i <= 6 ? 'medium' : 'heavy';
  const base = (i - 1) / 9;
  const nB = q.is_nsfw ? 0.1 : 0;
  const sf = Math.round(Math.min(1, base + nB + (Math.random() * 0.08 - 0.04)) * 100) / 100;
  const vC = ['confessions', 'deep', 'relationships', 'moral_gray'].includes(q.category) ? 0.1 : 0;
  const vl = Math.round(Math.min(1, base * 0.9 + vC + (Math.random() * 0.06 - 0.03)) * 100) / 100;
  return { energy, shock_factor: sf, vulnerability_level: vl, is_premium: i >= 7 || q.is_nsfw };
}

const BATCH8: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 5
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever eaten something I found in a dumpster on a dare", de: "Ich hab noch nie auf eine Wette hin etwas aus einem Mülleimer gegessen", es: "Nunca he comido algo que encontré en un basurero por un reto", category: "food", subcategory: "challenges", intensity: 8, is_nsfw: false },
{ en: "Never have I ever lost control of my car at high speed", de: "Ich hab noch nie bei hoher Geschwindigkeit die Kontrolle über mein Auto verloren", es: "Nunca he perdido el control de mi auto a alta velocidad", category: "risk", subcategory: "driving", intensity: 8, is_nsfw: false },
{ en: "Never have I ever caused an evacuation", de: "Ich hab noch nie eine Evakuierung verursacht", es: "Nunca he causado una evacuación", category: "embarrassing", subcategory: "public", intensity: 8, is_nsfw: false },
{ en: "Never have I ever watched someone spiral and been too afraid to intervene", de: "Ich hab noch nie zugesehen, wie jemand abgestürzt ist, und war zu feige einzugreifen", es: "Nunca he visto a alguien caer en espiral y tuve demasiado miedo para intervenir", category: "moral_gray", subcategory: "loyalty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been the one everyone blamed even though it wasn't entirely my fault", de: "Ich war noch nie derjenige, dem alle die Schuld gaben, obwohl es nicht ganz meine Schuld war", es: "Nunca he sido al que todos culparon aunque no fue enteramente mi culpa", category: "social", subcategory: "conflict", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been intimate with someone purely to avoid feeling alone", de: "Ich war noch nie mit jemandem intim, nur um mich nicht allein zu fühlen", es: "Nunca he sido íntimo con alguien puramente para evitar sentirme solo", category: "sexual", subcategory: "boundaries", intensity: 8, is_nsfw: true },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 15
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever driven so recklessly I should have lost my license", de: "Ich bin noch nie so rücksichtslos gefahren, dass ich eigentlich meinen Führerschein hätte verlieren müssen", es: "Nunca he manejado tan imprudentemente que debí haber perdido mi licencia", category: "risk", subcategory: "driving", intensity: 9, is_nsfw: false },
{ en: "Never have I ever ruined a celebration with a confession that came at the worst time", de: "Ich hab noch nie eine Feier mit einem Geständnis ruiniert, das zum schlechtesten Zeitpunkt kam", es: "Nunca he arruinado una celebración con una confesión que llegó en el peor momento", category: "party", subcategory: "faux_pas", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been exposed for being a completely different person online vs. in real life", de: "Ich wurde noch nie dafür entlarvt, dass ich online eine komplett andere Person bin als im echten Leben", es: "Nunca me han expuesto por ser una persona completamente diferente en línea vs. en la vida real", category: "embarrassing", subcategory: "caught", intensity: 9, is_nsfw: false },
{ en: "Never have I ever poisoned the atmosphere at a dinner so badly nobody finished eating", de: "Ich hab noch nie die Stimmung bei einem Essen so vergiftet, dass niemand aufgegessen hat", es: "Nunca he envenenado el ambiente en una cena tan mal que nadie terminó de comer", category: "food", subcategory: "cooking", intensity: 9, is_nsfw: false },
{ en: "Never have I ever confronted someone with evidence I'd secretly gathered", de: "Ich hab noch nie jemanden mit Beweisen konfrontiert, die ich heimlich gesammelt hatte", es: "Nunca he confrontado a alguien con evidencia que reuní en secreto", category: "confessions", subcategory: "snooping", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been involved in a scene at a public event that made the news", de: "Ich war noch nie an einer Szene bei einem öffentlichen Event beteiligt, die in die Nachrichten kam", es: "Nunca he estado involucrado en una escena en un evento público que salió en las noticias", category: "embarrassing", subcategory: "public", intensity: 9, is_nsfw: false },
{ en: "Never have I ever burned a bridge so thoroughly I can never go back", de: "Ich hab noch nie eine Brücke so gründlich abgebrannt, dass ich nie zurückkann", es: "Nunca he quemado un puente tan completamente que nunca puedo volver", category: "social", subcategory: "conflict", intensity: 9, is_nsfw: false },
{ en: "Never have I ever discovered someone was living a double life because of something at a party", de: "Ich hab noch nie herausgefunden, dass jemand ein Doppelleben führt, wegen etwas auf einer Party", es: "Nunca he descubierto que alguien vivía una doble vida por algo que pasó en una fiesta", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever made a food-related mistake that put someone in the hospital", de: "Ich hab noch nie einen Fehler mit Essen gemacht, der jemanden ins Krankenhaus gebracht hat", es: "Nunca he cometido un error con comida que mandó a alguien al hospital", category: "food", subcategory: "cooking", intensity: 9, is_nsfw: false },
{ en: "Never have I ever overheard myself being described as toxic", de: "Ich hab noch nie mitgehört, wie ich als toxisch beschrieben wurde", es: "Nunca me he escuchado ser descrito como tóxico", category: "social", subcategory: "status", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the one everyone feared at a gathering", de: "Ich war noch nie die Person, vor der alle auf einem Treffen Angst hatten", es: "Nunca he sido la persona a la que todos temían en una reunión", category: "party", subcategory: "faux_pas", intensity: 9, is_nsfw: false },
{ en: "Never have I ever eaten or drunk something tampered with and found out afterward", de: "Ich hab noch nie etwas Manipuliertes gegessen oder getrunken und es erst danach herausgefunden", es: "Nunca he comido o tomado algo adulterado y me enteré después", category: "food", subcategory: "gross", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a risk I took result in someone I care about getting hurt", de: "Noch nie hat ein Risiko, das ich eingegangen bin, dazu geführt, dass jemand, der mir wichtig ist, verletzt wurde", es: "Nunca un riesgo que tomé resultó en que alguien que me importa saliera lastimado", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 26
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever failed to protect someone who was counting on me", de: "Ich hab noch nie jemanden im Stich gelassen, der auf mich gezählt hat", es: "Nunca he fallado en proteger a alguien que contaba conmigo", category: "moral_gray", subcategory: "loyalty", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the reason an entire group fell apart", de: "Ich war noch nie der Grund, warum eine ganze Gruppe auseinandergefallen ist", es: "Nunca he sido la razón por la que un grupo entero se desmoronó", category: "social", subcategory: "conflict", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a secret eating habit that I'm too ashamed to talk about", de: "Ich hatte noch nie eine geheime Essgewohnheit, für die ich mich zu sehr schäme, um darüber zu reden", es: "Nunca he tenido un hábito alimenticio secreto del que me da demasiada vergüenza hablar", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever done something at a party that I still have nightmares about", de: "Ich hab noch nie etwas auf einer Party gemacht, von dem ich immer noch Albträume hab", es: "Nunca he hecho algo en una fiesta de lo que todavía tengo pesadillas", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had my life spiral because of one reckless decision", de: "Mein Leben ist noch nie wegen einer einzigen leichtsinnigen Entscheidung außer Kontrolle geraten", es: "Nunca mi vida se ha desmoronado por una sola decisión imprudente", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been so embarrassed I couldn't leave my house for days", de: "Mir war noch nie so peinlich, dass ich tagelang nicht aus dem Haus gehen konnte", es: "Nunca me ha dado tanta vergüenza que no pude salir de mi casa por días", category: "embarrassing", subcategory: "public", intensity: 10, is_nsfw: false },
{ en: "Never have I ever kept a lie going so long it became my reality", de: "Ich hab noch nie eine Lüge so lange aufrechterhalten, dass sie zu meiner Realität wurde", es: "Nunca he mantenido una mentira por tanto tiempo que se convirtió en mi realidad", category: "confessions", subcategory: "dishonesty", intensity: 10, is_nsfw: false },
{ en: "Never have I ever lost all respect from people who once admired me", de: "Ich hab noch nie den gesamten Respekt von Leuten verloren, die mich einmal bewundert haben", es: "Nunca he perdido todo el respeto de personas que alguna vez me admiraron", category: "social", subcategory: "status", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a food-related trauma that I've never told anyone about", de: "Ich hatte noch nie ein Essenstrauma, über das ich noch nie mit jemandem gesprochen hab", es: "Nunca he tenido un trauma relacionado con comida del que nunca le he contado a nadie", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever witnessed something at a party that I've blocked from my memory", de: "Ich hab noch nie etwas auf einer Party gesehen, das ich aus meinem Gedächtnis verdrängt hab", es: "Nunca he presenciado algo en una fiesta que he bloqueado de mi memoria", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever made someone feel so small they never stood up for themselves again", de: "Ich hab noch nie jemanden so klein gemacht, dass sich die Person nie wieder für sich selbst eingesetzt hat", es: "Nunca he hecho sentir a alguien tan pequeño que nunca volvió a defenderse", category: "moral_gray", subcategory: "manipulation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a near-death experience that nobody else knows about", de: "Ich hatte noch nie ein Nahtoderlebnis, von dem niemand anderes weiß", es: "Nunca he tenido una experiencia cercana a la muerte que nadie más sabe", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever caused permanent damage to a relationship between two other people", de: "Ich hab noch nie dauerhaften Schaden in der Beziehung zwischen zwei anderen Personen angerichtet", es: "Nunca he causado daño permanente en la relación entre otras dos personas", category: "social", subcategory: "conflict", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been publicly humiliated at a gathering by someone I trusted", de: "Ich wurde noch nie auf einem Treffen öffentlich von jemandem gedemütigt, dem ich vertraut hab", es: "Nunca me han humillado públicamente en una reunión por alguien en quien confiaba", category: "embarrassing", subcategory: "public", intensity: 10, is_nsfw: false },
{ en: "Never have I ever driven someone to a breaking point on purpose", de: "Ich hab noch nie jemanden absichtlich an den Rand eines Zusammenbruchs gebracht", es: "Nunca he llevado a alguien al punto de quiebre a propósito", category: "moral_gray", subcategory: "manipulation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever experienced food scarcity that changed my relationship with eating", de: "Ich hatte noch nie Nahrungsmittelknappheit, die mein Verhältnis zum Essen verändert hat", es: "Nunca he experimentado escasez de comida que cambió mi relación con comer", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the person no one invited but everyone talked about", de: "Ich war noch nie die Person, die niemand eingeladen hat, aber über die alle geredet haben", es: "Nunca he sido la persona que nadie invitó pero de la que todos hablaban", category: "party", subcategory: "faux_pas", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been so reckless that I ended up with scars I have to explain", de: "Ich war noch nie so leichtsinnig, dass ich Narben davongetragen hab, die ich erklären muss", es: "Nunca he sido tan imprudente que terminé con cicatrices que tengo que explicar", category: "risk", subcategory: "stunts", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a moment of rage where I said something I can never take back", de: "Ich hatte noch nie einen Wutanfall, bei dem ich etwas gesagt hab, das ich nie zurücknehmen kann", es: "Nunca he tenido un momento de rabia donde dije algo que nunca puedo retirar", category: "confessions", subcategory: "anger", intensity: 10, is_nsfw: false },
{ en: "Never have I ever learned something about myself that made me rethink my entire past", de: "Ich hab noch nie etwas über mich gelernt, das mich meine gesamte Vergangenheit überdenken ließ", es: "Nunca he aprendido algo sobre mí que me hizo repensar todo mi pasado", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been in a group where everyone knew a secret about me except me", de: "Ich war noch nie in einer Gruppe, in der alle ein Geheimnis über mich kannten, außer ich", es: "Nunca he estado en un grupo donde todos sabían un secreto sobre mí excepto yo", category: "embarrassing", subcategory: "cringe", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been involved in a situation at a party that required lawyers", de: "Ich war noch nie an einer Situation auf einer Party beteiligt, die Anwälte erforderte", es: "Nunca he estado involucrado en una situación en una fiesta que requirió abogados", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever used food to manipulate someone emotionally", de: "Ich hab noch nie Essen benutzt, um jemanden emotional zu manipulieren", es: "Nunca he usado comida para manipular a alguien emocionalmente", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever put my life in someone else's hands and instantly regretted it", de: "Ich hab noch nie mein Leben in die Hände von jemand anderem gelegt und es sofort bereut", es: "Nunca he puesto mi vida en las manos de alguien más y me arrepentí al instante", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever destroyed evidence of something I did", de: "Ich hab noch nie Beweise für etwas vernichtet, das ich getan hab", es: "Nunca he destruido evidencia de algo que hice", category: "confessions", subcategory: "secrets", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been so ashamed of my behavior at a social event that I apologized to everyone individually", de: "Ich hab mich noch nie so sehr für mein Verhalten auf einer Veranstaltung geschämt, dass ich mich bei jedem einzeln entschuldigt hab", es: "Nunca me he avergonzado tanto de mi comportamiento en un evento social que me disculpé con todos individualmente", category: "embarrassing", subcategory: "cringe", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the person who made the entire room uncomfortable just by existing", de: "Ich war noch nie die Person, die den ganzen Raum allein durch ihre Anwesenheit unwohl gemacht hat", es: "Nunca he sido la persona que hizo que todo el cuarto se sintiera incómodo solo con mi presencia", category: "social", subcategory: "awkward", intensity: 10, is_nsfw: false },
{ en: "Never have I ever realized I am my own worst enemy", de: "Ich hab noch nie realisiert, dass ich mein eigener schlimmster Feind bin", es: "Nunca me he dado cuenta de que soy mi peor enemigo", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
];

// ═══════════════════════════════════════════════════════════
//  MERGE, DEDUP, WRITE
// ═══════════════════════════════════════════════════════════

const BASE_PATH = path.resolve(__dirname, '../app/assets/questions.json');
const base: any[] = JSON.parse(fs.readFileSync(BASE_PATH, 'utf-8'));

const seenEN = new Set<string>();
const deduped: any[] = [];
for (const q of base) {
  const key = q.text_en.toLowerCase().trim();
  if (!seenEN.has(key)) { seenEN.add(key); deduped.push(q); }
}
const baseDupes = base.length - deduped.length;
if (baseDupes > 0) console.log(`Removed ${baseDupes} dupes from base.`);

let added = 0, skipped = 0;
for (const q of BATCH8) {
  const key = q.en.toLowerCase().trim();
  if (seenEN.has(key)) { skipped++; console.log(`  SKIP: ${q.en.substring(0,60)}...`); continue; }
  seenEN.add(key);
  const meta = computeMetadata(q);
  deduped.push({
    id: `placeholder`,
    text_en: q.en, text_de: q.de, text_es: q.es,
    category: q.category, subcategory: q.subcategory, intensity: q.intensity,
    is_nsfw: q.is_nsfw, is_premium: meta.is_premium,
    shock_factor: meta.shock_factor, vulnerability_level: meta.vulnerability_level, energy: meta.energy,
  });
  added++;
}

for (let i = 0; i < deduped.length; i++) {
  deduped[i].id = `q${String(i + 1).padStart(4, '0')}`;
}

console.log(`\nBase: ${base.length} | Skipped: ${skipped} | Added: ${added} | Total: ${deduped.length}`);

const byInt = new Map<number, number>();
for (const q of deduped) byInt.set(q.intensity, (byInt.get(q.intensity) || 0) + 1);
console.log('\nDistribution by intensity:');
let need = 0;
for (let i = 1; i <= 10; i++) {
  const c = byInt.get(i) || 0;
  const g = Math.max(0, 160 - c);
  need += g;
  console.log(`  ${i}: ${c} ${g > 0 ? `(need ${g})` : '✅'}`);
}
console.log(`Total still needed: ${need}`);

const byCat = new Map<string, number>();
for (const q of deduped) byCat.set(q.category, (byCat.get(q.category) || 0) + 1);
console.log('\nBy category:');
for (const [c, n] of [...byCat.entries()].sort((a, b) => b[1] - a[1])) console.log(`  ${c}: ${n}`);

fs.writeFileSync(BASE_PATH, JSON.stringify(deduped, null, 2) + '\n', 'utf-8');
console.log(`\n✅ Wrote ${deduped.length} questions to ${BASE_PATH}`);
