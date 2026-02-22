#!/usr/bin/env npx tsx
/**
 * BATCH 5 — fill remaining 299 to reach 1600
 * Gaps: 4:1, 5:10, 6:27, 7:45, 8:56, 9:70, 10:90 = 299
 * Focus underrepresented cats: food(62), risk(94), party(95), embarrassing(107)
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

const BATCH5: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 4 — need 1
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever pretended I liked a gift I actually hated", de: "Ich hab noch nie so getan, als würde mir ein Geschenk gefallen, das ich eigentlich gehasst hab", es: "Nunca he fingido que me gustó un regalo que en realidad odié", category: "embarrassing", subcategory: "cringe", intensity: 4, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 5 — need 10
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever tried an extreme food challenge", de: "Ich hab noch nie eine extreme Food-Challenge gemacht", es: "Nunca he intentado un reto de comida extremo", category: "food", subcategory: "challenges", intensity: 5, is_nsfw: false },
{ en: "Never have I ever jumped off something dangerously high into water", de: "Ich bin noch nie von etwas gefährlich Hohem ins Wasser gesprungen", es: "Nunca he saltado de algo peligrosamente alto al agua", category: "risk", subcategory: "stunts", intensity: 5, is_nsfw: false },
{ en: "Never have I ever had a massive wardrobe malfunction in public", de: "Ich hatte noch nie eine massive Garderobenpanne in der Öffentlichkeit", es: "Nunca he tenido un accidente de vestuario masivo en público", category: "embarrassing", subcategory: "public", intensity: 5, is_nsfw: false },
{ en: "Never have I ever lied about my age to get into a club", de: "Ich hab noch nie über mein Alter gelogen, um in einen Club zu kommen", es: "Nunca he mentido sobre mi edad para entrar a un club", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever pretended to be someone's partner to help them escape a situation", de: "Ich hab noch nie so getan, als wäre ich jemandes Partner, um der Person aus einer Situation zu helfen", es: "Nunca he fingido ser la pareja de alguien para ayudarle a escapar de una situación", category: "social", subcategory: "white_lies", intensity: 5, is_nsfw: false },
{ en: "Never have I ever mixed drinks that absolutely should not be mixed", de: "Ich hab noch nie Getränke gemischt, die man definitiv nicht mischen sollte", es: "Nunca he mezclado bebidas que definitivamente no se deberían mezclar", category: "food", subcategory: "drunk_eating", intensity: 5, is_nsfw: false },
{ en: "Never have I ever gone to a restaurant alone and pretended I was waiting for someone", de: "Ich war noch nie allein in einem Restaurant und hab so getan, als würde ich auf jemanden warten", es: "Nunca he ido a un restaurante solo y fingí que estaba esperando a alguien", category: "embarrassing", subcategory: "public", intensity: 5, is_nsfw: false },
{ en: "Never have I ever gotten a piercing on impulse", de: "Ich hab mir noch nie spontan ein Piercing stechen lassen", es: "Nunca me he puesto un piercing por impulso", category: "risk", subcategory: "reckless", intensity: 5, is_nsfw: false },
{ en: "Never have I ever broken something at a friend's house and hid it", de: "Ich hab noch nie etwas bei einem Freund kaputtgemacht und es versteckt", es: "Nunca he roto algo en casa de un amigo y lo escondí", category: "confessions", subcategory: "dishonesty", intensity: 5, is_nsfw: false },
{ en: "Never have I ever eaten something past its expiration date and hoped for the best", de: "Ich hab noch nie etwas Abgelaufenes gegessen und auf das Beste gehofft", es: "Nunca he comido algo pasado de fecha y esperé lo mejor", category: "food", subcategory: "gross", intensity: 5, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 6 — need 27
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever woken up in a place with no memory of how I got there", de: "Ich bin noch nie an einem Ort aufgewacht, ohne zu wissen, wie ich dahin gekommen bin", es: "Nunca me he despertado en un lugar sin recordar cómo llegué ahí", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever purposefully made someone jealous", de: "Ich hab noch nie absichtlich jemanden eifersüchtig gemacht", es: "Nunca he hecho a alguien celoso a propósito", category: "relationships", subcategory: "flirting", intensity: 6, is_nsfw: false },
{ en: "Never have I ever taken something from a hotel that wasn't free", de: "Ich hab noch nie etwas aus einem Hotel mitgenommen, das nicht gratis war", es: "Nunca me he llevado algo de un hotel que no era gratis", category: "risk", subcategory: "reckless", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been caught checking someone out by the person themselves", de: "Ich wurde noch nie dabei erwischt, wie ich jemanden gecheckt hab – und zwar von der Person selbst", es: "Nunca me han cachado viendo a alguien y fue esa misma persona", category: "embarrassing", subcategory: "caught", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been a bad influence on someone younger", de: "Ich war noch nie ein schlechter Einfluss auf jemand Jüngeres", es: "Nunca he sido una mala influencia para alguien más joven", category: "moral_gray", subcategory: "temptation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had a meal so bad I secretly threw it away", de: "Ich hatte noch nie ein Essen, das so schlecht war, dass ich es heimlich weggeworfen hab", es: "Nunca he tenido una comida tan mala que la tiré a escondidas", category: "food", subcategory: "cooking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been in a fight with a friend that lasted months", de: "Ich hatte noch nie einen Streit mit einem Freund, der Monate gedauert hat", es: "Nunca he tenido una pelea con un amigo que duró meses", category: "social", subcategory: "conflict", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had a one-night stand I never told anyone about", de: "Ich hatte noch nie einen One-Night-Stand, von dem ich niemandem erzählt hab", es: "Nunca he tenido una aventura de una noche de la que no le conté a nadie", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever accepted a dare that left a scar", de: "Ich hab noch nie eine Mutprobe angenommen, die eine Narbe hinterlassen hat", es: "Nunca he aceptado un reto que me dejó una cicatriz", category: "risk", subcategory: "bets", intensity: 6, is_nsfw: false },
{ en: "Never have I ever lost all my money in one night", de: "Ich hab noch nie all mein Geld in einer Nacht verloren", es: "Nunca he perdido todo mi dinero en una noche", category: "risk", subcategory: "reckless", intensity: 6, is_nsfw: false },
{ en: "Never have I ever walked out of a job without giving notice", de: "Ich hab noch nie einen Job gekündigt, ohne vorher Bescheid zu sagen", es: "Nunca me he ido de un trabajo sin avisar", category: "confessions", subcategory: "dishonesty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever gotten a ride home from a complete stranger after a party", de: "Ich bin noch nie nach einer Party bei einem kompletten Fremden mitgefahren", es: "Nunca me ha llevado un completo desconocido a casa después de una fiesta", category: "party", subcategory: "wild_nights", intensity: 6, is_nsfw: false },
{ en: "Never have I ever gone through someone's phone without their knowledge", de: "Ich hab noch nie heimlich jemandes Handy durchsucht", es: "Nunca he revisado el teléfono de alguien sin que lo supiera", category: "confessions", subcategory: "snooping", intensity: 6, is_nsfw: false },
{ en: "Never have I ever competed with a friend over the same person", de: "Ich hab noch nie mit einem Freund um dieselbe Person gewetteifert", es: "Nunca he competido con un amigo por la misma persona", category: "relationships", subcategory: "situationship", intensity: 6, is_nsfw: false },
{ en: "Never have I ever stress-eaten an entire pizza at 3 AM", de: "Ich hab noch nie aus Frust um 3 Uhr morgens eine ganze Pizza gegessen", es: "Nunca me he comido una pizza entera a las 3 de la mañana por estrés", category: "food", subcategory: "drunk_eating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever pretended to be sick to avoid a social obligation", de: "Ich hab mich noch nie krank gestellt, um eine soziale Verpflichtung zu umgehen", es: "Nunca he fingido estar enfermo para evitar una obligación social", category: "social", subcategory: "white_lies", intensity: 6, is_nsfw: false },
{ en: "Never have I ever dropped food on the floor at a party, picked it up, and served it to someone", de: "Ich hab noch nie auf einer Party Essen auf den Boden fallen lassen, es aufgehoben und jemandem serviert", es: "Nunca se me ha caído comida al piso en una fiesta, la levanté y se la serví a alguien", category: "food", subcategory: "gross", intensity: 6, is_nsfw: false },
{ en: "Never have I ever made a scene leaving a party", de: "Ich hab noch nie eine Szene gemacht, als ich eine Party verlassen hab", es: "Nunca he armado una escena al irme de una fiesta", category: "party", subcategory: "faux_pas", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had a dare go so wrong someone got hurt", de: "Ich hab noch nie erlebt, dass eine Mutprobe so schiefging, dass sich jemand verletzt hat", es: "Nunca he visto un reto salir tan mal que alguien se lastimó", category: "risk", subcategory: "bets", intensity: 6, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 7 — need 45
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever driven under the influence", de: "Ich bin noch nie unter Einfluss gefahren", es: "Nunca he manejado bajo la influencia", category: "risk", subcategory: "driving", intensity: 7, is_nsfw: false },
{ en: "Never have I ever hooked up with someone at a funeral or wake", de: "Ich hab mich noch nie auf einer Beerdigung oder Trauerfeier mit jemandem eingelassen", es: "Nunca me he liado con alguien en un funeral o velorio", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever been so angry I destroyed something I owned", de: "Ich war noch nie so wütend, dass ich etwas Eigenes zerstört hab", es: "Nunca he estado tan enojado que destruí algo mío", category: "confessions", subcategory: "anger", intensity: 7, is_nsfw: false },
{ en: "Never have I ever used someone's vulnerability against them", de: "Ich hab noch nie jemandes Verletzlichkeit gegen die Person verwendet", es: "Nunca he usado la vulnerabilidad de alguien en su contra", category: "moral_gray", subcategory: "manipulation", intensity: 7, is_nsfw: false },
{ en: "Never have I ever kissed my best friend's ex", de: "Ich hab noch nie den Ex meines besten Freundes geküsst", es: "Nunca he besado al ex de mi mejor amigo", category: "relationships", subcategory: "forbidden", intensity: 7, is_nsfw: false },
{ en: "Never have I ever lied to the police", de: "Ich hab noch nie die Polizei angelogen", es: "Nunca le he mentido a la policía", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever started eating something before paying for it at a store", de: "Ich hab noch nie im Laden angefangen etwas zu essen, bevor ich es bezahlt hab", es: "Nunca he empezado a comer algo en una tienda antes de pagarlo", category: "food", subcategory: "habits", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had a panic attack at a social event", de: "Ich hatte noch nie eine Panikattacke bei einer Veranstaltung", es: "Nunca he tenido un ataque de pánico en un evento social", category: "deep", subcategory: "mental_health", intensity: 7, is_nsfw: false },
{ en: "Never have I ever stayed in a toxic friendship out of fear", de: "Ich war noch nie aus Angst in einer toxischen Freundschaft geblieben", es: "Nunca me he quedado en una amistad tóxica por miedo", category: "social", subcategory: "status", intensity: 7, is_nsfw: false },
{ en: "Never have I ever broken a promise that actually mattered", de: "Ich hab noch nie ein Versprechen gebrochen, das wirklich wichtig war", es: "Nunca he roto una promesa que realmente importaba", category: "moral_gray", subcategory: "loyalty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been in a compromising position when someone walked in", de: "Ich war noch nie in einer kompromittierenden Situation, als jemand reinkam", es: "Nunca he estado en una posición comprometedora cuando alguien entró", category: "embarrassing", subcategory: "caught", intensity: 7, is_nsfw: true },
{ en: "Never have I ever woken up next to someone whose name I didn't know", de: "Ich bin noch nie neben jemandem aufgewacht, dessen Namen ich nicht kannte", es: "Nunca me he despertado junto a alguien cuyo nombre no sabía", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever done something at a party I had to apologize for the next day", de: "Ich hab noch nie etwas auf einer Party gemacht, für das ich mich am nächsten Tag entschuldigen musste", es: "Nunca he hecho algo en una fiesta por lo que tuve que disculparme al día siguiente", category: "party", subcategory: "faux_pas", intensity: 7, is_nsfw: false },
{ en: "Never have I ever eaten so much I couldn't move", de: "Ich hab noch nie so viel gegessen, dass ich mich nicht mehr bewegen konnte", es: "Nunca he comido tanto que no me podía mover", category: "food", subcategory: "gross", intensity: 7, is_nsfw: false },
{ en: "Never have I ever deleted messages before someone could see them", de: "Ich hab noch nie Nachrichten gelöscht, bevor jemand sie sehen konnte", es: "Nunca he borrado mensajes antes de que alguien los viera", category: "confessions", subcategory: "snooping", intensity: 7, is_nsfw: false },
{ en: "Never have I ever given an ultimatum I wasn't prepared to follow through on", de: "Ich hab noch nie ein Ultimatum gestellt, das ich nicht bereit war durchzuziehen", es: "Nunca he dado un ultimátum que no estaba preparado para cumplir", category: "relationships", subcategory: "boundaries", intensity: 7, is_nsfw: false },
{ en: "Never have I ever faked a reference for a job", de: "Ich hab noch nie eine Referenz für einen Job gefälscht", es: "Nunca he falsificado una referencia para un trabajo", category: "confessions", subcategory: "dishonesty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever pretended to be sober when I clearly wasn't", de: "Ich hab noch nie so getan, als wäre ich nüchtern, obwohl ich es eindeutig nicht war", es: "Nunca he fingido estar sobrio cuando claramente no lo estaba", category: "party", subcategory: "drinking", intensity: 7, is_nsfw: false },
{ en: "Never have I ever watched someone embarrass themselves and said nothing", de: "Ich hab noch nie zugesehen, wie sich jemand blamiert hat, und nichts gesagt", es: "Nunca he visto a alguien pasar vergüenza y no dije nada", category: "social", subcategory: "awkward", intensity: 7, is_nsfw: false },
{ en: "Never have I ever taken food off someone's plate without asking", de: "Ich hab noch nie jemandem Essen vom Teller genommen, ohne zu fragen", es: "Nunca he tomado comida del plato de alguien sin preguntar", category: "food", subcategory: "habits", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been the person who ruined the group photo", de: "Ich war noch nie die Person, die das Gruppenfoto ruiniert hat", es: "Nunca he sido la persona que arruinó la foto grupal", category: "embarrassing", subcategory: "cringe", intensity: 7, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 56
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever driven away from someone who needed help", de: "Ich bin noch nie von jemandem weggefahren, der Hilfe brauchte", es: "Nunca me he alejado de alguien que necesitaba ayuda", category: "moral_gray", subcategory: "dark", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had a hookup that my friend group would never approve of", de: "Ich hatte noch nie einen Hookup, den mein Freundeskreis niemals gutheißen würde", es: "Nunca he tenido un ligue que mi grupo de amigos nunca aprobaría", category: "sexual", subcategory: "hookups", intensity: 8, is_nsfw: true },
{ en: "Never have I ever carried a secret for years that still weighs on me", de: "Ich hab noch nie ein Geheimnis jahrelang mit mir herumgetragen, das mich immer noch belastet", es: "Nunca he cargado un secreto por años que todavía me pesa", category: "confessions", subcategory: "secrets", intensity: 8, is_nsfw: false },
{ en: "Never have I ever cut someone off completely and pretended they never existed", de: "Ich hab noch nie jemanden komplett geghostet und so getan, als hätte die Person nie existiert", es: "Nunca he cortado a alguien completamente y fingí que nunca existió", category: "relationships", subcategory: "heartbreak", intensity: 8, is_nsfw: false },
{ en: "Never have I ever eaten something that made me violently ill and lied about how it happened", de: "Ich hab noch nie etwas gegessen, das mich heftig krank gemacht hat, und gelogen, wie es passiert ist", es: "Nunca he comido algo que me enfermó gravemente y mentí sobre cómo pasó", category: "food", subcategory: "gross", intensity: 8, is_nsfw: false },
{ en: "Never have I ever nearly destroyed a friendship over pride", de: "Ich hab noch nie fast eine Freundschaft zerstört, weil ich zu stolz war", es: "Nunca he casi destruido una amistad por orgullo", category: "social", subcategory: "conflict", intensity: 8, is_nsfw: false },
{ en: "Never have I ever sabotaged someone's chances at something", de: "Ich hab noch nie jemandes Chancen auf etwas sabotiert", es: "Nunca he saboteado las oportunidades de alguien", category: "moral_gray", subcategory: "manipulation", intensity: 8, is_nsfw: false },
{ en: "Never have I ever run from the police", de: "Ich bin noch nie vor der Polizei weggerannt", es: "Nunca he huido de la policía", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever woken up in a hospital after a night out", de: "Ich bin noch nie nach einer Partynacht im Krankenhaus aufgewacht", es: "Nunca me he despertado en un hospital después de una noche de fiesta", category: "party", subcategory: "wild_nights", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been someone's secret", de: "Ich war noch nie jemandes Geheimnis", es: "Nunca he sido el secreto de alguien", category: "relationships", subcategory: "situationship", intensity: 8, is_nsfw: false },
{ en: "Never have I ever made a bet I knew the other person would lose", de: "Ich hab noch nie eine Wette abgeschlossen, von der ich wusste, dass die andere Person verlieren würde", es: "Nunca he hecho una apuesta que sabía que la otra persona perdería", category: "risk", subcategory: "bets", intensity: 8, is_nsfw: false },
{ en: "Never have I ever ghosted someone after things got serious", de: "Ich hab noch nie jemanden geghostet, nachdem es ernst wurde", es: "Nunca he dejado de contestarle a alguien después de que las cosas se pusieron serias", category: "relationships", subcategory: "heartbreak", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had food poisoning and blamed it on someone else", de: "Ich hatte noch nie eine Lebensmittelvergiftung und hab jemand anderem die Schuld gegeben", es: "Nunca he tenido intoxicación alimentaria y le eché la culpa a alguien más", category: "food", subcategory: "gross", intensity: 8, is_nsfw: false },
{ en: "Never have I ever participated in something shady to fit in", de: "Ich hab noch nie bei etwas Zwielichtigem mitgemacht, nur um dazuzugehören", es: "Nunca he participado en algo turbio solo para encajar", category: "social", subcategory: "people_pleasing", intensity: 8, is_nsfw: false },
{ en: "Never have I ever left someone stranded with no way home", de: "Ich hab noch nie jemanden ohne Heimweg sitzen lassen", es: "Nunca he dejado a alguien varado sin forma de llegar a casa", category: "moral_gray", subcategory: "loyalty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever explored a sexual fantasy that surprised even me", de: "Ich hab noch nie eine sexuelle Fantasie ausgelebt, die sogar mich überrascht hat", es: "Nunca he explorado una fantasía sexual que me sorprendió hasta a mí", category: "sexual", subcategory: "kinks", intensity: 8, is_nsfw: true },
{ en: "Never have I ever been someone else's alibi for something illegal", de: "Ich war noch nie jemandes Alibi für etwas Illegales", es: "Nunca he sido la coartada de alguien para algo ilegal", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever stayed at a party way past the point of comfort", de: "Ich bin noch nie auf einer Party geblieben, obwohl ich mich schon lange nicht mehr wohl gefühlt hab", es: "Nunca me he quedado en una fiesta mucho después de sentirme cómodo", category: "party", subcategory: "wild_nights", intensity: 8, is_nsfw: false },
{ en: "Never have I ever intentionally humiliated someone in public", de: "Ich hab noch nie jemanden absichtlich in der Öffentlichkeit bloßgestellt", es: "Nunca he humillado a alguien intencionalmente en público", category: "embarrassing", subcategory: "cringe", intensity: 8, is_nsfw: false },
{ en: "Never have I ever hidden a relationship from my family", de: "Ich hab noch nie eine Beziehung vor meiner Familie verheimlicht", es: "Nunca he escondido una relación de mi familia", category: "relationships", subcategory: "forbidden", intensity: 8, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 70
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever been the reason someone started therapy", de: "Ich war noch nie der Grund, warum jemand eine Therapie angefangen hat", es: "Nunca he sido la razón por la que alguien empezó terapia", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever felt so lonely in a crowd that I had to leave", de: "Ich hab mich noch nie so einsam inmitten von Leuten gefühlt, dass ich gehen musste", es: "Nunca me he sentido tan solo en una multitud que tuve que irme", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever used someone's feelings for me to get what I wanted", de: "Ich hab noch nie die Gefühle von jemandem für mich ausgenutzt, um zu bekommen, was ich wollte", es: "Nunca he usado los sentimientos de alguien por mí para obtener lo que quería", category: "moral_gray", subcategory: "manipulation", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been unable to look at myself in the mirror after something I did", de: "Ich konnte noch nie nach etwas, das ich getan hab, in den Spiegel schauen", es: "Nunca he sido incapaz de mirarme al espejo después de algo que hice", category: "deep", subcategory: "regret", intensity: 9, is_nsfw: false },
{ en: "Never have I ever risked someone else's safety for a thrill", de: "Ich hab noch nie die Sicherheit einer anderen Person für einen Kick riskiert", es: "Nunca he arriesgado la seguridad de alguien por una emoción", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },
{ en: "Never have I ever hooked up with someone to get back at their ex", de: "Ich hab mich noch nie mit jemandem eingelassen, um es dem Ex heimzuzahlen", es: "Nunca me he liado con alguien para vengarme de su ex", category: "sexual", subcategory: "hookups", intensity: 9, is_nsfw: true },
{ en: "Never have I ever felt nothing when someone told me I hurt them", de: "Ich hab noch nie nichts empfunden, als mir jemand gesagt hat, dass ich die Person verletzt hab", es: "Nunca he sentido nada cuando alguien me dijo que lo lastimé", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever eaten something that someone else touched in a way I'd rather not think about", de: "Ich hab noch nie etwas gegessen, das jemand auf eine Art angefasst hat, über die ich lieber nicht nachdenken will", es: "Nunca he comido algo que alguien tocó de una manera en la que prefiero no pensar", category: "food", subcategory: "gross", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a complete mental breakdown at an event", de: "Ich hatte noch nie einen kompletten mentalen Zusammenbruch bei einer Veranstaltung", es: "Nunca he tenido un colapso mental completo en un evento", category: "deep", subcategory: "mental_health", intensity: 9, is_nsfw: false },
{ en: "Never have I ever stayed in a relationship knowing I was the problem", de: "Ich war noch nie in einer Beziehung geblieben, obwohl ich wusste, dass ich das Problem bin", es: "Nunca me he quedado en una relación sabiendo que yo era el problema", category: "relationships", subcategory: "boundaries", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something I promised myself I'd never do again", de: "Ich hab noch nie etwas getan, von dem ich mir geschworen hab, es nie wieder zu tun", es: "Nunca he hecho algo que me prometí que nunca volvería a hacer", category: "confessions", subcategory: "shame", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the reason a party ended early because of a fight", de: "Ich war noch nie der Grund, warum eine Party wegen einer Schlägerei früher aufgehört hat", es: "Nunca he sido la razón por la que una fiesta terminó temprano por una pelea", category: "party", subcategory: "faux_pas", intensity: 9, is_nsfw: false },
{ en: "Never have I ever looked through someone's private messages and found something that destroyed me", de: "Ich hab noch nie jemandes private Nachrichten gelesen und etwas gefunden, das mich zerstört hat", es: "Nunca he revisado los mensajes privados de alguien y encontré algo que me destruyó", category: "confessions", subcategory: "snooping", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been afraid of what I'm capable of when pushed too far", de: "Ich hatte noch nie Angst davor, wozu ich fähig bin, wenn man mich zu weit treibt", es: "Nunca he tenido miedo de lo que soy capaz cuando me llevan demasiado lejos", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever seen a side of someone I love that made me question everything", de: "Ich hab noch nie eine Seite an jemandem, den ich liebe, gesehen, die mich alles hat hinterfragen lassen", es: "Nunca he visto un lado de alguien que amo que me hizo cuestionar todo", category: "relationships", subcategory: "heartbreak", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something so embarrassing I had to move social circles", de: "Ich hab noch nie etwas so Peinliches gemacht, dass ich meinen Freundeskreis wechseln musste", es: "Nunca he hecho algo tan vergonzoso que tuve que cambiar de círculo social", category: "embarrassing", subcategory: "public", intensity: 9, is_nsfw: false },
{ en: "Never have I ever kept going to a party after something traumatic happened there", de: "Ich bin noch nie weiter auf einer Party geblieben, nachdem dort etwas Traumatisches passiert ist", es: "Nunca he seguido en una fiesta después de que algo traumático pasó ahí", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever eaten someone else's clearly labeled food from a shared fridge and never admitted it", de: "Ich hab noch nie das deutlich beschriftete Essen von jemand anderem aus einem gemeinsamen Kühlschrank gegessen und es nie zugegeben", es: "Nunca he comido la comida claramente etiquetada de alguien de un refrigerador compartido y nunca lo admití", category: "food", subcategory: "habits", intensity: 9, is_nsfw: false },
{ en: "Never have I ever let someone take the blame for something I did", de: "Ich hab noch nie jemand anderen die Schuld für etwas tragen lassen, das ich getan hab", es: "Nunca he dejado que alguien cargara con la culpa de algo que hice yo", category: "moral_gray", subcategory: "loyalty", intensity: 9, is_nsfw: false },
{ en: "Never have I ever realized too late that I was the toxic one in a group", de: "Ich hab noch nie zu spät realisiert, dass ich die toxische Person in einer Gruppe war", es: "Nunca me he dado cuenta demasiado tarde de que yo era la persona tóxica en un grupo", category: "social", subcategory: "conflict", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been physically aggressive under the influence of substances", de: "Ich war noch nie unter dem Einfluss von Substanzen körperlich aggressiv", es: "Nunca he sido físicamente agresivo bajo la influencia de sustancias", category: "risk", subcategory: "substances", intensity: 9, is_nsfw: false },
{ en: "Never have I ever stared into the void wondering if anything actually matters", de: "Ich hab noch nie ins Nichts gestarrt und mich gefragt, ob irgendetwas überhaupt eine Rolle spielt", es: "Nunca me he quedado mirando al vacío preguntándome si algo realmente importa", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever used food as emotional currency — withholding it, bingeing it, or weaponizing it", de: "Ich hab noch nie Essen als emotionale Währung benutzt — vorenthalten, Bingen, oder als Waffe eingesetzt", es: "Nunca he usado la comida como moneda emocional — reteniéndola, atracándome, o usándola como arma", category: "food", subcategory: "habits", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a sexual encounter that I consented to but still regret deeply", de: "Ich hatte noch nie ein sexuelles Erlebnis, dem ich zugestimmt hab, das ich aber zutiefst bereue", es: "Nunca he tenido un encuentro sexual al que consentí pero que lamento profundamente", category: "sexual", subcategory: "boundaries", intensity: 9, is_nsfw: true },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 90
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever hurt someone so badly they cut me off forever", de: "Ich hab noch nie jemanden so sehr verletzt, dass die Person mich für immer aus ihrem Leben gestrichen hat", es: "Nunca he lastimado a alguien tan mal que me eliminó de su vida para siempre", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever felt genuinely unlovable", de: "Ich hab mich noch nie wirklich für nicht liebenswert gehalten", es: "Nunca me he sentido genuinamente imposible de amar", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been so ashamed of something that I physically cringe when I remember it", de: "Ich hab mich noch nie so sehr für etwas geschämt, dass ich jedes Mal zusammenzucke, wenn ich daran denke", es: "Nunca me he avergonzado tanto de algo que me da un escalofrío físico cuando lo recuerdo", category: "embarrassing", subcategory: "cringe", intensity: 10, is_nsfw: false },
{ en: "Never have I ever discovered my partner was living a completely separate life", de: "Ich hab noch nie herausgefunden, dass mein Partner ein komplett separates Leben geführt hat", es: "Nunca he descubierto que mi pareja llevaba una vida completamente separada", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever made a promise to a dying person that I didn't keep", de: "Ich hab noch nie einem sterbenden Menschen ein Versprechen gegeben, das ich nicht gehalten hab", es: "Nunca le he hecho una promesa a una persona moribunda que no cumplí", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been afraid of someone I used to love", de: "Ich hatte noch nie Angst vor jemandem, den ich einmal geliebt hab", es: "Nunca le he tenido miedo a alguien que alguna vez amé", category: "relationships", subcategory: "boundaries", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a breakdown so severe I wasn't functional for days", de: "Ich hatte noch nie einen so schweren Zusammenbruch, dass ich tagelang nicht funktionsfähig war", es: "Nunca he tenido un colapso tan severo que no fui funcional por días", category: "deep", subcategory: "mental_health", intensity: 10, is_nsfw: false },
{ en: "Never have I ever deliberately crashed a relationship because I didn't feel worthy of it", de: "Ich hab noch nie absichtlich eine Beziehung zerstört, weil ich mich ihrer nicht würdig gefühlt hab", es: "Nunca he destruido deliberadamente una relación porque no me sentía digno de ella", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever hidden an addiction from the person closest to me", de: "Ich hab noch nie eine Sucht vor der Person versteckt, die mir am nächsten steht", es: "Nunca he escondido una adicción de la persona más cercana a mí", category: "risk", subcategory: "substances", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been in a sexual situation so intense I still have flashbacks", de: "Ich war noch nie in einer sexuellen Situation, die so intensiv war, dass ich immer noch Flashbacks habe", es: "Nunca he estado en una situación sexual tan intensa que todavía tengo flashbacks", category: "sexual", subcategory: "kinks", intensity: 10, is_nsfw: true },
{ en: "Never have I ever watched someone self-destruct and done nothing", de: "Ich hab noch nie zugesehen, wie sich jemand selbst zerstört hat, und nichts getan", es: "Nunca he visto a alguien autodestruirse y no hice nada", category: "moral_gray", subcategory: "loyalty", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been involved in something that still haunts me when the room goes quiet", de: "Ich war noch nie an etwas beteiligt, das mich immer noch verfolgt, wenn es still wird", es: "Nunca he estado involucrado en algo que aún me persigue cuando el cuarto se queda en silencio", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever allowed fear to make me complicit in something I knew was wrong", de: "Ich hab noch nie zugelassen, dass Angst mich zum Komplizen in etwas gemacht hat, von dem ich wusste, dass es falsch war", es: "Nunca he permitido que el miedo me hiciera cómplice de algo que sabía que estaba mal", category: "moral_gray", subcategory: "temptation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever starved myself deliberately", de: "Ich hab noch nie absichtlich gehungert", es: "Nunca me he muerto de hambre deliberadamente", category: "food", subcategory: "habits", intensity: 10, is_nsfw: false },
{ en: "Never have I ever completely lost my sense of self", de: "Ich hab noch nie mein Selbstgefühl komplett verloren", es: "Nunca he perdido completamente mi sentido de identidad", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever ruined someone's reputation deliberately", de: "Ich hab noch nie absichtlich den Ruf von jemandem ruiniert", es: "Nunca he arruinado la reputación de alguien deliberadamente", category: "moral_gray", subcategory: "manipulation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had an experience that made me question my own morality", de: "Ich hatte noch nie ein Erlebnis, das mich dazu gebracht hat, meine eigene Moral zu hinterfragen", es: "Nunca he tenido una experiencia que me hizo cuestionar mi propia moralidad", category: "moral_gray", subcategory: "temptation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever found out something about myself that terrified me", de: "Ich hab noch nie etwas über mich herausgefunden, das mich erschreckt hat", es: "Nunca he descubierto algo sobre mí que me aterró", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever realized I became the person I always feared becoming", de: "Ich hab noch nie realisiert, dass ich die Person geworden bin, die zu werden ich immer befürchtet hatte", es: "Nunca me he dado cuenta de que me convertí en la persona que siempre temí ser", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a food-related experience that gave me lasting anxiety", de: "Ich hatte noch nie ein Essenserlebnis, das mir dauerhafte Angst bereitet hat", es: "Nunca he tenido una experiencia con comida que me dejó ansiedad duradera", category: "food", subcategory: "gross", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been at a party where something happened that should have been reported", de: "Ich war noch nie auf einer Party, wo etwas passiert ist, das hätte gemeldet werden sollen", es: "Nunca he estado en una fiesta donde pasó algo que debió haberse reportado", category: "party", subcategory: "wild_nights", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been told I was someone's biggest regret", de: "Mir wurde noch nie gesagt, dass ich jemandes größter Fehler bin", es: "Nunca me han dicho que fui el mayor arrepentimiento de alguien", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever used physical intimacy to fill an emotional void", de: "Ich hab noch nie körperliche Intimität genutzt, um eine emotionale Leere zu füllen", es: "Nunca he usado la intimidad física para llenar un vacío emocional", category: "sexual", subcategory: "boundaries", intensity: 10, is_nsfw: true },
{ en: "Never have I ever felt so trapped in my social circle that I wanted to reinvent myself completely", de: "Ich hab mich noch nie so gefangen in meinem sozialen Umfeld gefühlt, dass ich mich komplett neu erfinden wollte", es: "Nunca me he sentido tan atrapado en mi círculo social que quise reinventarme por completo", category: "social", subcategory: "status", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a secret I know I'll never confess even on my deathbed", de: "Ich hatte noch nie ein Geheimnis, von dem ich weiß, dass ich es nicht einmal auf dem Sterbebett gestehen werde", es: "Nunca he tenido un secreto que sé que nunca confesaré ni en mi lecho de muerte", category: "confessions", subcategory: "secrets", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been shocked by my own cruelty", de: "Ich war noch nie schockiert über meine eigene Grausamkeit", es: "Nunca me ha sorprendido mi propia crueldad", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever endangered someone's life because of my recklessness", de: "Ich hab noch nie das Leben von jemandem durch meine Rücksichtslosigkeit gefährdet", es: "Nunca he puesto en peligro la vida de alguien por mi imprudencia", category: "risk", subcategory: "reckless", intensity: 10, is_nsfw: false },
{ en: "Never have I ever realized my biggest fear about myself was actually true", de: "Ich hab noch nie realisiert, dass meine größte Angst über mich selbst tatsächlich wahr war", es: "Nunca me he dado cuenta de que mi mayor miedo sobre mí mismo era en realidad cierto", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever experienced something that permanently changed how I see humanity", de: "Ich hab noch nie etwas erlebt, das permanent verändert hat, wie ich die Menschheit sehe", es: "Nunca he experimentado algo que cambió permanentemente cómo veo a la humanidad", category: "deep", subcategory: "growth", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been the person everyone trusted who was secretly falling apart", de: "Ich war noch nie die Person, der alle vertrauen, die aber insgeheim auseinanderfällt", es: "Nunca he sido la persona en la que todos confían pero que secretamente se desmorona", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
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
for (const q of BATCH5) {
  const key = q.en.toLowerCase().trim();
  if (seenEN.has(key)) { skipped++; continue; }
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

console.log(`Base: ${base.length} | Skipped: ${skipped} | Added: ${added} | Total: ${deduped.length}`);

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
