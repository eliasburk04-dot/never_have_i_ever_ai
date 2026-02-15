/**
 * __tests__/validate_content.test.ts
 *
 * Tests for the content validation pipeline.
 */

import { describe, it, expect } from "vitest";
import { validateQuestion, validateDuplicates, detectGermanTransliterations } from "../validate_content";

// ─── Fixtures ───────────────────────────────────────────────────────────────

function makeQuestion(overrides: Record<string, unknown> = {}) {
  return {
    id: "q001",
    text_en: "Never have I ever eaten pizza for breakfast",
    text_de: "Ich hab noch nie Pizza zum Frühstück gegessen",
    text_es: "Yo nunca nunca he comido pizza en el desayuno",
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
    const q = makeQuestion({ text_es: "Nunca he comido pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES1")).toBe(true);
  });

  it("ES2: detects trailing period", () => {
    const q = makeQuestion({ text_es: "Yo nunca nunca he comido pizza." });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES2")).toBe(true);
  });

  it("ES5: detects incorrect verb form", () => {
    const q = makeQuestion({ text_es: "Yo nunca nunca comí pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES5")).toBe(true);
  });

  it("ES5: accepts 'he' verb form", () => {
    const q = makeQuestion({ text_es: "Yo nunca nunca he comido pizza" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES5")).toBe(false);
  });

  it("ES5: accepts 'me he' reflexive form", () => {
    const q = makeQuestion({ text_es: "Yo nunca nunca me he despertado tarde" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES5")).toBe(false);
  });

  it("ES5: accepts 'me han' passive form", () => {
    const q = makeQuestion({ text_es: "Yo nunca nunca me han echado de un lugar" });
    const v = validateQuestion(q, 0);
    expect(v.some((e) => e.rule === "ES5")).toBe(false);
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
      makeQuestion({ id: "q001", text_en: "Never have I ever eaten pizza", text_de: "Ich hab noch nie Pizza gegessen", text_es: "Yo nunca nunca he comido pizza" }),
      makeQuestion({ id: "q002", text_en: "Never have I ever eaten pasta", text_de: "Ich hab noch nie Pasta gegessen", text_es: "Yo nunca nunca he comido pasta" }),
    ];
    const v = validateDuplicates(questions);
    expect(v).toEqual([]);
  });
});
