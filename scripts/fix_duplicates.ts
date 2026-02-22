#!/usr/bin/env npx tsx
/**
 * fix_duplicates.ts — Remove near-duplicate questions and replace with fresh ones
 * to maintain 1604 count. Then fix remaining DE/ES dupes by rewording.
 */

import * as fs from 'fs';
import * as path from 'path';

type Energy = 'light' | 'medium' | 'heavy';

function computeMetadata(intensity: number, category: string, is_nsfw: boolean) {
  const i = intensity;
  let energy: Energy = i <= 3 ? 'light' : i <= 6 ? 'medium' : 'heavy';
  const base = (i - 1) / 9;
  const nB = is_nsfw ? 0.1 : 0;
  const sf = Math.round(Math.min(1, Math.max(0, base + nB + (Math.random() * 0.08 - 0.04))) * 100) / 100;
  const vC = ['confessions', 'deep', 'relationships', 'moral_gray'].includes(category) ? 0.1 : 0;
  const vl = Math.round(Math.min(1, Math.max(0, base * 0.9 + vC + (Math.random() * 0.06 - 0.03))) * 100) / 100;
  return { energy, shock_factor: sf, vulnerability_level: vl, is_premium: i >= 7 || is_nsfw };
}

const FILE = path.resolve(__dirname, '../app/assets/questions.json');
const questions: any[] = JSON.parse(fs.readFileSync(FILE, 'utf-8'));

// IDs to remove (keep the first in each pair, remove the second)
const removeIds = new Set([
  'q1175', // dupe of q0188 (bank account)
  'q1189', // dupe of q0286 (scene at restaurant)  
  'q1227', // dupe of q0396 (first date sex)
  'q1031', // dupe of q0462 (sexual encounter regret)
  'q0980', // dupe of q0163 (cheated on test) — remove the broader version, keep simpler
  'q0970', // dupe of q0269 (skinny dipping)
  'q1016', // dupe of q0353 (sex to get over someone)
]);

let removed = questions.filter(q => removeIds.has(q.id));
console.log(`Removing ${removed.length} duplicate questions:`);
for (const q of removed) {
  console.log(`  ${q.id}: ${q.text_en.substring(0, 60)}... (int=${q.intensity})`);
}

let filtered = questions.filter(q => !removeIds.has(q.id));

// Now fix the remaining ES dupe: q0269 skinny dipping stays, but we already removed q0970.
// Also fix DE dupe for q0286 — it's the only one remaining in its pair.
// All pairs are now resolved by removal.

// Add 7 replacement questions to maintain count
const replacements = [
  { en: "Never have I ever lost my phone at a festival", de: "Ich hab noch nie mein Handy auf einem Festival verloren", es: "Nunca he perdido mi teléfono en un festival", category: "party", subcategory: "wild_nights", intensity: 3, is_nsfw: false },
  { en: "Never have I ever double-dipped at a party", de: "Ich hab noch nie auf einer Party doppelt gedippt", es: "Nunca he metido la misma cosa dos veces en la salsa en una fiesta", category: "food", subcategory: "gross", intensity: 5, is_nsfw: false },
  { en: "Never have I ever regretted a text the moment I sent it", de: "Ich hab noch nie eine Nachricht bereut, in dem Moment, in dem ich sie abgeschickt hab", es: "Nunca me he arrepentido de un mensaje en el momento en que lo mandé", category: "embarrassing", subcategory: "cringe", intensity: 7, is_nsfw: false },
  { en: "Never have I ever had someone read my messages out loud in front of others", de: "Noch nie hat jemand meine Nachrichten vor anderen laut vorgelesen", es: "Nunca alguien ha leído mis mensajes en voz alta frente a otros", category: "embarrassing", subcategory: "caught", intensity: 7, is_nsfw: false },
  { en: "Never have I ever seen someone's true colors at their worst moment and still stood by them", de: "Ich hab noch nie jemandes wahres Gesicht in dessen schlechtestem Moment gesehen und trotzdem zu der Person gestanden", es: "Nunca he visto los verdaderos colores de alguien en su peor momento y aún así me quedé a su lado", category: "deep", subcategory: "growth", intensity: 9, is_nsfw: false },
  { en: "Never have I ever realized that the version of me others know is completely different from who I really am", de: "Ich hab noch nie realisiert, dass die Version von mir, die andere kennen, komplett anders ist als wer ich wirklich bin", es: "Nunca me he dado cuenta de que la versión de mí que otros conocen es completamente diferente de quien realmente soy", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
  { en: "Never have I ever been handed a drink at a party and just trusted it", de: "Mir wurde noch nie auf einer Party ein Getränk gereicht und ich hab einfach vertraut", es: "Nunca me han dado una bebida en una fiesta y simplemente confié", category: "risk", subcategory: "substances", intensity: 8, is_nsfw: false },
];

for (const r of replacements) {
  const meta = computeMetadata(r.intensity, r.category, r.is_nsfw);
  filtered.push({
    id: 'placeholder',
    text_en: r.en, text_de: r.de, text_es: r.es,
    category: r.category, subcategory: r.subcategory, intensity: r.intensity,
    is_nsfw: r.is_nsfw, is_premium: meta.is_premium,
    shock_factor: meta.shock_factor, vulnerability_level: meta.vulnerability_level, energy: meta.energy,
  });
}

// Re-assign sequential IDs
for (let i = 0; i < filtered.length; i++) {
  filtered[i].id = `q${String(i + 1).padStart(4, '0')}`;
}

console.log(`\nResult: ${filtered.length} questions (removed ${removed.length}, added ${replacements.length})`);

// Verify no remaining DE/ES dupes
for (const lang of ['text_de', 'text_es'] as const) {
  const seen = new Map<string, string>();
  let dupes = 0;
  for (const q of filtered) {
    const key = q[lang]?.toLowerCase().trim();
    const existing = seen.get(key);
    if (existing) { dupes++; console.log(`  Remaining ${lang} dupe: ${existing} ↔ ${q.id}`); }
    else seen.set(key, q.id);
  }
  if (dupes === 0) console.log(`${lang}: no duplicates ✅`);
}

fs.writeFileSync(FILE, JSON.stringify(filtered, null, 2) + '\n', 'utf-8');
console.log(`\n✅ Wrote ${filtered.length} questions`);
