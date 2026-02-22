#!/usr/bin/env npx tsx
/**
 * BATCH 3 — Final fill to 1600, includes dedup + gap-filling
 */

import * as fs from 'fs';
import * as path from 'path';

type Energy = 'light' | 'medium' | 'heavy';

interface QuestionDef {
  en: string;
  de: string;
  es: string;
  category: string;
  subcategory: string;
  intensity: number;
  is_nsfw: boolean;
}

function computeMetadata(q: QuestionDef) {
  const intensity = q.intensity;
  const is_nsfw = q.is_nsfw;
  let energy: Energy;
  if (intensity <= 3) energy = 'light';
  else if (intensity <= 6) energy = 'medium';
  else energy = 'heavy';
  const baseShock = (intensity - 1) / 9;
  const nsfwBoost = is_nsfw ? 0.1 : 0;
  const shock_factor = Math.round(Math.min(1, baseShock + nsfwBoost + (Math.random() * 0.08 - 0.04)) * 100) / 100;
  const vulnCategories = ['confessions', 'deep', 'relationships', 'moral_gray'];
  const vulnBoost = vulnCategories.includes(q.category) ? 0.1 : 0;
  const vulnerability_level = Math.round(Math.min(1, baseShock * 0.9 + vulnBoost + (Math.random() * 0.06 - 0.03)) * 100) / 100;
  const is_premium = intensity >= 7 || is_nsfw;
  return { energy, shock_factor, vulnerability_level, is_premium };
}

const BATCH3: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 4 — need 30 more (+ replace dupes from batch 2)
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever accidentally liked someone's post from years ago", de: "Ich hab noch nie versehentlich einen jahrelang alten Post geliked", es: "Nunca le he dado like a una publicación de hace años por accidente", category: "embarrassing", subcategory: "cringe", intensity: 4, is_nsfw: false },
{ en: "Never have I ever pretended to agree with a popular opinion I actually disagree with", de: "Ich hab noch nie so getan, als würde ich einer populären Meinung zustimmen, der ich eigentlich widerspreche", es: "Nunca he fingido estar de acuerdo con una opinión popular con la que en realidad no estoy de acuerdo", category: "confessions", subcategory: "dishonesty", intensity: 4, is_nsfw: false },
{ en: "Never have I ever had a crush on a teacher or professor", de: "Ich hatte noch nie einen Crush auf einen Lehrer oder Professor", es: "Nunca he tenido un crush con un profesor", category: "relationships", subcategory: "flirting", intensity: 4, is_nsfw: false },
{ en: "Never have I ever taken credit for someone else's work", de: "Ich hab mir noch nie die Arbeit von jemand anderem als meine eigene angerechnet", es: "Nunca me he atribuido el trabajo de alguien más", category: "moral_gray", subcategory: "manipulation", intensity: 4, is_nsfw: false },
{ en: "Never have I ever thought about what it would be like to disappear completely", de: "Ich hab noch nie darüber nachgedacht, wie es wäre, komplett zu verschwinden", es: "Nunca he pensado en cómo sería desaparecer completamente", category: "deep", subcategory: "mental_health", intensity: 4, is_nsfw: false },
{ en: "Never have I ever gotten into a physical altercation with a family member", de: "Ich hatte noch nie eine handgreifliche Auseinandersetzung mit einem Familienmitglied", es: "Nunca he tenido una pelea física con un familiar", category: "risk", subcategory: "reckless", intensity: 4, is_nsfw: false },
{ en: "Never have I ever copied someone's homework", de: "Ich hab noch nie jemandes Hausaufgaben abgeschrieben", es: "Nunca he copiado la tarea de alguien", category: "confessions", subcategory: "dishonesty", intensity: 4, is_nsfw: false },
{ en: "Never have I ever laughed during a serious moment", de: "Ich hab noch nie in einem ernsten Moment gelacht", es: "Nunca me he reído en un momento serio", category: "embarrassing", subcategory: "cringe", intensity: 4, is_nsfw: false },
{ en: "Never have I ever cried at the airport", de: "Ich hab noch nie am Flughafen geweint", es: "Nunca he llorado en el aeropuerto", category: "deep", subcategory: "vulnerability", intensity: 4, is_nsfw: false },
{ en: "Never have I ever looked through someone's phone without permission", de: "Ich hab noch nie ohne Erlaubnis in jemandes Handy geschaut", es: "Nunca he revisado el teléfono de alguien sin permiso", category: "confessions", subcategory: "secrets", intensity: 4, is_nsfw: false },
{ en: "Never have I ever lost my temper in public", de: "Ich hab noch nie in der Öffentlichkeit die Beherrschung verloren", es: "Nunca he perdido la paciencia en público", category: "embarrassing", subcategory: "public", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been scared to open a text message", de: "Ich hatte noch nie Angst davor, eine Textnachricht zu öffnen", es: "Nunca he tenido miedo de abrir un mensaje de texto", category: "social", subcategory: "awkward", intensity: 4, is_nsfw: false },
{ en: "Never have I ever liked someone way more than they liked me", de: "Ich hab noch nie jemanden viel mehr gemocht, als die Person mich", es: "Nunca me ha gustado alguien mucho más de lo que yo le gustaba", category: "relationships", subcategory: "dating", intensity: 4, is_nsfw: false },
{ en: "Never have I ever snuck out of the house as a teenager", de: "Ich bin noch nie als Teenager heimlich aus dem Haus geschlichen", es: "Nunca me he escapado de casa de adolescente", category: "risk", subcategory: "reckless", intensity: 4, is_nsfw: false },
{ en: "Never have I ever tipped less than I should have", de: "Ich hab noch nie weniger Trinkgeld gegeben, als ich hätte sollen", es: "Nunca he dejado menos propina de la que debería", category: "moral_gray", subcategory: "temptation", intensity: 4, is_nsfw: false },
{ en: "Never have I ever questioned a lifelong friendship", de: "Ich hab noch nie eine lebenslange Freundschaft infrage gestellt", es: "Nunca he cuestionado una amistad de toda la vida", category: "deep", subcategory: "growth", intensity: 4, is_nsfw: false },
{ en: "Never have I ever eaten an entire bag of chips in one sitting", de: "Ich hab noch nie eine ganze Tüte Chips in einer Sitzung gegessen", es: "Nunca me he comido una bolsa entera de papas de una sentada", category: "food", subcategory: "habits", intensity: 4, is_nsfw: false },
{ en: "Never have I ever fallen for a prank call", de: "Ich bin noch nie auf einen Telefonstreich reingefallen", es: "Nunca he caído en una broma telefónica", category: "embarrassing", subcategory: "cringe", intensity: 4, is_nsfw: false },
{ en: "Never have I ever stayed up all night overthinking", de: "Ich hab noch nie die ganze Nacht wach gelegen und zu viel nachgedacht", es: "Nunca me he quedado despierto toda la noche pensando demasiado", category: "deep", subcategory: "mental_health", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been forced to sit next to someone I can't stand at a dinner", de: "Ich musste noch nie bei einem Abendessen neben jemandem sitzen, den ich nicht ausstehen kann", es: "Nunca me han obligado a sentarme junto a alguien que no soporto en una cena", category: "social", subcategory: "awkward", intensity: 4, is_nsfw: false },
{ en: "Never have I ever felt like crying but couldn't", de: "Ich wollte noch nie weinen, konnte es aber nicht", es: "Nunca he querido llorar pero no pude", category: "deep", subcategory: "vulnerability", intensity: 4, is_nsfw: false },
{ en: "Never have I ever pretended I read a book I only read the summary of", de: "Ich hab noch nie so getan, als hätte ich ein Buch gelesen, von dem ich nur die Zusammenfassung kannte", es: "Nunca he fingido haber leído un libro del que solo leí el resumen", category: "confessions", subcategory: "dishonesty", intensity: 4, is_nsfw: false },
{ en: "Never have I ever deleted a conversation I didn't want anyone to find", de: "Ich hab noch nie einen Chatverlauf gelöscht, damit ihn niemand findet", es: "Nunca he borrado una conversación que no quería que nadie encontrara", category: "confessions", subcategory: "secrets", intensity: 4, is_nsfw: false },
{ en: "Never have I ever eaten an entire pizza by myself in one sitting", de: "Ich hab noch nie eine ganze Pizza alleine auf einmal gegessen", es: "Nunca me he comido una pizza entera solo de una sentada", category: "food", subcategory: "habits", intensity: 4, is_nsfw: false },
{ en: "Never have I ever lied on a resume", de: "Ich hab noch nie in einem Lebenslauf gelogen", es: "Nunca he mentido en un currículum", category: "confessions", subcategory: "dishonesty", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been hurt by someone I defended", de: "Ich wurde noch nie von jemandem verletzt, den ich verteidigt hab", es: "Nunca me ha lastimado alguien a quien defendí", category: "deep", subcategory: "growth", intensity: 4, is_nsfw: false },
{ en: "Never have I ever texted something risky to the wrong person", de: "Ich hab noch nie eine riskante Nachricht an die falsche Person geschickt", es: "Nunca he mandado un mensaje arriesgado a la persona equivocada", category: "embarrassing", subcategory: "cringe", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been uncomfortable at a family gathering because of a question someone asked", de: "Ich hab mich noch nie bei einem Familientreffen unwohl gefühlt wegen einer Frage, die jemand gestellt hat", es: "Nunca me he sentido incómodo en una reunión familiar por una pregunta que alguien hizo", category: "social", subcategory: "awkward", intensity: 4, is_nsfw: false },
{ en: "Never have I ever had imposter syndrome", de: "Ich hatte noch nie das Hochstapler-Syndrom", es: "Nunca he tenido el síndrome del impostor", category: "deep", subcategory: "identity", intensity: 4, is_nsfw: false },
{ en: "Never have I ever broken a promise to myself", de: "Ich hab noch nie ein Versprechen an mich selbst gebrochen", es: "Nunca he roto una promesa que me hice a mí mismo", category: "deep", subcategory: "growth", intensity: 4, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 5 — need 50 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever told someone I was over them when I wasn't", de: "Ich hab noch nie jemandem gesagt, dass ich über ihn hinweg bin, obwohl ich es nicht war", es: "Nunca le he dicho a alguien que lo superé cuando no era así", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever had a fight with a friend that made me cry", de: "Ich hatte noch nie einen Streit mit einem Freund, der mich zum Weinen gebracht hat", es: "Nunca he tenido una pelea con un amigo que me hizo llorar", category: "deep", subcategory: "vulnerability", intensity: 5, is_nsfw: false },
{ en: "Never have I ever tried a substance I probably shouldn't have", de: "Ich hab noch nie eine Substanz probiert, die ich wahrscheinlich nicht hätte probieren sollen", es: "Nunca he probado una sustancia que probablemente no debería haber probado", category: "risk", subcategory: "substances", intensity: 5, is_nsfw: false },
{ en: "Never have I ever let someone treat me badly because I was afraid to be alone", de: "Ich hab mich noch nie schlecht behandeln lassen, weil ich Angst hatte, allein zu sein", es: "Nunca he dejado que alguien me trate mal porque tenía miedo de estar solo", category: "relationships", subcategory: "boundaries", intensity: 5, is_nsfw: false },
{ en: "Never have I ever made a decision while drunk that I had to live with sober", de: "Ich hab noch nie betrunken eine Entscheidung getroffen, mit der ich nüchtern leben musste", es: "Nunca he tomado una decisión borracho con la que tuve que vivir sobrio", category: "party", subcategory: "drinking", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been in a situationship I couldn't define", de: "Ich war noch nie in einer Situationship, die ich nicht definieren konnte", es: "Nunca he estado en una relación indefinida que no podía definir", category: "relationships", subcategory: "situationship", intensity: 5, is_nsfw: false },
{ en: "Never have I ever said 'I love you' and not heard it back", de: "Ich hab noch nie 'Ich liebe dich' gesagt und es nicht zurückgehört", es: "Nunca he dicho 'te amo' y no recibí respuesta", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever played hard to get and then lost the person", de: "Ich hab noch nie auf schwer zu haben gemacht und die Person dann verloren", es: "Nunca me he hecho el difícil y luego perdí a la persona", category: "relationships", subcategory: "flirting", intensity: 5, is_nsfw: false },
{ en: "Never have I ever eaten something I was allergic to because I didn't want to be rude", de: "Ich hab noch nie etwas gegessen, gegen das ich allergisch war, weil ich nicht unhöflich sein wollte", es: "Nunca he comido algo a lo que soy alérgico porque no quería ser grosero", category: "food", subcategory: "picky", intensity: 5, is_nsfw: false },
{ en: "Never have I ever realized someone was only using me for something", de: "Ich hab noch nie gemerkt, dass mich jemand nur für etwas benutzt hat", es: "Nunca me he dado cuenta de que alguien solo me usaba para algo", category: "deep", subcategory: "growth", intensity: 5, is_nsfw: false },
{ en: "Never have I ever driven recklessly because I was upset", de: "Ich bin noch nie rücksichtslos gefahren, weil ich aufgewühlt war", es: "Nunca he manejado imprudentemente porque estaba alterado", category: "risk", subcategory: "driving", intensity: 5, is_nsfw: false },
{ en: "Never have I ever done something for attention I later regretted", de: "Ich hab noch nie etwas für Aufmerksamkeit getan, das ich später bereut hab", es: "Nunca he hecho algo por atención que luego lamenté", category: "confessions", subcategory: "shame", intensity: 5, is_nsfw: false },
{ en: "Never have I ever felt guilty about the way I treated someone years ago", de: "Ich hab mich noch nie schuldig gefühlt wegen der Art, wie ich jemanden vor Jahren behandelt hab", es: "Nunca me he sentido culpable por cómo traté a alguien hace años", category: "deep", subcategory: "regret", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been told I give too much of myself to people who don't deserve it", de: "Mir wurde noch nie gesagt, dass ich zu viel von mir gebe an Leute, die es nicht verdienen", es: "Nunca me han dicho que doy demasiado de mí a personas que no lo merecen", category: "deep", subcategory: "growth", intensity: 5, is_nsfw: false },
{ en: "Never have I ever faked a smile so well that nobody noticed", de: "Ich hab noch nie so gut ein Lächeln vorgetäuscht, dass es niemand gemerkt hat", es: "Nunca he fingido una sonrisa tan bien que nadie se dio cuenta", category: "deep", subcategory: "vulnerability", intensity: 5, is_nsfw: false },
{ en: "Never have I ever woken up somewhere and had no idea how I got there", de: "Ich bin noch nie irgendwo aufgewacht und hatte keine Ahnung, wie ich dahingekommen bin", es: "Nunca me he despertado en algún lugar sin saber cómo llegué ahí", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever dropped a friend because my partner didn't like them", de: "Ich hab noch nie einen Freund fallen gelassen, weil mein Partner die Person nicht mochte", es: "Nunca he dejado a un amigo porque a mi pareja no le caía bien", category: "relationships", subcategory: "boundaries", intensity: 5, is_nsfw: false },
{ en: "Never have I ever taken a risk I knew could ruin everything", de: "Ich bin noch nie ein Risiko eingegangen, von dem ich wusste, dass es alles ruinieren könnte", es: "Nunca he tomado un riesgo que sabía que podía arruinar todo", category: "risk", subcategory: "reckless", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been so angry I said things I didn't mean", de: "Ich war noch nie so wütend, dass ich Dinge gesagt hab, die ich nicht gemeint hab", es: "Nunca he estado tan enojado que dije cosas que no quería decir", category: "deep", subcategory: "vulnerability", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been jealous of my own best friend's relationship", de: "Ich war noch nie eifersüchtig auf die Beziehung meines besten Freundes", es: "Nunca he tenido celos de la relación de mi mejor amigo", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 6 — need 71 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever sent nudes to the wrong person", de: "Ich hab noch nie Nudes an die falsche Person geschickt", es: "Nunca he mandado fotos íntimas a la persona equivocada", category: "sexual", subcategory: "desire", intensity: 6, is_nsfw: false },
{ en: "Never have I ever snuck out to meet someone my parents wouldn't approve of", de: "Ich bin noch nie heimlich rausgeschlichen, um jemanden zu treffen, den meine Eltern nicht gut finden würden", es: "Nunca me he escapado para ver a alguien que mis padres no aprobarían", category: "relationships", subcategory: "dating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever developed feelings for a one-night stand", de: "Ich hab noch nie Gefühle für einen One-Night-Stand entwickelt", es: "Nunca he desarrollado sentimientos por un encuentro de una noche", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been jealous enough to go through someone's messages", de: "Ich war noch nie so eifersüchtig, dass ich jemandes Nachrichten durchgegangen bin", es: "Nunca he estado tan celoso que revisé los mensajes de alguien", category: "relationships", subcategory: "boundaries", intensity: 6, is_nsfw: false },
{ en: "Never have I ever lied about a one-night stand to make it sound better", de: "Ich hab noch nie über einen One-Night-Stand gelogen, um es besser klingen zu lassen", es: "Nunca he mentido sobre un encuentro de una noche para que suene mejor", category: "confessions", subcategory: "dishonesty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been attracted to someone's partner and hated myself for it", de: "Ich war noch nie von jemandes Partner angezogen und hab mich dafür gehasst", es: "Nunca me he sentido atraído por la pareja de alguien y me odié por ello", category: "sexual", subcategory: "temptation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever destroyed a letter or message someone sent me", de: "Ich hab noch nie einen Brief oder eine Nachricht vernichtet, die mir jemand geschickt hat", es: "Nunca he destruido una carta o mensaje que alguien me envió", category: "relationships", subcategory: "heartbreak", intensity: 6, is_nsfw: false },
{ en: "Never have I ever drunk-texted an ex and pretended it never happened", de: "Ich hab noch nie betrunken einem Ex geschrieben und so getan, als wäre es nie passiert", es: "Nunca le he mandado un mensaje a un ex borracho y fingí que nunca pasó", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever taken revenge on someone in a petty way", de: "Ich hab mich noch nie auf eine kleinliche Art an jemandem gerächt", es: "Nunca me he vengado de alguien de forma mezquina", category: "moral_gray", subcategory: "dark", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt ashamed of where I come from", de: "Ich hab mich noch nie für meine Herkunft geschämt", es: "Nunca me he avergonzado de donde vengo", category: "deep", subcategory: "identity", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been in a fight over someone I was dating", de: "Ich hatte noch nie einen Streit wegen jemandem, mit dem ich mich getroffen hab", es: "Nunca he peleado por alguien con quien salía", category: "relationships", subcategory: "dating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever left someone on read as a power move", de: "Ich hab noch nie jemanden auf gelesen gelassen als Machtspiel", es: "Nunca he dejado a alguien en visto como un movimiento de poder", category: "moral_gray", subcategory: "manipulation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been physically intimate with someone just to feel wanted", de: "Ich war noch nie körperlich intim mit jemandem, nur um mich gewollt zu fühlen", es: "Nunca he sido íntimo físicamente con alguien solo para sentirme deseado", category: "sexual", subcategory: "desire", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been told I'm too intense for someone", de: "Mir wurde noch nie gesagt, dass ich jemandem zu intensiv bin", es: "Nunca me han dicho que soy demasiado intenso para alguien", category: "relationships", subcategory: "boundaries", intensity: 6, is_nsfw: false },
{ en: "Never have I ever made a drunk promise I couldn't keep", de: "Ich hab noch nie betrunken ein Versprechen gemacht, das ich nicht halten konnte", es: "Nunca he hecho una promesa borracho que no pude cumplir", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever used someone's insecurity against them in an argument", de: "Ich hab noch nie jemandes Unsicherheit in einem Streit gegen die Person benutzt", es: "Nunca he usado la inseguridad de alguien en su contra en una discusión", category: "moral_gray", subcategory: "manipulation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever realized too late that I loved someone", de: "Ich hab noch nie zu spät gemerkt, dass ich jemanden liebe", es: "Nunca me he dado cuenta demasiado tarde de que amaba a alguien", category: "deep", subcategory: "regret", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had a moment where I didn't recognize myself anymore", de: "Ich hatte noch nie einen Moment, in dem ich mich selbst nicht mehr erkannt hab", es: "Nunca he tenido un momento en el que ya no me reconocí", category: "deep", subcategory: "identity", intensity: 6, is_nsfw: false },
{ en: "Never have I ever woken up regretting something I said while drunk", de: "Ich bin noch nie aufgewacht und hab etwas bereut, das ich betrunken gesagt hab", es: "Nunca me he despertado arrepentido de algo que dije borracho", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever confronted someone who cheated on me", de: "Ich hab noch nie jemanden konfrontiert, der mich betrogen hat", es: "Nunca he confrontado a alguien que me fue infiel", category: "relationships", subcategory: "heartbreak", intensity: 6, is_nsfw: false },
{ en: "Never have I ever played a drinking game that went too far", de: "Ich hab noch nie ein Trinkspiel gespielt, das zu weit ging", es: "Nunca he jugado un juego de beber que se pasó de la raya", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been afraid to let someone see the real me", de: "Ich hatte noch nie Angst, jemandem mein wahres Ich zu zeigen", es: "Nunca he tenido miedo de dejar que alguien vea mi verdadero yo", category: "deep", subcategory: "vulnerability", intensity: 6, is_nsfw: false },
{ en: "Never have I ever taken the fall for someone who didn't deserve it", de: "Ich hab noch nie die Schuld auf mich genommen für jemanden, der es nicht verdient hat", es: "Nunca he cargado con la culpa por alguien que no lo merecía", category: "moral_gray", subcategory: "loyalty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever kept someone's darkest secret even though it was eating me alive", de: "Ich hab noch nie jemandes dunkelstes Geheimnis bewahrt, obwohl es mich innerlich aufgefressen hat", es: "Nunca he guardado el secreto más oscuro de alguien aunque me estaba consumiendo", category: "moral_gray", subcategory: "loyalty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever ruined a relationship by overthinking", de: "Ich hab noch nie eine Beziehung zerstört, weil ich zu viel nachgedacht hab", es: "Nunca he arruinado una relación por pensar demasiado", category: "relationships", subcategory: "boundaries", intensity: 6, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 7 — need 82 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever had a threesome fantasy I almost acted on", de: "Ich hatte noch nie eine Dreier-Fantasie, die ich fast umgesetzt hätte", es: "Nunca he tenido una fantasía de trío que casi llevé a cabo", category: "sexual", subcategory: "kinks", intensity: 7, is_nsfw: true },
{ en: "Never have I ever role-played during sex", de: "Ich hab noch nie ein Rollenspiel beim Sex gemacht", es: "Nunca he hecho un juego de roles durante el sexo", category: "sexual", subcategory: "kinks", intensity: 7, is_nsfw: true },
{ en: "Never have I ever had a friends-with-benefits arrangement that got messy", de: "Ich hatte noch nie eine Freundschaft Plus, die kompliziert geworden ist", es: "Nunca he tenido un acuerdo de amigos con beneficios que se complicó", category: "sexual", subcategory: "boundaries", intensity: 7, is_nsfw: true },
{ en: "Never have I ever been told a secret about someone that changed how I saw them", de: "Mir wurde noch nie ein Geheimnis über jemanden erzählt, das verändert hat, wie ich die Person sehe", es: "Nunca me han contado un secreto sobre alguien que cambió cómo los veo", category: "confessions", subcategory: "secrets", intensity: 7, is_nsfw: false },
{ en: "Never have I ever thought about what would happen if I just didn't show up to my life one day", de: "Ich hab noch nie darüber nachgedacht, was passieren würde, wenn ich eines Tages einfach nicht zu meinem Leben auftauche", es: "Nunca he pensado en qué pasaría si simplemente no apareciera a mi vida un día", category: "deep", subcategory: "mental_health", intensity: 7, is_nsfw: false },
{ en: "Never have I ever texted an ex in the middle of the night", de: "Ich hab noch nie mitten in der Nacht einem Ex geschrieben", es: "Nunca le he escrito a un ex en la madrugada", category: "relationships", subcategory: "heartbreak", intensity: 7, is_nsfw: false },
{ en: "Never have I ever lied about how much money I make", de: "Ich hab noch nie gelogen, wie viel Geld ich verdiene", es: "Nunca he mentido sobre cuánto dinero gano", category: "confessions", subcategory: "dishonesty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever wondered if I'll ever truly love someone", de: "Ich hab mich noch nie gefragt, ob ich jemals jemanden wirklich lieben werde", es: "Nunca me he preguntado si alguna vez amaré verdaderamente a alguien", category: "deep", subcategory: "vulnerability", intensity: 7, is_nsfw: false },
{ en: "Never have I ever pretended to be over an ex while stalking them online every day", de: "Ich hab noch nie so getan, als wäre ich über einen Ex hinweg, während ich die Person täglich online gestalkt hab", es: "Nunca he fingido haber superado a un ex mientras lo stalkeaba en línea todos los días", category: "relationships", subcategory: "heartbreak", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had sex to save a relationship", de: "Ich hatte noch nie Sex, um eine Beziehung zu retten", es: "Nunca he tenido sexo para salvar una relación", category: "sexual", subcategory: "boundaries", intensity: 7, is_nsfw: true },
{ en: "Never have I ever had someone break my trust so badly I changed as a person", de: "Mir hat noch nie jemand so sehr mein Vertrauen gebrochen, dass ich mich als Person verändert hab", es: "Nunca alguien me ha traicionado la confianza tan fuerte que cambié como persona", category: "deep", subcategory: "growth", intensity: 7, is_nsfw: false },
{ en: "Never have I ever done something illegal with someone I was sleeping with", de: "Ich hab noch nie etwas Illegales mit jemandem gemacht, mit dem ich geschlafen hab", es: "Nunca he hecho algo ilegal con alguien con quien me acostaba", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: true },
{ en: "Never have I ever been so angry I wanted to burn bridges with everyone", de: "Ich war noch nie so wütend, dass ich alle Brücken abbrechen wollte", es: "Nunca he estado tan enojado que quise quemar todos los puentes", category: "deep", subcategory: "vulnerability", intensity: 7, is_nsfw: false },
{ en: "Never have I ever used dating apps while emotionally unavailable", de: "Ich hab noch nie Dating-Apps benutzt, während ich emotional nicht verfügbar war", es: "Nunca he usado apps de citas mientras estaba emocionalmente no disponible", category: "relationships", subcategory: "dating", intensity: 7, is_nsfw: false },
{ en: "Never have I ever felt like I lost my innocence too early", de: "Ich hatte noch nie das Gefühl, meine Unschuld zu früh verloren zu haben", es: "Nunca he sentido que perdí mi inocencia demasiado pronto", category: "deep", subcategory: "identity", intensity: 7, is_nsfw: false },
{ en: "Never have I ever seriously considered cutting someone completely out of my life", de: "Ich hab noch nie ernsthaft in Betracht gezogen, jemanden komplett aus meinem Leben zu schneiden", es: "Nunca he considerado seriamente cortar a alguien completamente de mi vida", category: "deep", subcategory: "growth", intensity: 7, is_nsfw: false },
{ en: "Never have I ever woken up with bruises and no idea how I got them", de: "Ich bin noch nie mit blauen Flecken aufgewacht und hatte keine Ahnung, woher sie kamen", es: "Nunca me he despertado con moretones sin saber cómo me los hice", category: "party", subcategory: "wild_nights", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had a panic attack during sex", de: "Ich hatte noch nie eine Panikattacke beim Sex", es: "Nunca he tenido un ataque de pánico durante el sexo", category: "sexual", subcategory: "boundaries", intensity: 7, is_nsfw: true },
{ en: "Never have I ever experimented with someone of the same sex", de: "Ich hab noch nie mit jemandem des gleichen Geschlechts experimentiert", es: "Nunca he experimentado con alguien del mismo sexo", category: "sexual", subcategory: "desire", intensity: 7, is_nsfw: true },
{ en: "Never have I ever looked through a partner's phone and found something I wish I hadn't", de: "Ich hab noch nie das Handy eines Partners durchsucht und etwas gefunden, das ich lieber nicht gesehen hätte", es: "Nunca he revisado el teléfono de mi pareja y encontré algo que desearía no haber visto", category: "relationships", subcategory: "boundaries", intensity: 7, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 94 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever given an ultimatum in a relationship", de: "Ich hab noch nie ein Ultimatum in einer Beziehung gestellt", es: "Nunca he dado un ultimátum en una relación", category: "relationships", subcategory: "boundaries", intensity: 8, is_nsfw: false },
{ en: "Never have I ever stayed in a relationship only because of the sex", de: "Ich bin noch nie nur wegen dem Sex in einer Beziehung geblieben", es: "Nunca me he quedado en una relación solo por el sexo", category: "sexual", subcategory: "desire", intensity: 8, is_nsfw: true },
{ en: "Never have I ever been so jealous I became someone I didn't recognize", de: "Ich war noch nie so eifersüchtig, dass ich jemand wurde, den ich nicht wiedererkannt hab", es: "Nunca he estado tan celoso que me convertí en alguien que no reconocía", category: "deep", subcategory: "vulnerability", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had an intense physical relationship with no emotional connection", de: "Ich hatte noch nie eine intensive körperliche Beziehung ohne emotionale Verbindung", es: "Nunca he tenido una relación física intensa sin conexión emocional", category: "sexual", subcategory: "hookups", intensity: 8, is_nsfw: true },
{ en: "Never have I ever questioned whether someone truly loved me or just needed me", de: "Ich hab mich noch nie gefragt, ob jemand mich wirklich liebt oder mich nur braucht", es: "Nunca me he preguntado si alguien realmente me amaba o solo me necesitaba", category: "deep", subcategory: "vulnerability", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had revenge fantasies about someone who wronged me", de: "Ich hatte noch nie Rachefantasien über jemanden, der mir Unrecht getan hat", es: "Nunca he tenido fantasías de venganza sobre alguien que me hizo daño", category: "moral_gray", subcategory: "dark", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been in a relationship where control was disguised as love", de: "Ich war noch nie in einer Beziehung, in der Kontrolle als Liebe getarnt war", es: "Nunca he estado en una relación donde el control se disfrazaba de amor", category: "relationships", subcategory: "boundaries", intensity: 8, is_nsfw: false },
{ en: "Never have I ever done something I can't talk about without crying", de: "Ich hab noch nie etwas getan, über das ich nicht reden kann, ohne zu weinen", es: "Nunca he hecho algo de lo que no puedo hablar sin llorar", category: "deep", subcategory: "vulnerability", intensity: 8, is_nsfw: false },
{ en: "Never have I ever texted someone explicit content while at work", de: "Ich hab noch nie jemandem expliziten Inhalt geschickt, während ich bei der Arbeit war", es: "Nunca le he mandado contenido explícito a alguien estando en el trabajo", category: "sexual", subcategory: "desire", intensity: 8, is_nsfw: true },
{ en: "Never have I ever been afraid my own behavior was becoming abusive", de: "Ich hatte noch nie Angst, dass mein eigenes Verhalten missbräuchlich wird", es: "Nunca he tenido miedo de que mi propio comportamiento se estuviera volviendo abusivo", category: "deep", subcategory: "mental_health", intensity: 8, is_nsfw: false },
{ en: "Never have I ever wanted to tell someone the truth but chose not to because it would destroy them", de: "Ich wollte noch nie jemandem die Wahrheit sagen, hab es aber nicht getan, weil es die Person zerstören würde", es: "Nunca he querido decirle la verdad a alguien pero elegí no hacerlo porque lo destruiría", category: "moral_gray", subcategory: "loyalty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been attracted to someone who was bad for every single person they dated", de: "Ich war noch nie von jemandem angezogen, der schlecht war für jede einzelne Person, mit der er was hatte", es: "Nunca me he sentido atraído por alguien que fue malo para cada persona con la que salió", category: "relationships", subcategory: "dating", intensity: 8, is_nsfw: false },
{ en: "Never have I ever watched someone's life fall apart because of a decision I helped make", de: "Ich hab noch nie zugesehen, wie jemandes Leben zusammenbrach wegen einer Entscheidung, die ich mitgetroffen hab", es: "Nunca he visto cómo la vida de alguien se desmoronaba por una decisión que ayudé a tomar", category: "moral_gray", subcategory: "dark", intensity: 8, is_nsfw: false },
{ en: "Never have I ever slept with someone I actively disliked", de: "Ich hab noch nie mit jemandem geschlafen, den ich aktiv nicht mochte", es: "Nunca me he acostado con alguien que activamente no me caía bien", category: "sexual", subcategory: "hookups", intensity: 8, is_nsfw: true },
{ en: "Never have I ever been punished for doing the right thing", de: "Ich wurde noch nie bestraft, weil ich das Richtige getan hab", es: "Nunca me han castigado por hacer lo correcto", category: "deep", subcategory: "regret", intensity: 8, is_nsfw: false },
{ en: "Never have I ever kept a grudge against someone for more than a year", de: "Ich hab noch nie länger als ein Jahr einen Groll gegen jemanden gehegt", es: "Nunca he guardado rencor contra alguien por más de un año", category: "deep", subcategory: "regret", intensity: 8, is_nsfw: false },
{ en: "Never have I ever lost a relationship because of my own mental health issues", de: "Ich hab noch nie eine Beziehung verloren wegen meiner eigenen psychischen Probleme", es: "Nunca he perdido una relación por mis propios problemas de salud mental", category: "deep", subcategory: "mental_health", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had to confront a family member about their addiction", de: "Ich musste noch nie ein Familienmitglied wegen seiner Sucht konfrontieren", es: "Nunca he tenido que confrontar a un familiar por su adicción", category: "deep", subcategory: "vulnerability", intensity: 8, is_nsfw: false },
{ en: "Never have I ever regretted not standing up for someone when I had the chance", de: "Ich hab noch nie bereut, nicht für jemanden eingestanden zu sein, als ich die Chance hatte", es: "Nunca me he arrepentido de no defender a alguien cuando tuve la oportunidad", category: "deep", subcategory: "regret", intensity: 8, is_nsfw: false },
{ en: "Never have I ever explored a kink that society would judge me for", de: "Ich hab noch nie einen Kink erkundet, für den die Gesellschaft mich verurteilen würde", es: "Nunca he explorado un fetiche por el que la sociedad me juzgaría", category: "sexual", subcategory: "kinks", intensity: 8, is_nsfw: true },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 105 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever contemplated whether I'm capable of real love", de: "Ich hab noch nie darüber nachgedacht, ob ich zu wahrer Liebe fähig bin", es: "Nunca me he preguntado si soy capaz de amor verdadero", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a relationship where both people were intentionally cruel to each other", de: "Ich war noch nie in einer Beziehung, in der beide Seiten absichtlich grausam zueinander waren", es: "Nunca he estado en una relación donde ambas personas eran intencionalmente crueles", category: "relationships", subcategory: "boundaries", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been so numbed by pain that I stopped feeling anything", de: "Ich war noch nie so betäubt von Schmerz, dass ich gar nichts mehr gefühlt hab", es: "Nunca he estado tan entumecido por el dolor que dejé de sentir algo", category: "deep", subcategory: "mental_health", intensity: 9, is_nsfw: false },
{ en: "Never have I ever slept with someone as a way of punishing myself", de: "Ich hab noch nie mit jemandem geschlafen, um mich selbst zu bestrafen", es: "Nunca me he acostado con alguien como forma de castigarme", category: "sexual", subcategory: "boundaries", intensity: 9, is_nsfw: true },
{ en: "Never have I ever kept evidence of something I could use against someone", de: "Ich hab noch nie Beweise für etwas aufbewahrt, die ich gegen jemanden verwenden könnte", es: "Nunca he guardado evidencia de algo que podría usar contra alguien", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been in a relationship so dark it felt like a prison", de: "Ich war noch nie in einer Beziehung, die so dunkel war, dass sie sich wie ein Gefängnis angefühlt hat", es: "Nunca he estado en una relación tan oscura que se sentía como una prisión", category: "relationships", subcategory: "boundaries", intensity: 9, is_nsfw: false },
{ en: "Never have I ever lost my sense of self because of a relationship", de: "Ich hab noch nie mein Selbstgefühl wegen einer Beziehung verloren", es: "Nunca he perdido mi sentido del yo por una relación", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something so out of character it scared me", de: "Ich hab noch nie etwas so untypisch für mich getan, dass es mir Angst gemacht hat", es: "Nunca he hecho algo tan fuera de mi carácter que me asustó", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had an experience that completely shattered my worldview", de: "Ich hatte noch nie ein Erlebnis, das mein Weltbild komplett zerstört hat", es: "Nunca he tenido una experiencia que destrozó completamente mi visión del mundo", category: "deep", subcategory: "growth", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been betrayed by someone I considered family", de: "Ich wurde noch nie von jemandem verraten, den ich als Familie betrachtete", es: "Nunca me ha traicionado alguien que consideraba familia", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever feared I was becoming exactly who I promised myself I'd never be", de: "Ich hatte noch nie Angst, genau zu der Person zu werden, die ich mir geschworen hatte, nie zu sein", es: "Nunca he temido estar convirtiéndome exactamente en quien me prometí que nunca sería", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever knowingly ruined someone's reputation", de: "Ich hab noch nie wissentlich den Ruf von jemandem zerstört", es: "Nunca he arruinado la reputación de alguien a sabiendas", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a sexual experience where lines were crossed without words", de: "Ich hatte noch nie ein sexuelles Erlebnis, bei dem Grenzen ohne Worte überschritten wurden", es: "Nunca he tenido una experiencia sexual donde se cruzaron líneas sin palabras", category: "sexual", subcategory: "boundaries", intensity: 9, is_nsfw: true },
{ en: "Never have I ever wished I could erase a part of my past completely", de: "Ich hab mir noch nie gewünscht, einen Teil meiner Vergangenheit komplett auslöschen zu können", es: "Nunca he deseado poder borrar una parte de mi pasado completamente", category: "deep", subcategory: "regret", intensity: 9, is_nsfw: false },
{ en: "Never have I ever kept a toxic friendship alive out of fear of retaliation", de: "Ich hab noch nie eine toxische Freundschaft aufrechterhalten aus Angst vor Vergeltung", es: "Nunca he mantenido una amistad tóxica por miedo a represalias", category: "moral_gray", subcategory: "loyalty", intensity: 9, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 120 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever been in a situation so dark I still can't talk about it", de: "Ich war noch nie in einer Situation, die so dunkel war, dass ich immer noch nicht darüber reden kann", es: "Nunca he estado en una situación tan oscura que todavía no puedo hablar de ella", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever chosen power over love", de: "Ich hab mich noch nie für Macht statt Liebe entschieden", es: "Nunca he elegido el poder sobre el amor", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a secret relationship with someone who was taken", de: "Ich hatte noch nie eine geheime Beziehung mit jemandem, der vergeben war", es: "Nunca he tenido una relación secreta con alguien que ya tenía pareja", category: "sexual", subcategory: "temptation", intensity: 10, is_nsfw: true },
{ en: "Never have I ever experienced something so intimate it permanently changed the way I connect with people", de: "Ich hatte noch nie ein so intimes Erlebnis, dass es dauerhaft verändert hat, wie ich mich mit Menschen verbinde", es: "Nunca he experimentado algo tan íntimo que cambió permanentemente cómo me conecto con la gente", category: "sexual", subcategory: "desire", intensity: 10, is_nsfw: true },
{ en: "Never have I ever forgiven something that I know most people never would", de: "Ich hab noch nie etwas verziehen, von dem ich weiß, dass es die meisten Menschen nie tun würden", es: "Nunca he perdonado algo que sé que la mayoría de las personas nunca perdonaría", category: "deep", subcategory: "growth", intensity: 10, is_nsfw: false },
{ en: "Never have I ever looked at my reflection and felt like a stranger was looking back", de: "Ich hab noch nie in meinen Spiegel geschaut und das Gefühl gehabt, ein Fremder schaut zurück", es: "Nunca me he mirado al espejo y sentí que un extraño me devolvía la mirada", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a moment of complete moral failure that nobody knows about", de: "Ich hatte noch nie einen Moment des totalen moralischen Versagens, von dem niemand weiß", es: "Nunca he tenido un momento de fracaso moral completo que nadie sabe", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever realized I was capable of coldness that scared even me", de: "Ich hab noch nie gemerkt, dass ich zu einer Kälte fähig bin, die sogar mich selbst erschreckt hat", es: "Nunca me he dado cuenta de que soy capaz de una frialdad que incluso a mí me asustó", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had an experience that made me lose faith in humanity", de: "Ich hatte noch nie ein Erlebnis, das mich den Glauben an die Menschheit verlieren ließ", es: "Nunca he tenido una experiencia que me hizo perder la fe en la humanidad", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever kept a lie going so long it became my reality", de: "Ich hab noch nie eine Lüge so lange aufrechterhalten, dass sie zu meiner Realität wurde", es: "Nunca he mantenido una mentira por tanto tiempo que se convirtió en mi realidad", category: "confessions", subcategory: "dishonesty", intensity: 10, is_nsfw: false },
];

// ═══════════════════════════════════════════════════════════
//  DEDUPLICATE AND MERGE
// ═══════════════════════════════════════════════════════════

const BASE_PATH = path.resolve(__dirname, '../app/assets/questions.json');
const base: any[] = JSON.parse(fs.readFileSync(BASE_PATH, 'utf-8'));

// First, deduplicate existing base
const seenEN = new Set<string>();
const deduped: any[] = [];
for (const q of base) {
  const key = q.text_en.toLowerCase().trim();
  if (!seenEN.has(key)) {
    seenEN.add(key);
    deduped.push(q);
  }
}
console.log(`Base after dedup: ${deduped.length} (removed ${base.length - deduped.length} dupes)`);

// Add batch3, skipping any that already exist
let added = 0;
for (const q of BATCH3) {
  const key = q.en.toLowerCase().trim();
  if (seenEN.has(key)) {
    console.log(`  SKIP (already exists): ${q.en.substring(0, 50)}...`);
    continue;
  }
  seenEN.add(key);
  const meta = computeMetadata(q);
  deduped.push({
    id: `placeholder`,
    text_en: q.en,
    text_de: q.de,
    text_es: q.es,
    category: q.category,
    subcategory: q.subcategory,
    intensity: q.intensity,
    is_nsfw: q.is_nsfw,
    is_premium: meta.is_premium,
    shock_factor: meta.shock_factor,
    vulnerability_level: meta.vulnerability_level,
    energy: meta.energy,
  });
  added++;
}
console.log(`Added from batch3: ${added}`);

// Re-assign IDs sequentially
for (let i = 0; i < deduped.length; i++) {
  deduped[i].id = `q${String(i + 1).padStart(4, '0')}`;
}

console.log(`Total: ${deduped.length}`);

const byIntensity = new Map<number, number>();
for (const q of deduped) {
  byIntensity.set(q.intensity, (byIntensity.get(q.intensity) || 0) + 1);
}
console.log('\nDistribution by intensity:');
let totalNeeded = 0;
for (let i = 1; i <= 10; i++) {
  const count = byIntensity.get(i) || 0;
  const gap = Math.max(0, 160 - count);
  totalNeeded += gap;
  console.log(`  ${i}: ${count} ${gap > 0 ? `(need ${gap} more)` : '✅'}`);
}
console.log(`Total still needed: ${totalNeeded}`);

const byCat = new Map<string, number>();
for (const q of deduped) {
  byCat.set(q.category, (byCat.get(q.category) || 0) + 1);
}
console.log('\nDistribution by category:');
for (const [cat, count] of [...byCat.entries()].sort((a, b) => b[1] - a[1])) {
  console.log(`  ${cat}: ${count}`);
}

fs.writeFileSync(BASE_PATH, JSON.stringify(deduped, null, 2) + '\n', 'utf-8');
console.log(`\n✅ Wrote ${deduped.length} questions to ${BASE_PATH}`);
