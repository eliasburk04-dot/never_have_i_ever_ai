/**
 * __tests__/validate_content.test.ts
 *
 * Tests for the content validation pipeline.
 */

import { describe, it, expect } from "vitest";
import { validateQuestion, validateDuplicates, detectGermanTransliterations, runContentValidation } from "../validate_content";

// ─── Fixtures ───────────────────────────────────────────────────────────────

function makeQuestion(overrides: Record<string, unknown> = {}) {
  return {
    id: "q001",
    text_en: "Never have I ever eaten pizza for breakfast",
    text_de: "Ich hab noch nie Pizza zum Frühstück gegessen",
    text_es: "Nunca he comido pizza en el desayuno",
    category: "food",
    subcategory: "habits",
    intensity: 1,
    is_nsfw: false,
    is_premium: false,
    shock_factor: 0.1,
    vulnerability_level: 0.05,
    energy: "light",
    ...overrides,
  } as any;
}

// ─── Universal Rules ────────────────────────────────────────────────────────

describe("Universal Rules", () => {
  it("U2: detects trailing whitespace", () => {
    const q = makeQuestion({ text_en: "Never have I ever eaten pizza " });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U2")).toBe(true);
  });

  it("U3: detects leading whitespace", () => {
    const q = makeQuestion({ text_de: " Ich hab noch nie Pizza gegessen" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U3")).toBe(true);
  });

  it("U4: detects doubled spaces", () => {
    const q = makeQuestion({ text_en: "Never have I ever  eaten pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U4")).toBe(true);
  });

  it("U6: detects text exceeding 150 chars", () => {
    const longText = "Never have I ever " + "a".repeat(140);
    const q = makeQuestion({ text_en: longText });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U6")).toBe(true);
  });

  it("U8: detects empty text field", () => {
    const q = makeQuestion({ text_de: "" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U8")).toBe(true);
  });

  it("U9: detects invalid id format", () => {
    const q = makeQuestion({ id: "question1" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U9")).toBe(true);
  });

  it("U9: detects id sequence gap", () => {
    const q = makeQuestion({ id: "q005" }); // at index 0, should be q001
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U9")).toBe(true);
  });

  it("U9: supports 4-digit id width for large pools", () => {
    const q = makeQuestion({ id: "q0001" });
    const v = validateQuestion(q, 0, 1600);
    expect(v.some((e) => e.rule === "U9")).toBe(false);
  });

  it("U10: detects intensity out of range", () => {
    const q = makeQuestion({ intensity: 11 });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U10")).toBe(true);
  });

  it("U10: detects non-integer intensity", () => {
    const q = makeQuestion({ intensity: 3.5 });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U10")).toBe(true);
  });

  it("U11: detects non-boolean is_nsfw", () => {
    const q = makeQuestion({ is_nsfw: "true" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U11")).toBe(true);
  });

  it("U12: detects shock_factor out of range", () => {
    const q = makeQuestion({ shock_factor: 1.5 });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U12")).toBe(true);
  });

  it("U13: detects invalid energy value", () => {
    const q = makeQuestion({ energy: "extreme" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U13")).toBe(true);
  });

  it("U14: detects invalid category", () => {
    const q = makeQuestion({ category: "random_stuff" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U14")).toBe(true);
  });

  it("U15: detects nsfw=true but premium=false", () => {
    const q = makeQuestion({ is_nsfw: true, is_premium: false });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U15")).toBe(true);
  });

  it("U16: detects HTML tags", () => {
    const q = makeQuestion({ text_en: "Never have I ever <b>eaten</b> pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "U16")).toBe(true);
  });

  it("passes a fully valid question", () => {
    const q = makeQuestion();
    const v = validateQuestion(q, 0);
    expect(v).toEqual([]);
  });
});

// ─── English Rules ──────────────────────────────────────────────────────────

describe("English Rules", () => {
  it("EN1: detects missing prefix", () => {
    const q = makeQuestion({ text_en: "I have never eaten pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "EN1")).toBe(true);
  });

  it("EN2: detects trailing period", () => {
    const q = makeQuestion({ text_en: "Never have I ever eaten pizza." });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "EN2")).toBe(true);
  });

  it("EN2: detects trailing question mark", () => {
    const q = makeQuestion({ text_en: "Never have I ever eaten pizza?" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "EN2")).toBe(true);
  });
});

// ─── German Rules ───────────────────────────────────────────────────────────

describe("German Rules", () => {
  it("DE1: detects missing prefix", () => {
    const q = makeQuestion({ text_de: "Noch nie hab ich Pizza gegessen" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(true);
  });

  it("DE1: accepts 'Ich hab mich noch nie' variant", () => {
    const q = makeQuestion({ text_de: "Ich hab mich noch nie geprügelt" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: accepts 'Ich war noch nie' variant", () => {
    const q = makeQuestion({ text_de: "Ich war noch nie auf meinen besten Freund neidisch" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE2: detects trailing period", () => {
    const q = makeQuestion({ text_de: "Ich hab noch nie Pizza gegessen." });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE2")).toBe(true);
  });

  it("DE3: detects ae transliteration", () => {
    const results = detectGermanTransliterations("Ich hab noch nie spaeter gegessen");
    expect(results.length).toBeGreaterThan(0);
    expect(results[0].match).toBe("ae");
  });

  it("DE3: allows Abenteuer (compound exception)", () => {
    const results = detectGermanTransliterations("Das war ein Abenteuer");
    expect(results).toEqual([]);
  });

  it("DE3: allows Bauer (compound exception)", () => {
    const results = detectGermanTransliterations("Der Bauer hat geerntet");
    expect(results).toEqual([]);
  });

  it("DE3: allows Feuer (compound exception)", () => {
    const results = detectGermanTransliterations("Das Feuer brennt");
    expect(results).toEqual([]);
  });

  it("DE3: detects ue transliteration in non-exception words", () => {
    const results = detectGermanTransliterations("Ich hab noch nie gefuehl gehabt");
    expect(results.length).toBeGreaterThan(0);
  });
});

// ─── Spanish Rules ──────────────────────────────────────────────────────────

describe("Spanish Rules", () => {
  it("ES1: detects missing prefix", () => {
    const q = makeQuestion({ text_es: "Yo nunca nunca he comido pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES1")).toBe(true);
  });

  it("ES1: accepts 'Nunca he' prefix", () => {
    const q = makeQuestion({ text_es: "Nunca he comido pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES1")).toBe(false);
  });

  it("ES1: accepts 'Nunca me he' prefix", () => {
    const q = makeQuestion({ text_es: "Nunca me he despertado tarde" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES1")).toBe(false);
  });

  it("ES1: accepts 'Nunca me han' prefix", () => {
    const q = makeQuestion({ text_es: "Nunca me han echado de un lugar" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES1")).toBe(false);
  });

  it("ES1: accepts 'Nunca hice' prefix", () => {
    const q = makeQuestion({ text_es: "Nunca hice trampa en un examen" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES1")).toBe(false);
  });

  it("ES2: detects trailing period", () => {
    const q = makeQuestion({ text_es: "Nunca he comido pizza." });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES2")).toBe(true);
  });
});

// ─── Duplicate Detection ────────────────────────────────────────────────────

describe("Duplicate Detection", () => {
  it("U7: detects duplicate English text", () => {
    const questions = [
      makeQuestion({ id: "q001", text_en: "Never have I ever eaten pizza" }),
      makeQuestion({ id: "q002", text_en: "Never have I ever eaten pizza" }),
    ];
    const v = validateDuplicates(questions);
    expect(v.some((e) => e.rule === "U7")).toBe(true);
  });

  it("U7: no false positive on different texts", () => {
    const questions = [
      makeQuestion({ id: "q001", text_en: "Never have I ever eaten pizza", text_de: "Ich hab noch nie Pizza gegessen", text_es: "Nunca he comido pizza" }),
      makeQuestion({ id: "q002", text_en: "Never have I ever eaten pasta", text_de: "Ich hab noch nie Pasta gegessen", text_es: "Nunca he comido pasta" }),
    ];
    const v = validateDuplicates(questions);
    expect(v).toEqual([]);
  });
});

// ─── Extended DE1 Prefix Variants ───────────────────────────────────────────

describe("DE1 Extended Prefix Variants", () => {
  it("DE1: accepts 'Ich hab mir noch nie' variant", () => {
    const q = makeQuestion({ text_de: "Ich hab mir noch nie einen Kater gewünscht" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: accepts 'Ich wäre noch nie' variant", () => {
    const q = makeQuestion({ text_de: "Ich wäre noch nie fast ertrunken" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: accepts 'Ich hatte als' variant", () => {
    const q = makeQuestion({ text_de: "Ich hatte als Kind einen imaginären Freund" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: accepts 'Ich hab es noch nie' variant", () => {
    const q = makeQuestion({ text_de: "Ich hab es noch nie bereut etwas gesagt zu haben" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: accepts 'Mir ist noch nie' variant", () => {
    const q = makeQuestion({ text_de: "Mir ist noch nie etwas Peinliches passiert" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: accepts 'Noch nie hat' variant", () => {
    const q = makeQuestion({ text_de: "Noch nie hat jemand mich beim Lügen erwischt" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(false);
  });

  it("DE1: rejects random German sentence", () => {
    const q = makeQuestion({ text_de: "Gestern habe ich Pizza gegessen" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "DE1")).toBe(true);
  });
});

// ─── Extended DE3 Compound Exceptions ───────────────────────────────────────

describe("DE3 Extended Compound Exceptions", () => {
  it("DE3: allows 'neuen' (neu + inflection)", () => {
    const results = detectGermanTransliterations("Einen neuen Anfang machen");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'Reue' (remorse)", () => {
    const results = detectGermanTransliterations("ohne Reue gelebt");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'Konsequenzen' (consequences)", () => {
    const results = detectGermanTransliterations("Die Konsequenzen tragen");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'zueinander' (to each other)", () => {
    const results = detectGermanTransliterations("Sie fanden zueinander");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'unbequemes' (uncomfortable)", () => {
    const results = detectGermanTransliterations("Ein unbequemes Gespräch");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'erneut' (again)", () => {
    const results = detectGermanTransliterations("Es erneut versucht");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'sexuell' (sexual)", () => {
    const results = detectGermanTransliterations("sexuell aktiv");
    expect(results).toEqual([]);
  });

  it("DE3: allows 'vertrauen' (trust)", () => {
    const results = detectGermanTransliterations("Ich vertraue dir");
    expect(results).toEqual([]);
  });
});

// ─── Integration: Full Dataset ──────────────────────────────────────────────

describe("Integration: questions.json", () => {
  it("runContentValidation returns 0 violations for the real dataset", () => {
    const { violations, total } = runContentValidation();
    expect(total).toBeGreaterThanOrEqual(1500);
    expect(violations).toEqual([]);
  });
});
