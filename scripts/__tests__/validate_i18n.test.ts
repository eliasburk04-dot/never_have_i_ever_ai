/**
 * __tests__/validate_i18n.test.ts
 *
 * Tests for the i18n validation pipeline.
 */

import { describe, it, expect, afterEach } from "vitest";
import { writeFileSync, mkdirSync, rmSync } from "fs";
import { resolve, dirname } from "path";
import { fileURLToPath } from "url";
import { validateArbFiles } from "../validate_i18n";

// ─── Fixtures ───────────────────────────────────────────────────────────────

const __filename = fileURLToPath(import.meta.url);
const __dirname2 = dirname(__filename);
const TMP_DIR = resolve(__dirname2, "__tmp_l10n__");

function setupArbFiles(
  en: Record<string, string>,
  de: Record<string, string>,
  es: Record<string, string>,
) {
  mkdirSync(TMP_DIR, { recursive: true });
  writeFileSync(resolve(TMP_DIR, "app_en.arb"), JSON.stringify(en, null, 2));
  writeFileSync(resolve(TMP_DIR, "app_de.arb"), JSON.stringify(de, null, 2));
  writeFileSync(resolve(TMP_DIR, "app_es.arb"), JSON.stringify(es, null, 2));
}

function cleanup() {
  try {
    rmSync(TMP_DIR, { recursive: true, force: true });
  } catch {
    // ignore
  }
}

// ─── Tests ──────────────────────────────────────────────────────────────────

describe("i18n Validation", () => {
  afterEach(cleanup);

  it("ARB1: detects missing key in DE", () => {
    setupArbFiles(
      { "@@locale": "en", "appTitle": "Title", "hello": "Hello" },
      { "@@locale": "de", "appTitle": "Titel" },
      { "@@locale": "es", "appTitle": "Título", "hello": "Hola" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB1" && e.key === "hello" && e.file === "app_de.arb")).toBe(true);
  });

  it("ARB1: detects missing key in ES", () => {
    setupArbFiles(
      { "@@locale": "en", "appTitle": "Title", "hello": "Hello" },
      { "@@locale": "de", "appTitle": "Titel", "hello": "Hallo" },
      { "@@locale": "es", "appTitle": "Título" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB1" && e.key === "hello" && e.file === "app_es.arb")).toBe(true);
  });

  it("ARB2: detects extra key in DE not present in EN", () => {
    setupArbFiles(
      { "@@locale": "en", "appTitle": "Title" },
      { "@@locale": "de", "appTitle": "Titel", "extraKey": "Extra" },
      { "@@locale": "es", "appTitle": "Título" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB2" && e.key === "extraKey")).toBe(true);
  });

  it("ARB3: detects placeholder mismatch", () => {
    setupArbFiles(
      { "@@locale": "en", "greeting": "Hello {name}" },
      { "@@locale": "de", "greeting": "Hallo {user}" },
      { "@@locale": "es", "greeting": "Hola {name}" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB3" && e.file === "app_de.arb")).toBe(true);
  });

  it("ARB3: passes when placeholders match", () => {
    setupArbFiles(
      { "@@locale": "en", "greeting": "Hello {name}" },
      { "@@locale": "de", "greeting": "Hallo {name}" },
      { "@@locale": "es", "greeting": "Hola {name}" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB3")).toBe(false);
  });

  it("ARB4: detects German transliteration in DE values", () => {
    setupArbFiles(
      { "@@locale": "en", "test": "Test" },
      { "@@locale": "de", "test": "Ueberprüfung" },
      { "@@locale": "es", "test": "Prueba" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB4")).toBe(true);
  });

  it("ARB7: detects wrong locale", () => {
    setupArbFiles(
      { "@@locale": "en", "title": "T" },
      { "@@locale": "en", "title": "T" }, // Wrong! Should be "de"
      { "@@locale": "es", "title": "T" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v.some((e) => e.rule === "ARB7" && e.file === "app_de.arb")).toBe(true);
  });

  it("passes all checks on valid files", () => {
    setupArbFiles(
      { "@@locale": "en", "appTitle": "Title" },
      { "@@locale": "de", "appTitle": "Titel" },
      { "@@locale": "es", "appTitle": "Título" },
    );
    const v = validateArbFiles(TMP_DIR);
    expect(v).toEqual([]);
  });
});
