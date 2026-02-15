/**
 * __tests__/fix_de_transliteration.test.ts
 *
 * Tests for the German transliteration auto-fix pipeline.
 */

import { describe, it, expect } from "vitest";
import { fixGermanTransliterations } from "../fix_de_transliteration";

describe("fixGermanTransliterations", () => {
  it("replaces ae with ä", () => {
    const { fixed, replacements } = fixGermanTransliterations("spaeter");
    expect(fixed).toBe("später");
    expect(replacements.length).toBeGreaterThan(0);
  });

  it("replaces oe with ö", () => {
    const { fixed } = fixGermanTransliterations("hoeren");
    expect(fixed).toBe("hören");
  });

  it("replaces ue with ü", () => {
    const { fixed } = fixGermanTransliterations("fuehlen");
    expect(fixed).toBe("fühlen");
  });

  it("preserves Abenteuer (compound exception)", () => {
    const { fixed, replacements } = fixGermanTransliterations("Ein großes Abenteuer");
    expect(fixed).toBe("Ein großes Abenteuer");
    expect(replacements).toEqual([]);
  });

  it("preserves Bauer (compound exception)", () => {
    const { fixed, replacements } = fixGermanTransliterations("Der Bauer auf dem Feld");
    expect(fixed).toBe("Der Bauer auf dem Feld");
    expect(replacements).toEqual([]);
  });

  it("preserves Feuer (compound exception)", () => {
    const { fixed, replacements } = fixGermanTransliterations("Das Feuer ist heiß");
    expect(fixed).toBe("Das Feuer ist heiß");
    expect(replacements).toEqual([]);
  });

  it("preserves Steuer (compound exception)", () => {
    const { fixed, replacements } = fixGermanTransliterations("Die Steuer zahlen");
    expect(fixed).toBe("Die Steuer zahlen");
    expect(replacements).toEqual([]);
  });

  it("preserves Trauer (compound exception)", () => {
    const { fixed, replacements } = fixGermanTransliterations("In tiefer Trauer");
    expect(fixed).toBe("In tiefer Trauer");
    expect(replacements).toEqual([]);
  });

  it("handles mixed exceptions and transliterations", () => {
    const { fixed } = fixGermanTransliterations("Der Bauer fuehlt sich mue de");
    // "Bauer" preserved, "fuehlt" → "fühlt", "mue" → "mü"
    expect(fixed).toContain("Bauer");
    expect(fixed).toContain("fühlt");
  });

  it("handles multiple replacements in one string", () => {
    const { fixed, replacements } = fixGermanTransliterations("Ich hab noch nie spaeter als ueblich gehoert");
    expect(fixed).toBe("Ich hab noch nie später als üblich gehört");
    expect(replacements.length).toBe(3);
  });

  it("returns unchanged text when no transliterations", () => {
    const input = "Ich hab noch nie Pizza zum Frühstück gegessen";
    const { fixed, replacements } = fixGermanTransliterations(input);
    expect(fixed).toBe(input);
    expect(replacements).toEqual([]);
  });

  it("preserves case for uppercase transliterations", () => {
    const { fixed } = fixGermanTransliterations("Ueberprüfung");
    expect(fixed).toBe("Überprüfung");
  });
});
