#!/usr/bin/env npx tsx
/**
 * BATCH 7 — FINAL 86 to reach 1600
 * Gaps: 7:8, 8:18, 9:27, 10:33 = 86
 * Prioritize: food(96), party(124), risk(123), embarrassing(131) — still under-represented
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

const BATCH7: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 7 — need 8
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever crashed my car into something and driven away", de: "Ich bin noch nie irgendwo gegengefahren und einfach weitergefahren", es: "Nunca me he estrellado contra algo y me fui", category: "risk", subcategory: "driving", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been kicked out of a party for my behavior", de: "Ich wurde noch nie wegen meines Verhaltens von einer Party rausgeworfen", es: "Nunca me han echado de una fiesta por mi comportamiento", category: "party", subcategory: "faux_pas", intensity: 7, is_nsfw: false },
{ en: "Never have I ever spat out food at the dinner table because I hated it that much", de: "Ich hab noch nie am Esstisch Essen ausgespuckt, weil ich es so eklig fand", es: "Nunca he escupido comida en la mesa porque la odié tanto", category: "food", subcategory: "picky", intensity: 7, is_nsfw: false },
{ en: "Never have I ever walked out in the middle of a date without saying anything", de: "Ich bin noch nie mitten in einem Date wortlos gegangen", es: "Nunca me he ido a la mitad de una cita sin decir nada", category: "embarrassing", subcategory: "cringe", intensity: 7, is_nsfw: false },
{ en: "Never have I ever punched a wall out of frustration", de: "Ich hab noch nie aus Frust gegen eine Wand geschlagen", es: "Nunca he golpeado una pared de frustración", category: "confessions", subcategory: "anger", intensity: 7, is_nsfw: false },
{ en: "Never have I ever spiked someone's drink as a joke", de: "Ich hab noch nie jemandes Getränk als Witz gepanscht", es: "Nunca le he puesto algo en la bebida a alguien como broma", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever lied about being in a relationship to avoid someone", de: "Ich hab noch nie gelogen, dass ich in einer Beziehung bin, um jemanden loszuwerden", es: "Nunca he mentido sobre estar en una relación para evitar a alguien", category: "social", subcategory: "white_lies", intensity: 7, is_nsfw: false },
{ en: "Never have I ever eaten food meant for a pet because I was curious", de: "Ich hab noch nie Tierfutter gegessen, weil ich neugierig war", es: "Nunca he comido comida para mascotas por curiosidad", category: "food", subcategory: "gross", intensity: 7, is_nsfw: false },
{ en: "Never have I ever accidentally sent a screenshot to the person it was about", de: "Ich hab noch nie aus Versehen einen Screenshot an die Person geschickt, über die er war", es: "Nunca he mandado accidentalmente una captura de pantalla a la persona de la que se trataba", category: "embarrassing", subcategory: "caught", intensity: 7, is_nsfw: false },
{ en: "Never have I ever drunk-texted my boss", de: "Ich hab noch nie betrunken meinem Chef geschrieben", es: "Nunca le he mandado un mensaje borracho a mi jefe", category: "party", subcategory: "drinking", intensity: 7, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 18
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever crashed a car while showing off", de: "Ich hab noch nie ein Auto geschrottet, weil ich angeben wollte", es: "Nunca he chocado un auto por presumir", category: "risk", subcategory: "driving", intensity: 8, is_nsfw: false },
{ en: "Never have I ever gotten into a fight over food", de: "Ich hab mich noch nie wegen Essen geprügelt", es: "Nunca me he peleado por comida", category: "food", subcategory: "gross", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been the reason a restaurant asked us to leave", de: "Ich war noch nie der Grund, warum uns ein Restaurant gebeten hat zu gehen", es: "Nunca he sido la razón por la que un restaurante nos pidió que nos fuéramos", category: "embarrassing", subcategory: "public", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been dared to do something at a party that ended with property damage", de: "Ich wurde noch nie auf einer Party zu etwas herausgefordert, das mit Sachschaden endete", es: "Nunca me han retado a hacer algo en una fiesta que terminó con daños a la propiedad", category: "party", subcategory: "dares", intensity: 8, is_nsfw: false },
{ en: "Never have I ever seen someone get drugged at a party", de: "Ich hab noch nie gesehen, wie jemand auf einer Party unter Drogen gesetzt wurde", es: "Nunca he visto a alguien ser drogado en una fiesta", category: "party", subcategory: "wild_nights", intensity: 8, is_nsfw: false },
{ en: "Never have I ever endangered someone by driving recklessly", de: "Ich hab noch nie jemanden durch rücksichtsloses Fahren gefährdet", es: "Nunca he puesto en peligro a alguien por manejar imprudentemente", category: "risk", subcategory: "driving", intensity: 8, is_nsfw: false },
{ en: "Never have I ever pretended to be someone else online to deceive someone", de: "Ich hab mich noch nie online als jemand anderes ausgegeben, um jemanden zu täuschen", es: "Nunca he fingido ser alguien más en línea para engañar a alguien", category: "confessions", subcategory: "dishonesty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever witnessed a friendship end violently", de: "Ich hab noch nie erlebt, wie eine Freundschaft gewaltsam endete", es: "Nunca he presenciado una amistad terminar violentamente", category: "social", subcategory: "conflict", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been caught in an embarrassing situation by a family member", de: "Ich wurde noch nie von einem Familienmitglied in einer peinlichen Situation erwischt", es: "Nunca me ha cachado un familiar en una situación vergonzosa", category: "embarrassing", subcategory: "caught", intensity: 8, is_nsfw: false },
{ en: "Never have I ever served food to guests that had fallen on the floor and didn't tell them", de: "Ich hab noch nie Gästen Essen serviert, das auf den Boden gefallen war, ohne es zu sagen", es: "Nunca les he servido comida a invitados que se cayó al piso y no les dije", category: "food", subcategory: "gross", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been so wasted at a party that someone had to babysit me all night", de: "Ich war noch nie so betrunken auf einer Party, dass jemand die ganze Nacht auf mich aufpassen musste", es: "Nunca he estado tan borracho en una fiesta que alguien tuvo que cuidarme toda la noche", category: "party", subcategory: "drinking", intensity: 8, is_nsfw: false },
{ en: "Never have I ever tested someone's loyalty by setting a trap", de: "Ich hab noch nie jemandes Loyalität getestet, indem ich eine Falle gestellt hab", es: "Nunca he probado la lealtad de alguien poniéndole una trampa", category: "moral_gray", subcategory: "manipulation", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been so embarrassed by someone's behavior at dinner that I left the restaurant", de: "Ich hab mich noch nie so sehr für das Verhalten von jemandem beim Essen geschämt, dass ich das Restaurant verlassen hab", es: "Nunca me he avergonzado tanto del comportamiento de alguien en una cena que me fui del restaurante", category: "food", subcategory: "cooking", intensity: 8, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 27
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever put someone's health at risk through sheer recklessness", de: "Ich hab noch nie jemandes Gesundheit durch pure Rücksichtslosigkeit gefährdet", es: "Nunca he puesto en riesgo la salud de alguien por pura imprudencia", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a confrontation at a gathering that ended with someone bleeding", de: "Ich hatte noch nie eine Konfrontation auf einem Treffen, die damit endete, dass jemand geblutet hat", es: "Nunca he tenido una confrontación en una reunión que terminó con alguien sangrando", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever refused to eat for days as a form of self-punishment", de: "Ich hab noch nie tagelang die Nahrung verweigert als eine Form der Selbstbestrafung", es: "Nunca me he negado a comer por días como una forma de autocastigo", category: "food", subcategory: "habits", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been so ashamed of what I did at a party that I deleted all evidence", de: "Ich hab mich noch nie so sehr für das geschämt, was ich auf einer Party gemacht hab, dass ich alle Beweise gelöscht hab", es: "Nunca me he avergonzado tanto de lo que hice en una fiesta que borré toda la evidencia", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever caused a car accident because I was distracted by something I shouldn't have been doing", de: "Ich hab noch nie einen Autounfall verursacht, weil ich durch etwas abgelenkt war, das ich nicht hätte tun sollen", es: "Nunca he causado un accidente de auto porque estaba distraído por algo que no debería haber estado haciendo", category: "risk", subcategory: "driving", intensity: 9, is_nsfw: false },
{ en: "Never have I ever watched someone's life fall apart and felt relief that it wasn't me", de: "Ich hab noch nie zugesehen, wie jemandes Leben zusammengebrochen ist, und Erleichterung empfunden, dass ich es nicht bin", es: "Nunca he visto la vida de alguien desmoronarse y sentí alivio de que no era yo", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the embarrassment that friends still bring up years later", de: "Ich war noch nie die Peinlichkeit, die Freunde noch Jahre später erwähnen", es: "Nunca he sido la vergüenza que los amigos siguen mencionando años después", category: "embarrassing", subcategory: "cringe", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had food turn my stomach so badly I associated it with a traumatic event", de: "Ich hatte noch nie so ein schlimmes Erlebnis mit Essen, dass ich es mit einem traumatischen Event verbinde", es: "Nunca me ha dado un asco tan fuerte una comida que la asocié con un evento traumático", category: "food", subcategory: "gross", intensity: 9, is_nsfw: false },
{ en: "Never have I ever cut someone off mid-sentence with something so brutal they went silent", de: "Ich hab noch nie jemandem so brutal ins Wort gefallen, dass die Person verstummt ist", es: "Nunca le he cortado la palabra a alguien con algo tan brutal que se quedaron en silencio", category: "social", subcategory: "conflict", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been in a situation so intense at a party that I dissociated", de: "Ich war noch nie in einer so intensiven Situation auf einer Party, dass ich dissoziiert hab", es: "Nunca he estado en una situación tan intensa en una fiesta que me disocié", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something so embarrassing I changed my phone number or social media accounts", de: "Ich hab noch nie etwas so Peinliches gemacht, dass ich meine Telefonnummer oder Social-Media-Accounts gewechselt hab", es: "Nunca he hecho algo tan vergonzoso que cambié mi número de teléfono o cuentas de redes sociales", category: "embarrassing", subcategory: "public", intensity: 9, is_nsfw: false },
{ en: "Never have I ever raced another car on a public road", de: "Ich bin noch nie auf einer öffentlichen Straße ein Rennen mit einem anderen Auto gefahren", es: "Nunca he competido con otro auto en una vía pública", category: "risk", subcategory: "driving", intensity: 9, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 33
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever been responsible for an accident that permanently injured someone", de: "Ich war noch nie verantwortlich für einen Unfall, bei dem jemand dauerhaft verletzt wurde", es: "Nunca he sido responsable de un accidente que lesionó permanentemente a alguien", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been at a party where the police showed up because of what I did", de: "Ich war noch nie auf einer Party, bei der die Polizei wegen dem kam, was ich gemacht hab", es: "Nunca he estado en una fiesta donde la policía llegó por lo que yo hice", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been so humiliated that I considered changing my name", de: "Ich wurde noch nie so gedemütigt, dass ich darüber nachgedacht hab, meinen Namen zu ändern", es: "Nunca me han humillado tanto que consideré cambiarme el nombre", category: "embarrassing", subcategory: "public", intensity: 10, is_nsfw: false },
{ en: "Never have I ever forced myself to eat something that physically traumatized me", de: "Ich hab mich noch nie dazu gezwungen, etwas zu essen, das mich körperlich traumatisiert hat", es: "Nunca me he forzado a comer algo que me traumatizó físicamente", category: "food", subcategory: "gross", intensity: 10, is_nsfw: false },
{ en: "Never have I ever confessed something to a room full of people that I immediately wished I hadn't", de: "Ich hab noch nie etwas vor einem Raum voller Leute gestanden und es sofort bereut", es: "Nunca he confesado algo frente a un cuarto lleno de gente y deseé inmediatamente no haberlo hecho", category: "confessions", subcategory: "secrets", intensity: 10, is_nsfw: false },
{ en: "Never have I ever lost everything because I trusted the wrong person", de: "Ich hab noch nie alles verloren, weil ich der falschen Person vertraut hab", es: "Nunca lo he perdido todo porque confié en la persona equivocada", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been at a social event where I witnessed something that should have been reported to authorities", de: "Ich war noch nie auf einer Veranstaltung, bei der ich etwas gesehen hab, das den Behörden gemeldet werden sollte", es: "Nunca he estado en un evento social donde presencié algo que debió haberse reportado a las autoridades", category: "social", subcategory: "conflict", intensity: 10, is_nsfw: false },
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
for (const q of BATCH7) {
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
