# Question Engine & AI Orchestration Redesign

> **Constraint**: Escalation math (EMA boldness, progression modifier, tone thresholds, de-escalation rule) remains **100% unchanged**.
> This document redesigns everything that feeds INTO and comes OUT OF those formulas.

---

## PART 1 — CONTENT ARCHITECTURE REDESIGN

### 1.1 Current Taxonomy (Problems)

```
Current: 50 questions
Tags:    category (6 values), intensity (1-10), is_nsfw, is_premium
```

**Why it fails:**
- Only 6 categories → AI keeps generating within the same topic space
- No subcategory granularity → "relationships" covers crushing AND cheating AND betrayal
- No metadata about emotional weight → a "funny embarrassing" and a "soul-crushing confession" can both be intensity 7
- No shock/vulnerability axis → every question at the same intensity feels similar
- 35 free / 15 NSFW is too thin for sessions >15 rounds

### 1.2 New Taxonomy Schema

Every question (pool + AI-generated) is tagged with:

```json
{
  "id": "q001",
  "text_en": "...",
  "text_de": "...",
  "text_es": "...",
  "intensity": 6,
  "category": "relationships",
  "subcategory": "cheating",
  "shock_factor": 0.7,
  "vulnerability_level": 0.5,
  "is_nsfw": false,
  "is_premium": false,
  "energy": "heavy",
  "target_group_size": "any"
}
```

#### New Fields Explained

| Field | Type | Purpose |
|-------|------|---------|
| `subcategory` | string | Fine-grained topic within category. Enables rotation enforcement. |
| `shock_factor` | float 0–1 | How surprising/provocative the question is at face value. A high-intensity question can have LOW shock (expected confession) or HIGH shock (unexpected twist). |
| `vulnerability_level` | float 0–1 | How emotionally exposed the answerer becomes. Prevents back-to-back vulnerable rounds which cause group fatigue. |
| `energy` | enum | `light` / `medium` / `heavy` — pacing metadata. Enables rhythm control. |
| `target_group_size` | enum | `any` / `small` (2-4) / `large` (5+) — some questions work better in certain group sizes. |

#### How These Improve Diversity

1. **`subcategory`** → Category cooldown operates at subcategory level. "relationships/cheating" and "relationships/crushing" are different cooldown slots.
2. **`shock_factor`** → Prevents the "every question feels the same intensity" problem. Within intensity 6, you get a mix of 0.3-shock (mild) and 0.8-shock (gasp).
3. **`vulnerability_level`** → After a high-vulnerability question, the engine selects a lower-vulnerability one. Prevents emotional exhaustion.
4. **`energy`** → Creates rhythm. Pattern: medium → light → heavy → light → medium. Prevents monotone pacing.

### 1.3 Expanded Category System

**14 categories, 42+ subcategories:**

| Category | Subcategories | NSFW? | Intensity Range |
|----------|--------------|-------|-----------------|
| **social** | awkward, faux-pas, white-lies, people-pleasing | No | 1–4 |
| **embarrassing** | public, private, online, body | No | 1–5 |
| **food** | habits, gross, cultural | No | 1–3 |
| **relationships** | crushing, dating, heartbreak, cheating, toxic | No | 3–7 |
| **secrets** | mild, deep, dark | No | 4–8 |
| **moral_gray** | dishonesty, hypocrisy, manipulation | No | 4–7 |
| **alcohol** | first-time, blackout, regret, peer-pressure | NSFW | 5–8 |
| **party** | wild-nights, dares, public-scenes, walk-of-shame | NSFW | 5–9 |
| **drugs** | experimentation, peer-pressure, regret | NSFW | 7–9 |
| **sexual** | first-times, casual, risky, fantasy | NSFW | 7–10 |
| **taboo** | forbidden-thoughts, societal, boundary-crossing | NSFW | 8–10 |
| **confessions** | guilt, shame, hidden-life | No+NSFW | 5–10 |
| **risk_behavior** | reckless, adrenaline, consequences | No | 4–8 |
| **power_dynamics** | authority, manipulation, status | NSFW | 6–9 |

---

## PART 2 — SESSION VARIATION ENGINE

### 2.1 Topic Rotation Enforcement

```
RULE: Do not repeat the same CATEGORY within the last N rounds.
RULE: Do not repeat the same SUBCATEGORY within the last M rounds.

N = max(3, floor(active_category_count / 2))
M = max(5, floor(active_subcategory_count / 3))

Where:
  active_category_count = categories available for current intensity range
  active_subcategory_count = subcategories available for current intensity range
```

**Implementation in `select()`:**

```
function selectWithRotation(candidates, recentRounds, N, M):
    recentCategories = recentRounds.takeLast(N).map(r => r.category)
    recentSubcategories = recentRounds.takeLast(M).map(r => r.subcategory)
    
    // Tier 1: Exclude recent categories AND subcategories
    tier1 = candidates.filter(q =>
        !recentCategories.contains(q.category) &&
        !recentSubcategories.contains(q.subcategory)
    )
    if tier1.nonEmpty: return weightedSelect(tier1)
    
    // Tier 2: Exclude only subcategories (allow category repeat)
    tier2 = candidates.filter(q =>
        !recentSubcategories.contains(q.subcategory)
    )
    if tier2.nonEmpty: return weightedSelect(tier2)
    
    // Tier 3: No rotation constraint (exhaustion fallback)
    return weightedSelect(candidates)
```

### 2.2 Start Seed Randomization

**Problem**: Every game starts with intensity 1, tone "safe" → always gets the same ~10 questions.

**Solution**: Generate a session seed that alters opening behavior WITHOUT changing escalation math.

```
function generateSessionSeed(lobbyId, timestamp):
    seed = hash(lobbyId + timestamp) % 1000
    return seed

function getOpeningVariation(seed):
    // Vary starting intensity within safe range (1–3)
    startIntensity = (seed % 3) + 1  // 1, 2, or 3
    
    // Vary opening category
    safeCategories = ['social', 'embarrassing', 'food', 'relationships', 'risk_behavior']
    startCategoryIndex = (seed / 3) % safeCategories.length
    preferredStartCategory = safeCategories[startCategoryIndex]
    
    // Vary energy pattern
    energyPatterns = [
        ['light', 'medium', 'light', 'medium', 'heavy'],  // Slow build
        ['medium', 'light', 'medium', 'heavy', 'light'],   // Alternating
        ['medium', 'medium', 'light', 'heavy', 'medium'],  // Plateau start
    ]
    patternIndex = (seed / 15) % energyPatterns.length
    openingEnergyPattern = energyPatterns[patternIndex]
    
    return { startIntensity, preferredStartCategory, openingEnergyPattern }
```

**Result**: With 3 intensities × 5 categories × 3 patterns = **45 distinct opening feels**.

### 2.3 Session Uniqueness Hash

```
function buildSessionContext(lobbyId, playerNames, timestamp):
    raw = lobbyId + playerNames.sort().join('') + timestamp.toString()
    sessionHash = sha256(raw)
    
    // Extract deterministic sub-seeds
    categorySeed = parseInt(sessionHash.substring(0, 8), 16)
    energySeed = parseInt(sessionHash.substring(8, 16), 16)
    variationSeed = parseInt(sessionHash.substring(16, 24), 16)
    
    return { categorySeed, energySeed, variationSeed }
```

This seed shifts the probability distribution of categories so different groups naturally gravitate toward different topic mixes — even with the same escalation curve.

### 2.4 Weighted Randomness (Anti-Uniformity)

Instead of flat random selection, use **inverse frequency weighting**:

```
function weightedSelect(candidates, categoryUsageCounts):
    totalUsage = sum(categoryUsageCounts.values)
    
    for each candidate q in candidates:
        usageCount = categoryUsageCounts[q.category] or 0
        
        // Base weight: inverse of usage frequency
        baseWeight = 1.0 / (usageCount + 1)
        
        // Shock variety: prefer shock_factor that differs from recent
        recentAvgShock = average(recentRounds.takeLast(3).map(r => r.shock_factor))
        shockDelta = abs(q.shock_factor - recentAvgShock)
        shockBonus = shockDelta * 0.5
        
        // Vulnerability oscillation: after high vulnerability, prefer low
        lastVulnerability = recentRounds.last?.vulnerability_level ?? 0.5
        vulnTarget = 1.0 - lastVulnerability  // Oscillate
        vulnDelta = 1.0 - abs(q.vulnerability_level - vulnTarget)
        vulnBonus = vulnDelta * 0.3
        
        // Energy pattern matching
        expectedEnergy = getExpectedEnergy(currentRound, openingEnergyPattern)
        energyBonus = (q.energy == expectedEnergy) ? 0.4 : 0.0
        
        q.selectionWeight = baseWeight + shockBonus + vulnBonus + energyBonus
    
    // Weighted random selection
    return weightedRandom(candidates, weight: q => q.selectionWeight)
```

### 2.5 AI Semantic Avoidance Rule

```
AI_AVOIDANCE_WINDOW = 5

function buildAvoidanceContext(recentRounds):
    topics = recentRounds.takeLast(AI_AVOIDANCE_WINDOW).map(r => {
        'question': r.questionText,
        'category': r.category,
        'subcategory': r.subcategory,
        'keywords': extractKeywords(r.questionText)
    })
    
    return "AVOIDANCE LIST (do NOT generate questions about these topics):\n" +
           topics.map(t => "- ${t.subcategory}: '${t.question}'").join('\n')
```

Passed directly to AI in the user prompt (see Part 4).

---

## PART 3 — REAL 18+ DEPTH (APP STORE SAFE)

### 3.1 Adult Content Design Principles

**App Store compliance boundary:**
- ✅ Imply, reference, acknowledge that adults do adult things
- ✅ Use colloquial/slang phrasing
- ✅ Reference specific scenarios without graphic detail
- ❌ No explicit sexual descriptions
- ❌ No minors in any sexual/drug context
- ❌ No illegal activity encouragement
- ❌ No graphic violence

**Tone guideline**: Write like friends at a party would actually talk — direct, slightly crude, but never pornographic.

### 3.2 Tiered Adult Escalation Structure

#### Intensity 7 — Light Sexual / Adult Implication

*Subcategory: first encounters, mild embarrassment, alcohol-related*

| # | EN | DE |
|---|----|----|
| 1 | Never have I ever woken up next to someone and not remembered their name | Ich hab noch nie neben jemandem aufgewacht und den Namen vergessen |
| 2 | Never have I ever lied about my body count | Ich hab noch nie bei der Anzahl meiner Sexpartner gelogen |
| 3 | Never have I ever had a crush on a teacher | Ich hab noch nie einen Crush auf einen Lehrer gehabt |
| 4 | Never have I ever skinny dipped | Ich hab noch nie nackt gebadet |
| 5 | Never have I ever been caught watching something I shouldn't | Ich hab noch nie dabei erwischt worden wie ich was Verbotenes geschaut hab |
| 6 | Never have I ever drunk-texted an ex | Ich hab noch nie betrunken meinem Ex geschrieben |
| 7 | Never have I ever pretended to be more experienced than I am | Ich hab noch nie so getan als hätte ich mehr Erfahrung als ich hab |
| 8 | Never have I ever kissed someone just to make someone else jealous | Ich hab noch nie jemanden geküsst nur um jemand anderen eifersüchtig zu machen |
| 9 | Never have I ever had a one night stand and snuck out in the morning | Ich hab noch nie nach einem One-Night-Stand morgens heimlich abgehauen |
| 10 | Never have I ever faked being drunk to avoid something | Ich hab noch nie so getan als wäre ich betrunken um was zu vermeiden |

#### Intensity 8 — Direct Adult Scenario

*Subcategory: hookups, party regret, substances, embarrassing sexual situations*

| # | EN | DE |
|---|----|----|
| 1 | Never have I ever hooked up with two people in the same week | Ich hab noch nie mit zwei verschiedenen Leuten in derselben Woche rumgemacht |
| 2 | Never have I ever been walked in on during something intimate | Ich hab noch nie dabei erwischt worden als ich intim war |
| 3 | Never have I ever done something sexual in a public place | Ich hab noch nie was Sexuelles an einem öffentlichen Ort gemacht |
| 4 | Never have I ever woken up somewhere with no idea how I got there | Ich hab noch nie irgendwo aufgewacht ohne zu wissen wie ich dahingekommen bin |
| 5 | Never have I ever tried a drug harder than weed | Ich hab noch nie eine härtere Droge als Gras probiert |
| 6 | Never have I ever sent or received explicit photos | Ich hab noch nie explizite Fotos geschickt oder bekommen |
| 7 | Never have I ever been so drunk I threw up on someone | Ich hab noch nie jemanden vollgekotzt weil ich so betrunken war |
| 8 | Never have I ever hooked up with a friend's ex | Ich hab noch nie was mit dem Ex eines Freundes gehabt |
| 9 | Never have I ever had a walk of shame in broad daylight | Ich hab noch nie den Walk of Shame bei Tageslicht gemacht |
| 10 | Never have I ever blacked out and had someone tell me what I did | Ich hab noch nie einen Filmriss gehabt und mir danach erzählen lassen müssen was ich getan hab |

#### Intensity 9 — Vulnerable Confession Tone

*Subcategory: deep sexual, substance dependency, dark secrets, moral failure*

| # | EN | DE |
|---|----|----|
| 1 | Never have I ever cheated on someone I actually loved | Ich hab noch nie jemanden betrogen den ich wirklich geliebt hab |
| 2 | Never have I ever slept with someone for a favor or advantage | Ich hab noch nie mit jemandem geschlafen um einen Vorteil zu bekommen |
| 3 | Never have I ever used someone knowing I'd break their heart | Ich hab noch nie jemanden ausgenutzt obwohl ich wusste dass ich sein Herz brechen würde |
| 4 | Never have I ever had a substance problem I hid from everyone | Ich hab noch nie ein Suchtproblem vor allen versteckt |
| 5 | Never have I ever fantasized about a friend's partner while they were in the room | Ich hab noch nie Fantasien über den Partner eines Freundes gehabt während der im Raum war |
| 6 | Never have I ever kept sleeping with someone I had zero feelings for | Ich hab noch nie weiter mit jemandem geschlafen für den ich null Gefühle hatte |
| 7 | Never have I ever done something in bed I was too ashamed to ever tell anyone | Ich hab noch nie was im Bett gemacht wofür ich mich zu sehr geschämt hab um es jemandem zu erzählen |
| 8 | Never have I ever manipulated someone into a relationship | Ich hab noch nie jemanden in eine Beziehung manipuliert |
| 9 | Never have I ever woken up regretting who I went home with | Ich hab noch nie morgens bereut mit wem ich nach Hause gegangen bin |
| 10 | Never have I ever crossed my own moral line and pretended it didn't happen | Ich hab noch nie meine eigene moralische Grenze überschritten und so getan als wäre nichts passiert |

#### Intensity 10 — Taboo Thought-Provoking (Non-Graphic)

*Subcategory: forbidden desires, double life, deep shame, boundary violations*

| # | EN | DE |
|---|----|----|
| 1 | Never have I ever had a fantasy I'd literally take to my grave | Ich hab noch nie eine Fantasie gehabt die ich mit ins Grab nehmen würde |
| 2 | Never have I ever wanted someone I absolutely should not want | Ich hab noch nie jemanden gewollt den ich absolut nicht wollen sollte |
| 3 | Never have I ever done something that would make everyone here see me differently | Ich hab noch nie was getan das alle hier dazu bringen würde mich anders zu sehen |
| 4 | Never have I ever led a part of my life that nobody in this room knows about | Ich hab noch nie einen Teil meines Lebens geführt von dem niemand hier weiß |
| 5 | Never have I ever enjoyed something I'm supposed to feel guilty about | Ich hab noch nie etwas genossen wofür ich mich eigentlich schuldig fühlen sollte |
| 6 | Never have I ever thought about doing something truly unforgivable | Ich hab noch nie darüber nachgedacht etwas wirklich Unverzeihliches zu tun |
| 7 | Never have I ever kept a sexual secret that would destroy a relationship if it came out | Ich hab noch nie ein sexuelles Geheimnis gehabt das eine Beziehung zerstören würde wenn es rauskäme |
| 8 | Never have I ever felt attracted to someone while I was with their best friend | Ich hab noch nie Anziehung gespürt für jemanden während ich mit dessen bestem Freund zusammen war |
| 9 | Never have I ever broken someone and never apologized | Ich hab noch nie jemanden kaputt gemacht und mich nie entschuldigt |
| 10 | Never have I ever questioned my own identity in a way I've never told anyone | Ich hab noch nie meine eigene Identität in Frage gestellt auf eine Art die ich nie jemandem erzählt hab |

---

## PART 4 — AI GENERATION RULESET

### 4.1 Redesigned System Prompt

```
You are the question engine for "Never Have I Ever", a party game with adaptive escalation.

CORE RULES:
1. Respond ONLY with valid JSON. No other text.
2. You select the best question from the candidate pool, rephrase it to fit the group, or generate a new one.
3. STRICTLY respect the tone_level and intensity_range.
4. If NSFW is disabled: NO sexual content, NO drugs, NO alcohol abuse. Keep it clean.
5. Even with NSFW enabled: NO minors, NO explicit pornographic descriptions, NO illegal activity encouragement, NO violence/self-harm, NO hate speech.
6. Questions MUST start with the correct language prefix.
7. Keep questions under 120 characters.
8. Be culturally aware.

LANGUAGE PREFIXES:
- English: "Never have I ever"
- German: "Ich hab noch nie"
- Spanish: "Yo nunca nunca"

QUESTION QUALITY RULES:
- Questions must be SPECIFIC, not vague. Bad: "done something wild." Good: "snuck out at 3am to meet someone I barely knew."
- Questions should provoke interesting GROUP SPLITS (not unanimous yes/no).
- Avoid generic phrasing like "done something bad" or "had a secret."
- Each question should paint a SCENE or MOMENT, not a general concept.
- Vary sentence structure. Don't always use the same pattern.

ADULT CONTENT TIERS (when NSFW enabled):
- Intensity 7: Implication, innuendo, mild adult references
- Intensity 8: Direct adult scenarios (hookups, substances, explicit-ish situations)
- Intensity 9: Vulnerable confessions, moral failures, relationship damage
- Intensity 10: Taboo thoughts, deep shame, identity-level secrets

RESPONSE FORMAT:
{
    "selected_question_id": "id-or-null",
    "question_text": "Never have I ever ...",
    "was_modified": true/false,
    "was_generated": true/false,
    "category": "one of the 14 categories",
    "subcategory": "specific subcategory",
    "shock_factor": 0.0-1.0,
    "vulnerability_level": 0.0-1.0,
    "reasoning": "brief explanation"
}
```

### 4.2 Redesigned User Prompt Template

```
GAME STATE:
- Language: {language}
- Round: {current_round} / {max_rounds}
- Players: {player_count}
- NSFW Mode: {nsfw_enabled}
- Current Tone: {current_tone}
- Boldness Score: {boldness_score}
- Target Intensity Range: {min_intensity} - {max_intensity}
- Session Energy Target: {expected_energy}

RECENT HISTORY (avoid repeating these topics):
{recent_history_with_categories}

TOPIC AVOIDANCE LIST (do NOT ask about these themes):
{avoidance_list}

CATEGORY USAGE COUNTS THIS SESSION:
{category_usage_map}
→ Prefer UNDERUSED categories.

LAST QUESTION'S ATTRIBUTES:
- Shock Factor: {last_shock}
- Vulnerability Level: {last_vulnerability}
→ Generate a question with DIFFERENT shock/vulnerability balance.

CANDIDATE QUESTIONS FROM POOL:
{candidates_json}

INSTRUCTIONS:
{instruction_variant}

Respond ONLY with the JSON object.
```

### 4.3 Similarity Avoidance Logic

```
function buildAvoidanceList(session):
    window = min(5, session.rounds.length)
    recent = session.rounds.takeLast(window)
    
    avoidanceEntries = recent.map(round => {
        keywords = extractKeyTheme(round.questionText)
        return "- Round ${round.roundNumber} [${round.subcategory}]: '${round.questionText}' → AVOID themes: ${keywords}"
    })
    
    return avoidanceEntries.join('\n')

function extractKeyTheme(questionText):
    // Strip prefix
    text = questionText.replaceFirst(prefixPattern, '')
    // Extract 2-3 key nouns/concepts
    // Simple heuristic: longest 2-3 non-stopwords
    words = text.split(' ').filter(w => w.length > 4 && !isStopword(w))
    return words.take(3).join(', ')
```

### 4.4 Fallback Rules if AI Repeats Theme

```
function validateAiResponse(response, recentRounds):
    // Check 1: Not same subcategory as last 3 rounds
    recentSubs = recentRounds.takeLast(3).map(r => r.subcategory)
    if response.subcategory in recentSubs:
        return RETRY_WITH_STRICTER_PROMPT
    
    // Check 2: Keyword overlap check
    recentTexts = recentRounds.takeLast(5).map(r => r.questionText.toLowerCase())
    responseWords = response.question_text.toLowerCase().split(' ').toSet()
    for each recentText in recentTexts:
        recentWords = recentText.split(' ').toSet()
        overlap = responseWords.intersection(recentWords)
        overlapRatio = overlap.length / responseWords.length
        if overlapRatio > 0.5:  // More than 50% word overlap
            return RETRY_WITH_STRICTER_PROMPT
    
    // Check 3: If retry also fails → fall back to pool
    return ACCEPT

// Retry prompt addendum:
"CRITICAL: Your previous suggestion was too similar to recent questions.
 Generate something from a COMPLETELY DIFFERENT topic domain.
 Must use category: {random_underused_category}"
```

---

## PART 5 — HYBRID BALANCE STRATEGY

### 5.1 Distribution Formula

```
function getAiProbability(currentRound, maxRounds, poolCandidateCount):
    // Base progression: early=pool-heavy, late=AI-heavy
    progressRatio = currentRound / maxRounds
    
    // Sigmoid curve: slow start, rapid mid-game shift, plateau
    baseProbability = 1 / (1 + exp(-8 * (progressRatio - 0.45)))
    // Round 1:  ~2% AI
    // Round 25%: ~15% AI
    // Round 50%: ~50% AI  
    // Round 75%: ~85% AI
    // Round 100%: ~97% AI
    
    // Scale to 60/40 target: multiply by 0.65 so max AI is ~63%
    scaledProbability = baseProbability * 0.65
    
    // Pool exhaustion boost: if few candidates, increase AI
    if poolCandidateCount < 3:
        scaledProbability = max(scaledProbability, 0.85)
    elif poolCandidateCount < 5:
        scaledProbability = max(scaledProbability, 0.60)
    
    // Minimum pool usage: first 3 rounds always pool
    if currentRound <= 3:
        scaledProbability = 0.0
    
    return clamp(scaledProbability, 0.0, 0.90)

function shouldUseAi(currentRound, maxRounds, poolCandidateCount, sessionSeed):
    probability = getAiProbability(currentRound, maxRounds, poolCandidateCount)
    roll = seededRandom(sessionSeed + currentRound) // deterministic per round
    return roll < probability
```

### 5.2 Distribution Examples

**10-round game (short):**
| Round | AI Prob | Likely Source |
|-------|---------|---------------|
| 1–3 | 0% | Pool |
| 4–5 | ~12% | Pool (mostly) |
| 6–7 | ~30% | Mixed |
| 8–10 | ~45% | Mixed |
→ ~70% pool, ~30% AI

**20-round game (standard):**
| Round | AI Prob | Likely Source |
|-------|---------|---------------|
| 1–3 | 0% | Pool |
| 4–7 | ~10-20% | Pool-heavy |
| 8–12 | ~30-45% | Mixed |
| 13–17 | ~50-60% | AI-heavy |
| 18–20 | ~60% | AI-heavy |
→ ~58% pool, ~42% AI

**50-round game (long):**
| Round | AI Prob | Likely Source |
|-------|---------|---------------|
| 1–3 | 0% | Pool |
| 4–15 | ~5-25% | Pool-heavy |
| 16–35 | ~30-55% | Mixed (pool exhausting) |
| 36–50 | ~60-85% | AI-dominant (pool exhausted) |
→ ~45% pool, ~55% AI

---

## PART 6 — LONG SESSION ANTI-REPETITION STRATEGY

### 6.1 Category Cooldown System

```
CATEGORY_COOLDOWN = {
    'small_pool': 2,    // categories with <5 questions
    'medium_pool': 3,   // categories with 5-10 questions
    'large_pool': 4,    // categories with >10 questions
}

SUBCATEGORY_COOLDOWN = CATEGORY_COOLDOWN + 2

function isCategoryOnCooldown(category, recentRounds):
    poolSize = countQuestionsInCategory(category)
    cooldown = CATEGORY_COOLDOWN[sizeClass(poolSize)]
    recentCategories = recentRounds.takeLast(cooldown).map(r => r.category)
    return category in recentCategories
```

### 6.2 Intensity Cycling (for 50+ round sessions)

Prevent monotone escalation in long games. After reaching peak intensity, insert "breather" cycles:

```
function shouldInsertBreather(session):
    if session.rounds.length < 15: return false
    
    // Check: have we been at high intensity for 5+ consecutive rounds?
    recentIntensities = session.rounds.takeLast(5).map(r => r.intensity)
    avgRecent = average(recentIntensities)
    
    if avgRecent > 7.0:
        // Insert a breather: temporarily lower intensity by 2-3
        return true
    
    return false

function getBreatherIntensityAdjustment():
    return -2  // Applied to intensity range for one round
    // e.g., if range is 7-10, breather makes it 5-8
```

**This does NOT change escalation math.** The boldness/tone still follow EMA. The breather only affects the intensity range passed to `select()` and AI, creating a momentary "catch your breath" round.

### 6.3 Soft-Reset Moments

At specific intervals in long games, insert "palette cleanser" rounds:

```
SOFT_RESET_INTERVAL = 15  // Every 15 rounds

function shouldSoftReset(currentRound):
    return currentRound > 10 && currentRound % SOFT_RESET_INTERVAL == 0

function getSoftResetConfig():
    return {
        'force_energy': 'light',
        'force_low_vulnerability': true,  // vulnerability_level < 0.3
        'prefer_category': randomFrom(['social', 'embarrassing', 'food']),
        'intensity_override': max(currentIntensityMin - 3, 1)
    }
```

**Purpose:** After 15 rounds of escalation, one round that's lighter and funny. Creates a laugh moment, group relief, and makes the NEXT escalation hit harder by contrast.

### 6.4 100-Round Session Architecture

```
Rounds 1–3:     SEED PHASE     (pool only, varied start)
Rounds 4–10:    WARM-UP        (mostly pool, category exploration)
Rounds 11–20:   ACCELERATION   (mixed pool/AI, escalation kicks in)
Rounds 21–35:   PEAK ZONE      (heavy AI, deep questions)
Rounds 36–50:   SUSTAIN        (AI-dominant, breathers every 15 rounds)
Rounds 51–70:   SECOND WIND    (soft-reset at 60, re-explore categories)
Rounds 71–85:   DEEP DIVE      (highest vulnerability, confession territory)
Rounds 86–100:  FINALE         (callback to earlier themes, closure questions)
```

---

## PART 7 — IMPLEMENTATION SUMMARY

### 7.1 Revised Content Architecture

- **50 → 200 pool questions** (expanded JSON)
- **6 → 14 categories**, **0 → 42+ subcategories**
- **3 new metadata fields**: `shock_factor`, `vulnerability_level`, `energy`
- Each question fully trilingual (EN/DE/ES)

### 7.2 Anti-Repetition System

| Mechanism | Scope | Effect |
|-----------|-------|--------|
| Category cooldown | Last N rounds | Prevents same topic cluster |
| Subcategory cooldown | Last M rounds | Prevents same exact theme |
| Session seed | Per session | 45 distinct opening feels |
| Weighted random | Per selection | Underused categories boosted |
| Shock oscillation | Round-to-round | Alternates surprise level |
| Vulnerability oscillation | Round-to-round | Prevents emotional fatigue |
| Energy pacing | Pattern-based | Creates rhythm (light/heavy) |
| AI avoidance window | Last 5 rounds | Semantic de-duplication |

### 7.3 Adult-Tier Escalation Model

| Intensity | Tier Name | Content Style |
|-----------|-----------|---------------|
| 7 | Light Adult | Implication, innuendo, "morning after" references |
| 8 | Direct Adult | Hookups, substances, explicit situations stated directly |
| 9 | Vulnerable Confession | Cheating, using people, hidden addictions, shame |
| 10 | Taboo Provocation | Forbidden desires, double lives, identity secrets |

### 7.4 AI Generation Rules

- Strict prompt with topic avoidance list
- Category/subcategory returned in AI response → enables rotation tracking
- Shock + vulnerability returned → enables oscillation
- Max 1 retry on theme repeat → then pool fallback
- Safety filter unchanged

### 7.5 Hybrid Distribution

- Sigmoid-based probability curve
- First 3 rounds: always pool
- Mid-game: ~50/50
- Late-game: AI-dominant
- Pool exhaustion auto-compensated
- Target overall: ~60% pool / ~40% AI

### 7.6 New Question Examples (30 samples across tiers)

**Safe (1–3):**
1. "Never have I ever pretended to text to avoid talking to someone"
2. "Never have I ever eaten an entire pizza by myself in one sitting"
3. "Never have I ever accidentally liked a year-old Instagram post while stalking"
4. "Never have I ever ugly cried in a public bathroom"
5. "Never have I ever used a pickup line unironically"

**Deeper (3–5):**
6. "Never have I ever stayed in a friendship I knew was toxic"
7. "Never have I ever changed my entire personality around a crush"
8. "Never have I ever read my partner's messages when they weren't looking"
9. "Never have I ever lied about why a relationship ended"
10. "Never have I ever secretly hated a gift so much I returned it the next day"

**Secretive (5–7):**
11. "Never have I ever told someone's secret to feel closer to someone else"
12. "Never have I ever kept in touch with an ex behind my partner's back"
13. "Never have I ever pretended not to see someone I know to avoid saying hi"
14. "Never have I ever sabotaged someone's chance without them knowing"
15. "Never have I ever stolen something from a store and gotten away with it"

**Freaky 7 (light NSFW):**
16. "Never have I ever had a friend with benefits situation that got complicated"
17. "Never have I ever pretended to enjoy a kiss that was absolutely terrible"
18. "Never have I ever gone home with a stranger I met that same night"
19. "Never have I ever lied about where I slept last night"
20. "Never have I ever had someone's partner flirt with me and I didn't stop it"

**Freaky 8 (direct NSFW):**
21. "Never have I ever been the other person in someone's relationship"
22. "Never have I ever done something in a car that I shouldn't have"
23. "Never have I ever had a hookup so bad I pretended to fall asleep"
24. "Never have I ever drunk-dialed someone and instantly regretted it when they answered"
25. "Never have I ever blacked out and woken up with unexplainable bruises"

**Freaky 9 (confessional):**
26. "Never have I ever kept sleeping with someone because I was afraid of being alone"
27. "Never have I ever destroyed evidence of something I did"
28. "Never have I ever emotionally manipulated someone to get what I wanted"
29. "Never have I ever felt nothing when I should have felt guilty"
30. "Never have I ever lived a lie for so long that it became my truth"

### 7.7 Why This Eliminates Repetition and Improves Engagement

| Problem | Root Cause | Solution |
|---------|-----------|----------|
| Same opening feel | Fixed intensity 1 start, same 10 questions | Session seed → 45 opening variations |
| Mid-game monotony | Same categories repeat | Category + subcategory cooldown + weighted random |
| AI feels similar | No avoidance context, vague prompts | 5-round avoidance window, specific prompts, shock/vulnerability oscillation |
| NSFW feels shallow | Only 15 NSFW questions, vague "nsfw_light/heavy" | 4-tier adult system (7/8/9/10) with real adult content across 6 NSFW categories |
| Long games die | 50 questions exhausted by round 30 | 200 pool questions + AI compensation + category cycling + breathers |
| Emotional flatline | No pacing metadata | Energy system (light/medium/heavy) + vulnerability oscillation + soft resets |
| "Heard this before" | No usage weighting | Inverse frequency weighting → underused categories surface |

**Net effect**: A 20-round game will feel meaningfully different every time it's played. A 50-round game will sustain engagement without repetition. NSFW mode will feel genuinely adult without crossing App Store lines.

---

## Implementation Priority

| Phase | Task | Effort |
|-------|------|--------|
| **P0** | Expand `questions.json` from 50 → 200 with new taxonomy | 3–4 hours |
| **P1** | Add `subcategory`, `shock_factor`, `vulnerability_level`, `energy` to `LocalQuestion` model | 30 min |
| **P1** | Implement category/subcategory cooldown in `LocalQuestionPool.select()` | 1 hour |
| **P1** | Implement session seed + opening variation in `OfflineGameCubit.startGame()` | 1 hour |
| **P2** | Redesign Groq system prompt + user prompt with avoidance list | 1 hour |
| **P2** | Add AI response validation (theme repeat check) | 30 min |
| **P2** | Implement hybrid distribution sigmoid | 30 min |
| **P3** | Add weighted random selection (shock/vulnerability/energy) | 1 hour |
| **P3** | Implement breather rounds + soft-reset for long sessions | 1 hour |
| **P4** | Update Edge Functions with same logic (for online mode) | 2 hours |

**Total: ~12 hours of implementation for a transformative upgrade.**
