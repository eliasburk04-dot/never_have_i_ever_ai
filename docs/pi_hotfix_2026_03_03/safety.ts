const BLOCKED_PATTERNS: RegExp[] = [
  /\b(sex|intercourse|orgasm|naked|nude|genitals?|penis|vagina)\b/i,
  /\b(child|children|kid|minor|underage)\b/i,
  /\b(kill|murder|suicide|self.?harm|assault|rape|abuse)\b/i,
  /\b(cocaine|heroin|meth|trafficking|molest)\b/i,
  /\b(without.?consent|force[ds]?.?(to|into)|against.?will)\b/i,
  /\b(drink|drinking|alcohol|beer|vodka|tequila|whiskey|rum|cocktail|shot|hangover)\b/i,
  /\b(trinkspiel|trinken|alkohol|bier|wodka|tequila|whisky|kater)\b/i,
  /\b(beber|alcohol|cerveza|vodka|tequila|whisky|ron|trago|resaca|borracho)\b/i,
];

const NSFW_DISABLED_PATTERNS: RegExp[] = [
  /\b(hookup|hook.?up|one.?night|skinny.?dip|strip)\b/i,
];

export function passesSafetyFilter(text: string, nsfwEnabled: boolean): boolean {
  for (const pattern of BLOCKED_PATTERNS) {
    if (pattern.test(text)) return false;
  }
  if (!nsfwEnabled) {
    for (const pattern of NSFW_DISABLED_PATTERNS) {
      if (pattern.test(text)) return false;
    }
  }
  if (text.length > 200) return false;
  return true;
}
