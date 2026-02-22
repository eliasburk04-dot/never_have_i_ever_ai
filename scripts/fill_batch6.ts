#!/usr/bin/env npx tsx
/**
 * BATCH 6 — FINAL 179 to reach 1600
 * Gaps: 6:9, 7:27, 8:36, 9:47, 10:60 = 179
 * Category balance: deep(252) over, food(78) party(106) risk(109) embarrassing(116) under
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

const BATCH6: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 6 — need 9
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever cooked someone a meal as an apology", de: "Ich hab noch nie jemandem als Entschuldigung etwas gekocht", es: "Nunca le he cocinado a alguien como disculpa", category: "food", subcategory: "cooking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever ruined someone's birthday party", de: "Ich hab noch nie jemandes Geburtstagsparty ruiniert", es: "Nunca he arruinado la fiesta de cumpleaños de alguien", category: "party", subcategory: "faux_pas", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been peer-pressured into something I regretted immediately", de: "Ich wurde noch nie zu etwas gedrängt, das ich sofort bereut hab", es: "Nunca me han presionado a hacer algo que lamenté de inmediato", category: "risk", subcategory: "bets", intensity: 6, is_nsfw: false },
{ en: "Never have I ever let someone think I'm more experienced than I am", de: "Ich hab noch nie jemanden glauben lassen, dass ich mehr Erfahrung hab, als ich tatsächlich hab", es: "Nunca he dejado que alguien piense que tengo más experiencia de la que realmente tengo", category: "confessions", subcategory: "dishonesty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever accidentally walked in on someone in the bathroom", de: "Ich bin noch nie versehentlich bei jemandem im Bad reingeplatzt", es: "Nunca he entrado accidentalmente al baño cuando alguien estaba ahí", category: "embarrassing", subcategory: "caught", intensity: 6, is_nsfw: false },
{ en: "Never have I ever broken a diet in spectacular fashion", de: "Ich hab noch nie eine Diät auf spektakuläre Weise gebrochen", es: "Nunca he roto una dieta de manera espectacular", category: "food", subcategory: "habits", intensity: 6, is_nsfw: false },
{ en: "Never have I ever danced on a table or bar", de: "Ich hab noch nie auf einem Tisch oder einer Bar getanzt", es: "Nunca he bailado sobre una mesa o barra", category: "party", subcategory: "dares", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been caught singing loudly alone and someone recorded it", de: "Ich wurde noch nie beim lauten Alleine-Singen erwischt und jemand hat es aufgenommen", es: "Nunca me han cachado cantando solo en voz alta y alguien lo grabó", category: "embarrassing", subcategory: "cringe", intensity: 6, is_nsfw: false },
{ en: "Never have I ever confronted someone who was spreading rumors about me", de: "Ich hab noch nie jemanden konfrontiert, der Gerüchte über mich verbreitet hat", es: "Nunca he confrontado a alguien que estaba difundiendo rumores sobre mí", category: "social", subcategory: "conflict", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been the last one standing at a party", de: "Ich war noch nie der Letzte, der auf einer Party noch stand", es: "Nunca he sido el último en pie en una fiesta", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever taken a risk purely because I was bored", de: "Ich bin noch nie ein Risiko eingegangen, nur weil mir langweilig war", es: "Nunca he tomado un riesgo puramente porque estaba aburrido", category: "risk", subcategory: "stunts", intensity: 6, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 7 — need 27
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever had a food allergy reaction and pretended I was fine", de: "Ich hatte noch nie eine allergische Reaktion auf Essen und hab so getan, als wäre alles okay", es: "Nunca he tenido una reacción alérgica a comida y fingí que estaba bien", category: "food", subcategory: "gross", intensity: 7, is_nsfw: false },
{ en: "Never have I ever trashed a hotel room", de: "Ich hab noch nie ein Hotelzimmer verwüstet", es: "Nunca he destrozado una habitación de hotel", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had a confrontation at a party that got physical", de: "Ich hatte noch nie eine Auseinandersetzung auf einer Party, die handgreiflich wurde", es: "Nunca he tenido una confrontación en una fiesta que se volvió física", category: "party", subcategory: "wild_nights", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been the person nobody wanted on their team", de: "Ich war noch nie die Person, die niemand in seinem Team haben wollte", es: "Nunca he sido la persona que nadie quería en su equipo", category: "embarrassing", subcategory: "public", intensity: 7, is_nsfw: false },
{ en: "Never have I ever eaten something that turned out to contain an ingredient I'm against eating", de: "Ich hab noch nie etwas gegessen, das eine Zutat enthielt, die ich eigentlich nicht essen wollte", es: "Nunca he comido algo que resultó contener un ingrediente que no quiero comer", category: "food", subcategory: "picky", intensity: 7, is_nsfw: false },
{ en: "Never have I ever ended a friendship over text", de: "Ich hab noch nie eine Freundschaft per Textnachricht beendet", es: "Nunca he terminado una amistad por mensaje de texto", category: "social", subcategory: "conflict", intensity: 7, is_nsfw: false },
{ en: "Never have I ever mixed up someone's name at the worst possible moment", de: "Ich hab noch nie jemandes Namen im schlimmsten Moment verwechselt", es: "Nunca he confundido el nombre de alguien en el peor momento posible", category: "embarrassing", subcategory: "cringe", intensity: 7, is_nsfw: false },
{ en: "Never have I ever keyed someone's car", de: "Ich hab noch nie jemandes Auto zerkratzt", es: "Nunca le he rayado el auto a alguien", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever flirted with someone's partner right in front of them", de: "Ich hab noch nie direkt vor jemandem mit dessen Partner geflirtet", es: "Nunca he coqueteado con la pareja de alguien justo frente a ellos", category: "social", subcategory: "awkward", intensity: 7, is_nsfw: false },
{ en: "Never have I ever vomited on someone at a party", de: "Ich hab mich noch nie auf einer Party auf jemanden übergeben", es: "Nunca he vomitado encima de alguien en una fiesta", category: "party", subcategory: "drinking", intensity: 7, is_nsfw: false },
{ en: "Never have I ever done something embarrassing on a date that ended it immediately", de: "Ich hab noch nie etwas so Peinliches auf einem Date gemacht, dass es sofort vorbei war", es: "Nunca he hecho algo tan vergonzoso en una cita que la terminó de inmediato", category: "embarrassing", subcategory: "cringe", intensity: 7, is_nsfw: false },
{ en: "Never have I ever binged food so hard I felt physically sick for hours", de: "Ich hab noch nie so viel gegessen, dass ich mich stundenlang körperlich krank gefühlt hab", es: "Nunca he comido tanto que me sentí físicamente enfermo por horas", category: "food", subcategory: "gross", intensity: 7, is_nsfw: false },
{ en: "Never have I ever regretted a drunken kiss the second it happened", de: "Ich hab noch nie einen betrunkenen Kuss bereut, in der Sekunde, in der er passiert ist", es: "Nunca he lamentado un beso borracho en el segundo en que pasó", category: "party", subcategory: "dares", intensity: 7, is_nsfw: false },
{ en: "Never have I ever lost a friend because I chose a partner over them", de: "Ich hab noch nie einen Freund verloren, weil ich einen Partner dem Freund vorgezogen hab", es: "Nunca he perdido un amigo porque elegí a una pareja sobre ellos", category: "social", subcategory: "conflict", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had a hangover so bad I missed an important event", de: "Ich hatte noch nie einen so schlimmen Kater, dass ich ein wichtiges Event verpasst hab", es: "Nunca he tenido una resaca tan mala que me perdí un evento importante", category: "party", subcategory: "drinking", intensity: 7, is_nsfw: false },
{ en: "Never have I ever thrown food at someone during an argument", de: "Ich hab noch nie während eines Streits Essen auf jemanden geworfen", es: "Nunca le he tirado comida a alguien durante una discusión", category: "food", subcategory: "gross", intensity: 7, is_nsfw: false },
{ en: "Never have I ever snuck into an event I wasn't invited to", de: "Ich hab mich noch nie in ein Event geschlichen, zu dem ich nicht eingeladen war", es: "Nunca me he colado en un evento al que no estaba invitado", category: "risk", subcategory: "stunts", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been so embarrassed I couldn't speak", de: "Mir war noch nie so peinlich, dass ich nicht sprechen konnte", es: "Nunca me he avergonzado tanto que no podía hablar", category: "embarrassing", subcategory: "public", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been the reason two people stopped talking", de: "Ich war noch nie der Grund, warum zwei Leute aufgehört haben miteinander zu reden", es: "Nunca he sido la razón por la que dos personas dejaron de hablarse", category: "social", subcategory: "conflict", intensity: 7, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 36
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever had someone expose my deepest secret to a room full of people", de: "Noch nie hat jemand mein tiefstes Geheimnis vor einem Raum voller Leute enthüllt", es: "Nunca alguien ha expuesto mi secreto más profundo frente a un cuarto lleno de gente", category: "embarrassing", subcategory: "caught", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been offered something illegal and considered it", de: "Mir wurde noch nie etwas Illegales angeboten und ich hab es in Betracht gezogen", es: "Nunca me han ofrecido algo ilegal y lo consideré", category: "risk", subcategory: "substances", intensity: 8, is_nsfw: false },
{ en: "Never have I ever cooked for someone with an ingredient I knew they'd hate, just to see their reaction", de: "Ich hab noch nie für jemanden mit einer Zutat gekocht, von der ich wusste, dass die Person sie hasst, nur um die Reaktion zu sehen", es: "Nunca he cocinado para alguien con un ingrediente que sabía que odiaría, solo para ver su reacción", category: "food", subcategory: "cooking", intensity: 8, is_nsfw: false },
{ en: "Never have I ever gotten into a screaming match at a party", de: "Ich hab mich noch nie auf einer Party angeschrien", es: "Nunca he tenido un gritadero en una fiesta", category: "party", subcategory: "faux_pas", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been humiliated in front of a large group", de: "Ich wurde noch nie vor einer großen Gruppe gedemütigt", es: "Nunca me han humillado frente a un grupo grande", category: "embarrassing", subcategory: "public", intensity: 8, is_nsfw: false },
{ en: "Never have I ever tried a food so disgusting it made someone else at the table gag", de: "Ich hab noch nie ein Essen probiert, das so eklig war, dass sich jemand anderes am Tisch geekelt hat", es: "Nunca he probado una comida tan asquerosa que hizo que alguien más en la mesa tuviera arcadas", category: "food", subcategory: "challenges", intensity: 8, is_nsfw: false },
{ en: "Never have I ever broken into a place just to prove I could", de: "Ich bin noch nie irgendwo eingebrochen, nur um zu beweisen, dass ich es kann", es: "Nunca he entrado a un lugar ilegalmente solo para probar que podía", category: "risk", subcategory: "stunts", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had a partner's family find out something about me that changed everything", de: "Noch nie hat die Familie eines Partners etwas über mich herausgefunden, das alles verändert hat", es: "Nunca la familia de una pareja descubrió algo sobre mí que cambió todo", category: "relationships", subcategory: "forbidden", intensity: 8, is_nsfw: false },
{ en: "Never have I ever sent food back at a restaurant and lied about the reason", de: "Ich hab noch nie Essen in einem Restaurant zurückgeschickt und den Grund dafür erfunden", es: "Nunca he devuelto comida en un restaurante y mentí sobre la razón", category: "food", subcategory: "picky", intensity: 8, is_nsfw: false },
{ en: "Never have I ever ruined an event with my behavior and only realized days later", de: "Ich hab noch nie eine Veranstaltung mit meinem Verhalten ruiniert und es erst Tage später realisiert", es: "Nunca he arruinado un evento con mi comportamiento y solo me di cuenta días después", category: "embarrassing", subcategory: "public", intensity: 8, is_nsfw: false },
{ en: "Never have I ever stayed silent when I should have spoken up about something serious", de: "Ich hab noch nie geschwiegen, als ich etwas Ernstes hätte ansprechen sollen", es: "Nunca me he quedado callado cuando debí haber hablado sobre algo serio", category: "moral_gray", subcategory: "loyalty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had to be physically restrained at a party", de: "Ich musste noch nie auf einer Party physisch festgehalten werden", es: "Nunca me han tenido que sujetar físicamente en una fiesta", category: "party", subcategory: "wild_nights", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been abandoned by friends during a night out", de: "Ich wurde noch nie während eines Abends von Freunden im Stich gelassen", es: "Nunca mis amigos me han abandonado durante una salida nocturna", category: "social", subcategory: "conflict", intensity: 8, is_nsfw: false },
{ en: "Never have I ever done something reckless with food that could have seriously hurt someone", de: "Ich hab noch nie etwas Rücksichtsloses mit Essen gemacht, das jemanden ernsthaft hätte verletzen können", es: "Nunca he hecho algo imprudente con comida que podría haber lastimado a alguien seriamente", category: "food", subcategory: "gross", intensity: 8, is_nsfw: false },
{ en: "Never have I ever manipulated a situation so I'd come out looking good", de: "Ich hab noch nie eine Situation so manipuliert, dass ich gut dastehe", es: "Nunca he manipulado una situación para quedar bien", category: "moral_gray", subcategory: "manipulation", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had an affair and genuinely believed it was justified", de: "Ich hatte noch nie eine Affäre und war ehrlich davon überzeugt, dass sie gerechtfertigt war", es: "Nunca he tenido una aventura y genuinamente creí que estaba justificada", category: "sexual", subcategory: "temptation", intensity: 8, is_nsfw: true },
{ en: "Never have I ever risked losing everything over a spontaneous decision", de: "Ich hab noch nie alles riskiert wegen einer spontanen Entscheidung", es: "Nunca he arriesgado perderlo todo por una decisión espontánea", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever confronted someone publicly about a private matter", de: "Ich hab noch nie jemanden öffentlich wegen einer privaten Angelegenheit konfrontiert", es: "Nunca he confrontado a alguien públicamente sobre un asunto privado", category: "embarrassing", subcategory: "public", intensity: 8, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 47
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever been blackmailed over something I did", de: "Ich wurde noch nie wegen etwas erpresst, das ich getan hab", es: "Nunca me han chantajeado por algo que hice", category: "confessions", subcategory: "secrets", intensity: 9, is_nsfw: false },
{ en: "Never have I ever cooked or prepared food while in a state I should not have been handling food in", de: "Ich hab noch nie Essen zubereitet, als ich in einem Zustand war, in dem ich kein Essen hätte anfassen sollen", es: "Nunca he cocinado o preparado comida en un estado en el que no debería haber estado manejando comida", category: "food", subcategory: "cooking", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something at a party that became a story people still tell", de: "Ich hab noch nie etwas auf einer Party gemacht, das zu einer Geschichte wurde, die Leute immer noch erzählen", es: "Nunca he hecho algo en una fiesta que se convirtió en una historia que la gente todavía cuenta", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever tripped someone on purpose and pretended it was an accident", de: "Ich hab noch nie jemandem absichtlich ein Bein gestellt und so getan, als wäre es ein Unfall gewesen", es: "Nunca le he puesto el pie a alguien a propósito y fingí que fue un accidente", category: "embarrassing", subcategory: "cringe", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been too afraid to eat alone in public", de: "Ich hatte noch nie so viel Angst, dass ich nicht alleine in der Öffentlichkeit essen konnte", es: "Nunca he tenido tanto miedo de comer solo en público", category: "food", subcategory: "habits", intensity: 9, is_nsfw: false },
{ en: "Never have I ever heard my name mentioned in a conversation I wasn't supposed to hear", de: "Ich hab noch nie meinen Namen in einem Gespräch gehört, das ich nicht hätte hören sollen", es: "Nunca he escuchado mi nombre en una conversación que no debí haber escuchado", category: "social", subcategory: "status", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the worst influence at a gathering", de: "Ich war noch nie der schlechteste Einfluss bei einem Treffen", es: "Nunca he sido la peor influencia en una reunión", category: "party", subcategory: "faux_pas", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a near-death experience that I caused myself", de: "Ich hatte noch nie ein Nahtoderlebnis, das ich selbst verursacht hab", es: "Nunca he tenido una experiencia cercana a la muerte que yo mismo causé", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been so embarrassed I avoided a specific place for months", de: "Mir war noch nie so peinlich, dass ich einen bestimmten Ort monatelang gemieden hab", es: "Nunca me ha dado tanta vergüenza que evité un lugar específico por meses", category: "embarrassing", subcategory: "public", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the reason a family dinner went silent", de: "Ich war noch nie der Grund, warum es bei einem Familienessen plötzlich still wurde", es: "Nunca he sido la razón por la que una cena familiar quedó en silencio", category: "social", subcategory: "awkward", intensity: 9, is_nsfw: false },
{ en: "Never have I ever harmed myself under the influence of substances", de: "Ich hab mir noch nie unter dem Einfluss von Substanzen selbst geschadet", es: "Nunca me he hecho daño bajo la influencia de sustancias", category: "risk", subcategory: "substances", intensity: 9, is_nsfw: false },
{ en: "Never have I ever committed a revenge act I later regretted", de: "Ich hab noch nie eine Racheaktion begangen, die ich später bereut hab", es: "Nunca he cometido un acto de venganza que luego lamenté", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been so drunk I accidentally confessed to my crush", de: "Ich war noch nie so betrunken, dass ich meinem Crush versehentlich meine Gefühle gestanden hab", es: "Nunca he estado tan borracho que accidentalmente le confesé a mi crush", category: "party", subcategory: "drinking", intensity: 9, is_nsfw: false },
{ en: "Never have I ever made someone's life harder just to make mine easier", de: "Ich hab noch nie jemandes Leben schwerer gemacht, nur um meins einfacher zu machen", es: "Nunca he hecho la vida de alguien más difícil solo para hacer la mía más fácil", category: "moral_gray", subcategory: "manipulation", intensity: 9, is_nsfw: false },
{ en: "Never have I ever walked in on something at a party I was not supposed to see", de: "Ich bin noch nie auf einer Party in etwas reingeplatzt, das ich nicht hätte sehen sollen", es: "Nunca he entrado a algo en una fiesta que no debí haber visto", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been rejected so harshly it changed how I approach relationships", de: "Ich wurde noch nie so hart abgewiesen, dass es verändert hat, wie ich an Beziehungen herangehe", es: "Nunca me han rechazado tan duramente que cambió cómo me acerco a las relaciones", category: "relationships", subcategory: "heartbreak", intensity: 9, is_nsfw: false },
{ en: "Never have I ever humiliated myself so badly at a meal I lost my appetite for days", de: "Ich hab mich noch nie so sehr bei einem Essen blamiert, dass ich tagelang keinen Appetit mehr hatte", es: "Nunca me he humillado tan mal en una comida que perdí el apetito por días", category: "food", subcategory: "gross", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been involved in an incident at a party that required emergency services", de: "Ich war noch nie an einem Vorfall auf einer Party beteiligt, bei dem der Rettungsdienst gerufen werden musste", es: "Nunca he estado involucrado en un incidente en una fiesta que requirió servicios de emergencia", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever played a prank that permanently damaged property", de: "Ich hab noch nie einen Streich gespielt, der dauerhaften Sachschaden verursacht hat", es: "Nunca he hecho una broma que dañó propiedad permanentemente", category: "risk", subcategory: "stunts", intensity: 9, is_nsfw: false },
{ en: "Never have I ever watched someone's reputation get destroyed and felt satisfied", de: "Ich hab noch nie zugesehen, wie jemandes Ruf zerstört wurde, und mich zufrieden gefühlt", es: "Nunca he visto la reputación de alguien destruirse y me sentí satisfecho", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 60
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever had a moment of clarity that showed me how much damage I've done", de: "Ich hatte noch nie einen Moment der Klarheit, der mir gezeigt hat, wie viel Schaden ich angerichtet hab", es: "Nunca he tenido un momento de claridad que me mostró cuánto daño he hecho", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever caused a public scene so bad that strangers intervened", de: "Ich hab noch nie eine so schlimme öffentliche Szene verursacht, dass Fremde eingegriffen haben", es: "Nunca he causado una escena pública tan mala que desconocidos intervinieron", category: "embarrassing", subcategory: "public", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been someone's reason for seeking professional help", de: "Ich war noch nie der Grund, warum jemand professionelle Hilfe gesucht hat", es: "Nunca he sido la razón por la que alguien buscó ayuda profesional", category: "relationships", subcategory: "boundaries", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had an encounter with food that left permanent emotional scars", de: "Ich hatte noch nie ein Erlebnis mit Essen, das dauerhafte emotionale Narben hinterlassen hat", es: "Nunca he tenido una experiencia con comida que dejó cicatrices emocionales permanentes", category: "food", subcategory: "gross", intensity: 10, is_nsfw: false },
{ en: "Never have I ever attended a party that changed my life in a way I can never undo", de: "Ich war noch nie auf einer Party, die mein Leben auf eine Weise verändert hat, die ich nie rückgängig machen kann", es: "Nunca he ido a una fiesta que cambió mi vida de una manera que nunca puedo deshacer", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been confronted with evidence of something I thought was buried forever", de: "Ich wurde noch nie mit Beweisen für etwas konfrontiert, von dem ich dachte, es wäre für immer begraben", es: "Nunca me han confrontado con evidencia de algo que pensé que estaba enterrado para siempre", category: "confessions", subcategory: "secrets", intensity: 10, is_nsfw: false },
{ en: "Never have I ever taken a risk so insane that I shouldn't be alive to tell the story", de: "Ich bin noch nie ein so wahnsinniges Risiko eingegangen, dass ich eigentlich nicht mehr leben sollte, um davon zu erzählen", es: "Nunca he tomado un riesgo tan loco que no debería estar vivo para contar la historia", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever carried guilt so heavy it affected my physical health", de: "Ich hab noch nie so schwere Schuld mit mir getragen, dass es meine körperliche Gesundheit beeinträchtigt hat", es: "Nunca he cargado con una culpa tan pesada que afectó mi salud física", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the villain in someone else's story and known they were right", de: "Ich war noch nie der Bösewicht in der Geschichte von jemand anderem und wusste, dass die Person Recht hatte", es: "Nunca he sido el villano en la historia de alguien más y supe que tenían razón", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever stood at a crossroads where every option would hurt someone", de: "Ich stand noch nie an einem Punkt, an dem jede Option jemanden verletzen würde", es: "Nunca he estado en una encrucijada donde cada opción lastimaría a alguien", category: "moral_gray", subcategory: "temptation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been in a situation where food was used as punishment", de: "Ich war noch nie in einer Situation, in der Essen als Strafe eingesetzt wurde", es: "Nunca he estado en una situación donde la comida fue usada como castigo", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever witnessed violence at a party and didn't report it", de: "Ich hab noch nie Gewalt auf einer Party gesehen und sie nicht gemeldet", es: "Nunca he presenciado violencia en una fiesta y no la reporté", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had my life threatened", de: "Mir wurde noch nie mit dem Tod gedroht", es: "Nunca me han amenazado de muerte", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the cause of someone's worst day", de: "Ich war noch nie die Ursache für den schlimmsten Tag von jemandem", es: "Nunca he sido la causa del peor día de alguien", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had an eating disorder that consumed years of my life", de: "Ich hatte noch nie eine Essstörung, die Jahre meines Lebens verschlungen hat", es: "Nunca he tenido un trastorno alimenticio que consumió años de mi vida", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been so embarrassed at a social event that I developed anxiety about future events", de: "Mir war noch nie auf einer Veranstaltung so peinlich, dass ich Angst vor zukünftigen Events entwickelt hab", es: "Nunca me ha dado tanta vergüenza en un evento social que desarrollé ansiedad sobre eventos futuros", category: "embarrassing", subcategory: "public", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had someone I trusted completely turn out to be someone entirely different", de: "Noch nie hat sich jemand, dem ich komplett vertraut hab, als jemand völlig anderes entpuppt", es: "Nunca alguien en quien confié completamente resultó ser alguien completamente diferente", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been at a party where someone's life was genuinely at risk", de: "Ich war noch nie auf einer Party, bei der jemandes Leben ernsthaft in Gefahr war", es: "Nunca he estado en una fiesta donde la vida de alguien estuvo genuinamente en riesgo", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever cooked or served something that made someone seriously ill", de: "Ich hab noch nie etwas gekocht oder serviert, das jemanden ernsthaft krank gemacht hat", es: "Nunca he cocinado o servido algo que enfermó seriamente a alguien", category: "food", subcategory: "cooking", intensity: 10, is_nsfw: false },
{ en: "Never have I ever destroyed someone's trust so completely they warned others about me", de: "Ich hab noch nie jemandes Vertrauen so komplett zerstört, dass die Person andere vor mir gewarnt hat", es: "Nunca he destruido la confianza de alguien tan completamente que advirtieron a otros sobre mí", category: "social", subcategory: "conflict", intensity: 10, is_nsfw: false },
{ en: "Never have I ever risked a lifelong friendship for a fleeting thrill", de: "Ich hab noch nie eine lebenslange Freundschaft für einen flüchtigen Kick riskiert", es: "Nunca he arriesgado una amistad de toda la vida por una emoción pasajera", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a panic attack triggered by a specific food smell", de: "Ich hatte noch nie eine Panikattacke, die durch einen bestimmten Essensgeruch ausgelöst wurde", es: "Nunca he tenido un ataque de pánico provocado por un olor específico de comida", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the one who cleared a room at a party just by what I said", de: "Ich war noch nie derjenige, der auf einer Party einen Raum leerte, nur durch das, was ich gesagt hab", es: "Nunca he sido el que vació un cuarto en una fiesta solo por lo que dije", category: "party", subcategory: "faux_pas", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been utterly humiliated in front of my family", de: "Ich wurde noch nie vor meiner Familie komplett gedemütigt", es: "Nunca me han humillado por completo frente a mi familia", category: "embarrassing", subcategory: "cringe", intensity: 10, is_nsfw: false },
{ en: "Never have I ever committed to a lie so deeply that the truth would collapse everything", de: "Ich hab mich noch nie so tief in eine Lüge verstrickt, dass die Wahrheit alles zum Einstürzen bringen würde", es: "Nunca me he comprometido tan profundamente con una mentira que la verdad haría colapsar todo", category: "confessions", subcategory: "dishonesty", intensity: 10, is_nsfw: false },
{ en: "Never have I ever lost someone permanently because of my pride", de: "Ich hab noch nie jemanden dauerhaft verloren, wegen meines Stolzes", es: "Nunca he perdido a alguien permanentemente por mi orgullo", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had my worst nightmare become reality", de: "Es ist noch nie passiert, dass mein schlimmster Albtraum Realität geworden ist", es: "Nunca se ha hecho realidad mi peor pesadilla", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
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
for (const q of BATCH6) {
  const key = q.en.toLowerCase().trim();
  if (seenEN.has(key)) { skipped++; console.log(`  SKIP: ${q.en.substring(0,50)}...`); continue; }
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
