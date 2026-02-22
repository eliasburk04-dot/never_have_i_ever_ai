#!/usr/bin/env npx tsx
/**
 * BATCH 2 — Fill remaining gaps to reach 1600 total
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

const BATCH2: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 2 — need 20 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever screamed at a horror movie and someone judged me", de: "Ich hab noch nie bei einem Horrorfilm geschrien und jemand hat mich dafür verurteilt", es: "Nunca he gritado en una película de terror y alguien me juzgó", category: "embarrassing", subcategory: "public", intensity: 2, is_nsfw: false },
{ en: "Never have I ever accidentally walked in on someone", de: "Ich bin noch nie versehentlich bei jemandem reingeplatzt", es: "Nunca he entrado sin querer cuando alguien estaba ocupado", category: "embarrassing", subcategory: "caught", intensity: 2, is_nsfw: false },
{ en: "Never have I ever been caught checking someone out", de: "Ich wurde noch nie erwischt, wie ich jemanden gecheckt hab", es: "Nunca me han cachado viendo a alguien", category: "embarrassing", subcategory: "caught", intensity: 2, is_nsfw: false },
{ en: "Never have I ever eaten a meal I made and pretended it tasted good", de: "Ich hab noch nie ein Essen gegessen, das ich selbst gemacht hab, und so getan, als wäre es gut", es: "Nunca he comido algo que preparé y fingí que sabía bien", category: "food", subcategory: "cooking", intensity: 2, is_nsfw: false },
{ en: "Never have I ever avoided a coworker in the hallway", de: "Ich bin noch nie einem Arbeitskollegen auf dem Flur ausgewichen", es: "Nunca he evitado a un compañero de trabajo en el pasillo", category: "social", subcategory: "awkward", intensity: 2, is_nsfw: false },
{ en: "Never have I ever felt guilty for enjoying something basic", de: "Ich hab mich noch nie schuldig gefühlt, weil ich etwas Simples genossen hab", es: "Nunca me he sentido culpable por disfrutar algo básico", category: "confessions", subcategory: "guilt", intensity: 2, is_nsfw: false },
{ en: "Never have I ever pretended to like a song everyone else liked", de: "Ich hab noch nie so getan, als würde mir ein Song gefallen, den alle anderen mochten", es: "Nunca he fingido que me gusta una canción que a todos les gustaba", category: "social", subcategory: "people_pleasing", intensity: 2, is_nsfw: false },
{ en: "Never have I ever tripped and played it off like nothing happened", de: "Ich bin noch nie gestolpert und hab so getan, als wäre nichts passiert", es: "Nunca me he tropezado y fingí que nada pasó", category: "embarrassing", subcategory: "public", intensity: 2, is_nsfw: false },
{ en: "Never have I ever binged an entire season in one day", de: "Ich hab noch nie eine ganze Staffel an einem Tag durchgebinget", es: "Nunca he visto una temporada entera en un día", category: "social", subcategory: "habits", intensity: 2, is_nsfw: false },
{ en: "Never have I ever typed a long reply and then deleted it", de: "Ich hab noch nie eine lange Antwort getippt und sie dann gelöscht", es: "Nunca he escrito una respuesta larga y luego la borré", category: "social", subcategory: "online", intensity: 2, is_nsfw: false },
{ en: "Never have I ever left a store without buying anything and felt judged", de: "Ich bin noch nie aus einem Laden rausgegangen, ohne was zu kaufen, und hab mich verurteilt gefühlt", es: "Nunca he salido de una tienda sin comprar nada y me sentí juzgado", category: "embarrassing", subcategory: "public", intensity: 2, is_nsfw: false },
{ en: "Never have I ever pretended I wasn't hungry to be polite", de: "Ich hab noch nie so getan, als hätte ich keinen Hunger, um höflich zu sein", es: "Nunca he fingido no tener hambre para ser educado", category: "social", subcategory: "people_pleasing", intensity: 2, is_nsfw: false },
{ en: "Never have I ever forgotten an important birthday", de: "Ich hab noch nie einen wichtigen Geburtstag vergessen", es: "Nunca he olvidado un cumpleaños importante", category: "confessions", subcategory: "guilt", intensity: 2, is_nsfw: false },
{ en: "Never have I ever hidden behind something to avoid someone", de: "Ich hab mich noch nie hinter etwas versteckt, um jemandem aus dem Weg zu gehen", es: "Nunca me he escondido detrás de algo para evitar a alguien", category: "embarrassing", subcategory: "cringe", intensity: 2, is_nsfw: false },
{ en: "Never have I ever agreed to a plan I had no intention of attending", de: "Ich hab noch nie einem Plan zugestimmt, zu dem ich nie vorhatte hinzugehen", es: "Nunca he aceptado un plan al que no tenía intención de ir", category: "social", subcategory: "people_pleasing", intensity: 2, is_nsfw: false },
{ en: "Never have I ever read spoilers intentionally", de: "Ich hab noch nie absichtlich Spoiler gelesen", es: "Nunca he leído spoilers intencionalmente", category: "confessions", subcategory: "secrets", intensity: 2, is_nsfw: false },
{ en: "Never have I ever practiced a conversation in front of a mirror", de: "Ich hab noch nie ein Gespräch vor dem Spiegel geübt", es: "Nunca he practicado una conversación frente al espejo", category: "social", subcategory: "habits", intensity: 2, is_nsfw: false },
{ en: "Never have I ever been afraid to ask for directions", de: "Ich hatte noch nie Angst, nach dem Weg zu fragen", es: "Nunca he tenido miedo de pedir indicaciones", category: "social", subcategory: "awkward", intensity: 2, is_nsfw: false },
{ en: "Never have I ever eaten something off the floor", de: "Ich hab noch nie was vom Boden aufgehoben und gegessen", es: "Nunca he comido algo del piso", category: "food", subcategory: "gross", intensity: 2, is_nsfw: false },
{ en: "Never have I ever been the only one laughing at something", de: "Ich war noch nie die einzige Person, die über etwas gelacht hat", es: "Nunca he sido el único riéndose de algo", category: "embarrassing", subcategory: "public", intensity: 2, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 3 — need 36 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever accidentally hit 'like' on an old photo while stalking someone", de: "Ich hab noch nie versehentlich ein altes Foto geliked, während ich jemanden gestalkt hab", es: "Nunca he dado like por accidente a una foto vieja mientras stalkeaba a alguien", category: "social", subcategory: "online", intensity: 3, is_nsfw: false },
{ en: "Never have I ever pretended to be older or younger to get into something", de: "Ich hab noch nie so getan, als wäre ich älter oder jünger, um irgendwo reinzukommen", es: "Nunca he fingido ser mayor o menor para entrar a algo", category: "confessions", subcategory: "dishonesty", intensity: 3, is_nsfw: false },
{ en: "Never have I ever gone back to an ex even though I knew it was a mistake", de: "Ich bin noch nie zu einem Ex zurückgegangen, obwohl ich wusste, dass es ein Fehler war", es: "Nunca he vuelto con un ex sabiendo que era un error", category: "relationships", subcategory: "heartbreak", intensity: 3, is_nsfw: false },
{ en: "Never have I ever left a date early by making up an excuse", de: "Ich bin noch nie von einem Date früher gegangen, indem ich eine Ausrede erfunden hab", es: "Nunca me he ido temprano de una cita inventando una excusa", category: "relationships", subcategory: "dating", intensity: 3, is_nsfw: false },
{ en: "Never have I ever sent a risky text and immediately regretted it", de: "Ich hab noch nie eine riskante Nachricht geschickt und es sofort bereut", es: "Nunca he mandado un mensaje arriesgado y me arrepentí al instante", category: "social", subcategory: "online", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been caught lying about something small", de: "Ich wurde noch nie bei einer kleinen Lüge erwischt", es: "Nunca me han cachado mintiendo sobre algo pequeño", category: "confessions", subcategory: "dishonesty", intensity: 3, is_nsfw: false },
{ en: "Never have I ever pretended I knew how to do something at work and had to Google it secretly", de: "Ich hab noch nie so getan, als wüsste ich, wie etwas bei der Arbeit geht, und musste es heimlich googeln", es: "Nunca he fingido saber hacer algo en el trabajo y tuve que buscarlo en Google en secreto", category: "confessions", subcategory: "dishonesty", intensity: 3, is_nsfw: false },
{ en: "Never have I ever eaten an entire cake by myself", de: "Ich hab noch nie einen ganzen Kuchen alleine gegessen", es: "Nunca me he comido un pastel entero solo", category: "food", subcategory: "habits", intensity: 3, is_nsfw: false },
{ en: "Never have I ever broken a bone doing something stupid", de: "Ich hab mir noch nie einen Knochen gebrochen, weil ich was Dummes gemacht hab", es: "Nunca me he roto un hueso haciendo algo tonto", category: "risk", subcategory: "stunts", intensity: 3, is_nsfw: false },
{ en: "Never have I ever cried watching a YouTube video", de: "Ich hab noch nie bei einem YouTube-Video geweint", es: "Nunca he llorado viendo un video de YouTube", category: "deep", subcategory: "vulnerability", intensity: 3, is_nsfw: false },
{ en: "Never have I ever eaten food from the trash", de: "Ich hab noch nie Essen aus dem Müll gegessen", es: "Nunca he comido comida de la basura", category: "food", subcategory: "gross", intensity: 3, is_nsfw: false },
{ en: "Never have I ever dyed my hair a color I instantly hated", de: "Ich hab mir noch nie die Haare in einer Farbe gefärbt, die ich sofort gehasst hab", es: "Nunca me he teñido el pelo de un color que odié al instante", category: "embarrassing", subcategory: "cringe", intensity: 3, is_nsfw: false },
{ en: "Never have I ever taken a photo of food at a restaurant and felt embarrassed about it", de: "Ich hab noch nie ein Foto vom Essen im Restaurant gemacht und mich dafür geschämt", es: "Nunca me he sentido avergonzado por tomar una foto de la comida en un restaurante", category: "food", subcategory: "habits", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been ghosted by someone I really liked", de: "Ich wurde noch nie von jemandem geghostet, den ich wirklich mochte", es: "Nunca me ha ghosteado alguien que me gustaba mucho", category: "relationships", subcategory: "dating", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been scared of the dark as an adult", de: "Ich hatte als Erwachsener noch nie Angst im Dunkeln", es: "Nunca he tenido miedo a la oscuridad de adulto", category: "confessions", subcategory: "shame", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been so awkward on a date it became a story I tell now", de: "Ich war noch nie so peinlich auf einem Date, dass es jetzt eine Geschichte ist, die ich erzähle", es: "Nunca he sido tan incómodo en una cita que se convirtió en una historia que cuento ahora", category: "relationships", subcategory: "dating", intensity: 3, is_nsfw: false },
{ en: "Never have I ever felt left out by my closest friends", de: "Ich hab mich noch nie von meinen engsten Freunden ausgeschlossen gefühlt", es: "Nunca me he sentido excluido por mis amigos más cercanos", category: "deep", subcategory: "vulnerability", intensity: 3, is_nsfw: false },
{ en: "Never have I ever won something and not told anyone to avoid jealousy", de: "Ich hab noch nie etwas gewonnen und es niemandem erzählt, um Neid zu vermeiden", es: "Nunca he ganado algo y no se lo dije a nadie para evitar celos", category: "social", subcategory: "status", intensity: 3, is_nsfw: false },
{ en: "Never have I ever peed in a pool", de: "Ich hab noch nie ins Schwimmbecken gepinkelt", es: "Nunca he hecho pipi en una piscina", category: "embarrassing", subcategory: "gross", intensity: 3, is_nsfw: false },
{ en: "Never have I ever danced on a table", de: "Ich hab noch nie auf einem Tisch getanzt", es: "Nunca he bailado sobre una mesa", category: "party", subcategory: "wild_nights", intensity: 3, is_nsfw: false },
{ en: "Never have I ever pretended to enjoy a sport just to hang out with someone", de: "Ich hab noch nie so getan, als würde ich einen Sport mögen, nur um mit jemandem rumzuhängen", es: "Nunca he fingido disfrutar un deporte solo para pasar tiempo con alguien", category: "social", subcategory: "people_pleasing", intensity: 3, is_nsfw: false },
{ en: "Never have I ever driven drunk or with a drunk driver", de: "Ich bin noch nie betrunken gefahren oder mit einem betrunkenen Fahrer mitgefahren", es: "Nunca he manejado borracho ni me he subido con un conductor borracho", category: "risk", subcategory: "driving", intensity: 3, is_nsfw: false },
{ en: "Never have I ever thought a stranger was someone I knew and started a conversation", de: "Ich hab noch nie einen Fremden für jemanden gehalten, den ich kenne, und ein Gespräch angefangen", es: "Nunca he confundido a un desconocido con alguien que conozco y empecé a hablarle", category: "embarrassing", subcategory: "public", intensity: 3, is_nsfw: false },
{ en: "Never have I ever rage-texted someone I regretted later", de: "Ich hab noch nie jemandem eine Wut-Nachricht geschickt, die ich später bereut hab", es: "Nunca le he mandado un mensaje de rabia a alguien que luego lamenté", category: "confessions", subcategory: "guilt", intensity: 3, is_nsfw: false },
{ en: "Never have I ever ghosted someone who didn't deserve it", de: "Ich hab noch nie jemanden geghostet, der es nicht verdient hatte", es: "Nunca le he hecho ghosting a alguien que no lo merecía", category: "moral_gray", subcategory: "dark", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been laughed at in front of a large group", de: "Ich wurde noch nie vor einer großen Gruppe ausgelacht", es: "Nunca se han reído de mí frente a un grupo grande", category: "embarrassing", subcategory: "public", intensity: 3, is_nsfw: false },
{ en: "Never have I ever eaten expired food and hoped for the best", de: "Ich hab noch nie abgelaufenes Essen gegessen und aufs Beste gehofft", es: "Nunca he comido comida vencida y esperé lo mejor", category: "food", subcategory: "gross", intensity: 3, is_nsfw: false },
{ en: "Never have I ever gotten into trouble because of a dare", de: "Ich hatte noch nie Ärger wegen einer Mutprobe", es: "Nunca me he metido en problemas por un reto", category: "risk", subcategory: "bets", intensity: 3, is_nsfw: false },
{ en: "Never have I ever pretended to understand a joke everyone was laughing at", de: "Ich hab noch nie so getan, als würde ich einen Witz verstehen, über den alle gelacht haben", es: "Nunca he fingido entender un chiste del que todos se reían", category: "social", subcategory: "people_pleasing", intensity: 3, is_nsfw: false },
{ en: "Never have I ever eavesdropped on a private conversation", de: "Ich hab noch nie ein privates Gespräch belauscht", es: "Nunca he escuchado una conversación privada a escondidas", category: "confessions", subcategory: "secrets", intensity: 3, is_nsfw: false },
{ en: "Never have I ever ditched my friends to spend time with my partner", de: "Ich hab noch nie meine Freunde sitzen lassen, um Zeit mit meinem Partner zu verbringen", es: "Nunca he dejado plantados a mis amigos para estar con mi pareja", category: "relationships", subcategory: "boundaries", intensity: 3, is_nsfw: false },
{ en: "Never have I ever tried a diet that was obviously unhealthy", de: "Ich hab noch nie eine Diät ausprobiert, die offensichtlich ungesund war", es: "Nunca he hecho una dieta que era obviamente poco saludable", category: "food", subcategory: "habits", intensity: 3, is_nsfw: false },
{ en: "Never have I ever lost it over something minor and embarrassed myself", de: "Ich hab noch nie wegen einer Kleinigkeit ausgerastet und mich blamiert", es: "Nunca he explotado por algo menor y me avergoncé", category: "embarrassing", subcategory: "cringe", intensity: 3, is_nsfw: false },
{ en: "Never have I ever had a food allergy reaction at the worst time", de: "Ich hatte noch nie eine Lebensmittelallergiereaktion im schlimmsten Moment", es: "Nunca he tenido una reacción alérgica alimentaria en el peor momento", category: "food", subcategory: "gross", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been peer-pressured into drinking", de: "Ich wurde noch nie unter Gruppenzwang zum Trinken gebracht", es: "Nunca me han presionado para beber", category: "party", subcategory: "drinking", intensity: 3, is_nsfw: false },
{ en: "Never have I ever tripped going up the stairs", de: "Ich bin noch nie beim Treppensteigen nach oben gestolpert", es: "Nunca me he tropezado subiendo las escaleras", category: "embarrassing", subcategory: "cringe", intensity: 3, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 4 — need 63 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever been the one who started drama in a friend group", de: "Ich war noch nie die Person, die Drama in einer Freundesgruppe angefangen hat", es: "Nunca he sido quien empezó el drama en un grupo de amigos", category: "moral_gray", subcategory: "manipulation", intensity: 4, is_nsfw: false },
{ en: "Never have I ever secretly hoped someone would fail", de: "Ich hab noch nie heimlich gehofft, dass jemand scheitert", es: "Nunca he deseado en secreto que alguien fracasara", category: "moral_gray", subcategory: "dark", intensity: 4, is_nsfw: false },
{ en: "Never have I ever ghosted someone mid-conversation", de: "Ich hab noch nie jemanden mitten im Gespräch geghostet", es: "Nunca le he hecho ghosting a alguien en medio de una conversación", category: "social", subcategory: "online", intensity: 4, is_nsfw: false },
{ en: "Never have I ever gotten blackout drunk", de: "Ich war noch nie so betrunken, dass ich einen Filmriss hatte", es: "Nunca me he emborrachado tanto que tuve un apagón", category: "party", subcategory: "drinking", intensity: 4, is_nsfw: false },
{ en: "Never have I ever thrown up in someone else's car", de: "Ich hab mich noch nie im Auto von jemand anderem übergeben", es: "Nunca he vomitado en el coche de alguien más", category: "party", subcategory: "wild_nights", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been the last person at a party who wouldn't leave", de: "Ich war noch nie der Letzte auf einer Party, der nicht gehen wollte", es: "Nunca he sido el último en una fiesta que no quería irse", category: "party", subcategory: "faux_pas", intensity: 4, is_nsfw: false },
{ en: "Never have I ever pretended to be single when I wasn't", de: "Ich hab noch nie so getan, als wäre ich Single, obwohl ich es nicht war", es: "Nunca he fingido ser soltero cuando no lo era", category: "relationships", subcategory: "flirting", intensity: 4, is_nsfw: false },
{ en: "Never have I ever used someone's Wi-Fi password without asking", de: "Ich hab noch nie jemandes WLAN-Passwort benutzt, ohne zu fragen", es: "Nunca he usado la contraseña de Wi-Fi de alguien sin pedir permiso", category: "confessions", subcategory: "guilt", intensity: 4, is_nsfw: false },
{ en: "Never have I ever stayed friends with someone just because I felt bad for them", de: "Ich war noch nie mit jemandem befreundet, nur weil ich Mitleid hatte", es: "Nunca he mantenido una amistad solo porque sentía pena", category: "moral_gray", subcategory: "temptation", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been humiliated in front of someone I liked", de: "Ich wurde noch nie vor jemandem blamiert, den ich mochte", es: "Nunca me he sentido humillado frente a alguien que me gustaba", category: "embarrassing", subcategory: "cringe", intensity: 4, is_nsfw: false },
{ en: "Never have I ever talked someone out of a decision because it was bad for me", de: "Ich hab noch nie jemandem etwas ausgeredet, weil es schlecht für mich war", es: "Nunca he disuadido a alguien de una decisión porque me perjudicaba", category: "moral_gray", subcategory: "manipulation", intensity: 4, is_nsfw: false },
{ en: "Never have I ever woken up with no memory of the night before", de: "Ich bin noch nie aufgewacht und konnte mich nicht an die Nacht davor erinnern", es: "Nunca me he despertado sin recuerdos de la noche anterior", category: "party", subcategory: "drinking", intensity: 4, is_nsfw: false },
{ en: "Never have I ever publicly embarrassed someone I was angry at", de: "Ich hab noch nie jemanden öffentlich bloßgestellt, auf den ich sauer war", es: "Nunca he avergonzado a alguien en público porque estaba enojado", category: "moral_gray", subcategory: "dark", intensity: 4, is_nsfw: false },
{ en: "Never have I ever driven somewhere I shouldn't have been", de: "Ich bin noch nie irgendwohin gefahren, wo ich nicht hätte sein sollen", es: "Nunca he manejado a un lugar donde no debería haber estado", category: "risk", subcategory: "driving", intensity: 4, is_nsfw: false },
{ en: "Never have I ever wished I could trade lives with someone", de: "Ich hab mir noch nie gewünscht, mit jemandem das Leben zu tauschen", es: "Nunca he deseado intercambiar vidas con alguien", category: "deep", subcategory: "identity", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been in a group chat that talked about someone in the group", de: "Ich war noch nie in einem Gruppenchat, der über jemanden aus der Gruppe gelästert hat", es: "Nunca he estado en un grupo de chat que hablaba de alguien del grupo", category: "moral_gray", subcategory: "loyalty", intensity: 4, is_nsfw: false },
{ en: "Never have I ever walked out during a movie because it was too intense", de: "Ich bin noch nie aus einem Film rausgegangen, weil er zu heftig war", es: "Nunca me he salido de una película porque era demasiado intensa", category: "social", subcategory: "habits", intensity: 4, is_nsfw: false },
{ en: "Never have I ever shoplifted", de: "Ich hab noch nie geklaut", es: "Nunca he robado en una tienda", category: "risk", subcategory: "reckless", intensity: 4, is_nsfw: false },
{ en: "Never have I ever drank so much I didn't recognize my reflection", de: "Ich hab noch nie so viel getrunken, dass ich mein Spiegelbild nicht erkannt hab", es: "Nunca he tomado tanto que no reconocí mi reflejo", category: "party", subcategory: "drinking", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been afraid of being alone", de: "Ich hatte noch nie Angst davor, allein zu sein", es: "Nunca he tenido miedo de estar solo", category: "deep", subcategory: "vulnerability", intensity: 4, is_nsfw: false },
{ en: "Never have I ever told a secret that wasn't mine to tell", de: "Ich hab noch nie ein Geheimnis verraten, das nicht meins war", es: "Nunca he contado un secreto que no era mío para contar", category: "confessions", subcategory: "guilt", intensity: 4, is_nsfw: false },
{ en: "Never have I ever had a mentor who let me down", de: "Ich hatte noch nie einen Mentor, der mich enttäuscht hat", es: "Nunca he tenido un mentor que me defraudó", category: "deep", subcategory: "growth", intensity: 4, is_nsfw: false },
{ en: "Never have I ever sabotaged my own success", de: "Ich hab noch nie meinen eigenen Erfolg sabotiert", es: "Nunca he saboteado mi propio éxito", category: "deep", subcategory: "mental_health", intensity: 4, is_nsfw: false },
{ en: "Never have I ever made fun of someone behind their back and felt guilty", de: "Ich hab noch nie hinter dem Rücken von jemandem gelästert und mich schuldig gefühlt", es: "Nunca me he burlado de alguien a sus espaldas y me sentí culpable", category: "confessions", subcategory: "guilt", intensity: 4, is_nsfw: false },
{ en: "Never have I ever challenged someone I had no chance of beating", de: "Ich hab noch nie jemanden herausgefordert, gegen den ich keine Chance hatte", es: "Nunca he retado a alguien contra quien no tenía oportunidad", category: "risk", subcategory: "bets", intensity: 4, is_nsfw: false },
{ en: "Never have I ever changed my personality depending on who I was with", de: "Ich hab noch nie meine Persönlichkeit verändert, je nachdem, mit wem ich zusammen war", es: "Nunca he cambiado mi personalidad dependiendo de con quién estaba", category: "deep", subcategory: "identity", intensity: 4, is_nsfw: false },
{ en: "Never have I ever eaten someone's food without permission", de: "Ich hab noch nie das Essen von jemand anderem ohne Erlaubnis gegessen", es: "Nunca he comido la comida de alguien sin permiso", category: "food", subcategory: "gross", intensity: 4, is_nsfw: false },
{ en: "Never have I ever ordered an expensive meal on someone else's tab", de: "Ich hab noch nie was Teures bestellt, wenn jemand anderes gezahlt hat", es: "Nunca he pedido algo caro cuando otra persona pagaba", category: "food", subcategory: "habits", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been the subject of a rumor", de: "Ich war noch nie das Thema eines Gerüchts", es: "Nunca he sido el tema de un rumor", category: "social", subcategory: "status", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been afraid someone would find out who I really am", de: "Ich hatte noch nie Angst, dass jemand rausfindet, wer ich wirklich bin", es: "Nunca he tenido miedo de que alguien descubra quién soy realmente", category: "deep", subcategory: "identity", intensity: 4, is_nsfw: false },
{ en: "Never have I ever gotten a speeding ticket", de: "Ich hab noch nie einen Strafzettel wegen zu schnellem Fahren bekommen", es: "Nunca me han puesto una multa por exceso de velocidad", category: "risk", subcategory: "driving", intensity: 4, is_nsfw: false },
{ en: "Never have I ever faked being sick to avoid a social event", de: "Ich hab noch nie so getan, als wäre ich krank, um ein soziales Event zu vermeiden", es: "Nunca he fingido estar enfermo para evitar un evento social", category: "confessions", subcategory: "dishonesty", intensity: 4, is_nsfw: false },
{ en: "Never have I ever said 'I don't care' when I absolutely did", de: "Ich hab noch nie 'Ist mir egal' gesagt, obwohl es mir absolut nicht egal war", es: "Nunca he dicho 'no me importa' cuando absolutamente sí me importaba", category: "confessions", subcategory: "dishonesty", intensity: 4, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 5 — need 81 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever stayed with someone just because I was scared of being alone", de: "Ich bin noch nie bei jemandem geblieben, nur weil ich Angst hatte, allein zu sein", es: "Nunca me he quedado con alguien solo porque tenía miedo de estar solo", category: "relationships", subcategory: "boundaries", intensity: 5, is_nsfw: false },
{ en: "Never have I ever led someone on when I knew I wasn't interested", de: "Ich hab noch nie jemandem falsche Hoffnungen gemacht, obwohl ich wusste, dass ich kein Interesse hatte", es: "Nunca he ilusionado a alguien sabiendo que no estaba interesado", category: "moral_gray", subcategory: "manipulation", intensity: 5, is_nsfw: false },
{ en: "Never have I ever questioned my own identity because of someone else's opinion", de: "Ich hab noch nie meine eigene Identität infrage gestellt wegen der Meinung von jemand anderem", es: "Nunca he cuestionado mi propia identidad por la opinión de alguien más", category: "deep", subcategory: "identity", intensity: 5, is_nsfw: false },
{ en: "Never have I ever done something reckless while under the influence", de: "Ich hab noch nie etwas Verrücktes gemacht, als ich unter Einfluss stand", es: "Nunca he hecho algo temerario bajo la influencia", category: "risk", subcategory: "substances", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been so embarrassed at a party I left without saying goodbye", de: "Ich war noch nie so peinlich berührt auf einer Party, dass ich ohne Abschied gegangen bin", es: "Nunca me he avergonzado tanto en una fiesta que me fui sin despedirme", category: "party", subcategory: "faux_pas", intensity: 5, is_nsfw: false },
{ en: "Never have I ever wanted someone who was clearly wrong for me", de: "Ich wollte noch nie jemanden, der offensichtlich falsch für mich war", es: "Nunca he deseado a alguien que claramente no me convenía", category: "relationships", subcategory: "dating", intensity: 5, is_nsfw: false },
{ en: "Never have I ever made a promise I knew I couldn't keep", de: "Ich hab noch nie ein Versprechen gemacht, von dem ich wusste, dass ich es nicht halten kann", es: "Nunca he hecho una promesa que sabía que no podía cumplir", category: "confessions", subcategory: "dishonesty", intensity: 5, is_nsfw: false },
{ en: "Never have I ever punished someone with silence", de: "Ich hab noch nie jemanden mit Schweigen bestraft", es: "Nunca he castigado a alguien con mi silencio", category: "moral_gray", subcategory: "manipulation", intensity: 5, is_nsfw: false },
{ en: "Never have I ever broken up with someone over text", de: "Ich hab noch nie per Nachricht mit jemandem Schluss gemacht", es: "Nunca he terminado con alguien por mensaje", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever given someone the silent treatment for more than a day", de: "Ich hab noch nie jemanden länger als einen Tag mit Schweigen bestraft", es: "Nunca le he dado a alguien la ley del hielo por más de un día", category: "moral_gray", subcategory: "manipulation", intensity: 5, is_nsfw: false },
{ en: "Never have I ever pretended my life was better than it actually was on social media", de: "Ich hab noch nie auf Social Media so getan, als wäre mein Leben besser als es wirklich ist", es: "Nunca he fingido que mi vida era mejor de lo que realmente era en redes sociales", category: "social", subcategory: "online", intensity: 5, is_nsfw: false },
{ en: "Never have I ever started a fight I knew I'd lose", de: "Ich hab noch nie einen Streit angefangen, von dem ich wusste, dass ich verlieren würde", es: "Nunca he empezado una pelea que sabía que iba a perder", category: "risk", subcategory: "reckless", intensity: 5, is_nsfw: false },
{ en: "Never have I ever held onto resentment for years", de: "Ich hab noch nie jahrelang Groll mit mir herumgetragen", es: "Nunca he guardado rencor por años", category: "deep", subcategory: "regret", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been so jealous it changed my behavior", de: "Ich war noch nie so eifersüchtig, dass es mein Verhalten verändert hat", es: "Nunca he estado tan celoso que cambió mi comportamiento", category: "deep", subcategory: "vulnerability", intensity: 5, is_nsfw: false },
{ en: "Never have I ever felt relieved when a friendship ended", de: "Ich war noch nie erleichtert, als eine Freundschaft endete", es: "Nunca me he sentido aliviado cuando una amistad terminó", category: "deep", subcategory: "growth", intensity: 5, is_nsfw: false },
{ en: "Never have I ever done something I was ashamed to tell my best friend", de: "Ich hab noch nie etwas getan, von dem ich mich geschämt hab, es meinem besten Freund zu erzählen", es: "Nunca he hecho algo que me avergonzaba contarle a mi mejor amigo", category: "confessions", subcategory: "shame", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been afraid to check my phone because of a conversation I was avoiding", de: "Ich hatte noch nie Angst, auf mein Handy zu schauen, wegen einer Konversation, der ich aus dem Weg ging", es: "Nunca he tenido miedo de revisar mi teléfono por una conversación que estaba evitando", category: "social", subcategory: "awkward", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been so drunk I had to be carried home", de: "Ich war noch nie so betrunken, dass ich nach Hause getragen werden musste", es: "Nunca he estado tan borracho que tuvieron que cargarme a casa", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever lied about how many people I've slept with", de: "Ich hab noch nie über die Anzahl der Leute gelogen, mit denen ich geschlafen hab", es: "Nunca he mentido sobre con cuántas personas me he acostado", category: "sexual", subcategory: "desire", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been emotionally cheated on", de: "Ich wurde noch nie emotional betrogen", es: "Nunca me han puesto los cuernos emocionalmente", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever hidden the real reason I broke up with someone", de: "Ich hab noch nie den wahren Grund verschwiegen, warum ich mit jemandem Schluss gemacht hab", es: "Nunca he escondido la verdadera razón por la que terminé con alguien", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever talked to an ex behind my partner's back", de: "Ich hab noch nie hinter dem Rücken meines Partners mit einem Ex geschrieben", es: "Nunca he hablado con un ex a espaldas de mi pareja", category: "moral_gray", subcategory: "cheating", intensity: 5, is_nsfw: false },
{ en: "Never have I ever pretended I wasn't hurt by something so I wouldn't look weak", de: "Ich hab noch nie so getan, als hätte mich etwas nicht verletzt, nur um nicht schwach auszusehen", es: "Nunca he fingido que algo no me dolió para no verme débil", category: "deep", subcategory: "vulnerability", intensity: 5, is_nsfw: false },
{ en: "Never have I ever lost a friend because I started dating their ex", de: "Ich hab noch nie einen Freund verloren, weil ich dessen Ex gedatet hab", es: "Nunca he perdido un amigo porque empecé a salir con su ex", category: "relationships", subcategory: "boundaries", intensity: 5, is_nsfw: false },
{ en: "Never have I ever felt disgusted with myself after a night out", de: "Ich hab mich noch nie nach einer Partynacht vor mir selbst geekelt", es: "Nunca me he sentido asqueado de mí mismo después de una noche de fiesta", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever considered calling an ex at 2 AM", de: "Ich hab noch nie darüber nachgedacht, um 2 Uhr nachts einen Ex anzurufen", es: "Nunca he considerado llamar a un ex a las 2 de la mañana", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever regretted something I said in the heat of the moment", de: "Ich hab noch nie etwas bereut, das ich im Affekt gesagt hab", es: "Nunca me he arrepentido de algo que dije en el calor del momento", category: "deep", subcategory: "regret", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been kicked out of a bar", de: "Ich wurde noch nie aus einer Bar geworfen", es: "Nunca me han echado de un bar", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever tried to make an ex jealous on social media", de: "Ich hab noch nie versucht, einen Ex auf Social Media eifersüchtig zu machen", es: "Nunca he intentado darle celos a un ex en redes sociales", category: "relationships", subcategory: "heartbreak", intensity: 5, is_nsfw: false },
{ en: "Never have I ever kept a dating app on my phone while in a relationship", de: "Ich hatte noch nie eine Dating-App auf dem Handy, obwohl ich in einer Beziehung war", es: "Nunca he tenido una app de citas en mi teléfono estando en una relación", category: "moral_gray", subcategory: "cheating", intensity: 5, is_nsfw: false },
{ en: "Never have I ever pretended I wasn't jealous when I clearly was", de: "Ich hab noch nie so getan, als wäre ich nicht eifersüchtig, obwohl ich es eindeutig war", es: "Nunca he fingido no estar celoso cuando claramente lo estaba", category: "relationships", subcategory: "flirting", intensity: 5, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 6 — need 102 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever hooked up with a coworker", de: "Ich hab noch nie was mit einem Arbeitskollegen gehabt", es: "Nunca me he liado con un compañero de trabajo", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever stalked an ex online for months after the breakup", de: "Ich hab noch nie einen Ex monatelang nach der Trennung online gestalkt", es: "Nunca he stalkeado a un ex en línea por meses después de la ruptura", category: "relationships", subcategory: "heartbreak", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been in a love triangle", de: "Ich war noch nie in einem Liebesdreieck", es: "Nunca he estado en un triángulo amoroso", category: "relationships", subcategory: "situationship", intensity: 6, is_nsfw: false },
{ en: "Never have I ever ghosted someone after sleeping with them", de: "Ich hab noch nie jemanden geghostet, nachdem ich mit der Person geschlafen hab", es: "Nunca le he hecho ghosting a alguien después de acostarme con esa persona", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever done something illegal and never got caught", de: "Ich hab noch nie was Illegales gemacht und bin nie erwischt worden", es: "Nunca he hecho algo ilegal y nunca me cacharon", category: "risk", subcategory: "reckless", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt so angry I broke something on purpose", de: "Ich war noch nie so wütend, dass ich absichtlich etwas kaputt gemacht hab", es: "Nunca he estado tan enojado que rompí algo a propósito", category: "deep", subcategory: "vulnerability", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been attracted to someone while in a relationship", de: "Ich war noch nie von jemandem angezogen, während ich in einer Beziehung war", es: "Nunca me he sentido atraído por alguien mientras estaba en una relación", category: "relationships", subcategory: "boundaries", intensity: 6, is_nsfw: false },
{ en: "Never have I ever hurt someone's feelings and not apologized", de: "Ich hab noch nie jemandes Gefühle verletzt und mich nicht entschuldigt", es: "Nunca he lastimado los sentimientos de alguien y no me disculpé", category: "moral_gray", subcategory: "dark", intensity: 6, is_nsfw: false },
{ en: "Never have I ever threatened to leave a relationship just to get my way", de: "Ich hab noch nie gedroht, eine Beziehung zu beenden, nur um meinen Willen durchzusetzen", es: "Nunca he amenazado con terminar una relación solo para salirme con la mía", category: "moral_gray", subcategory: "manipulation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt completely empty inside for no obvious reason", de: "Ich hab mich noch nie ohne erkennbaren Grund komplett leer gefühlt", es: "Nunca me he sentido completamente vacío por dentro sin razón aparente", category: "deep", subcategory: "mental_health", intensity: 6, is_nsfw: false },
{ en: "Never have I ever made out with my best friend", de: "Ich hab noch nie mit meinem besten Freund rumgeknutscht", es: "Nunca me he besado con mi mejor amigo", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever stolen someone's partner", de: "Ich hab noch nie jemandes Partner geklaut", es: "Nunca he robado la pareja de alguien", category: "moral_gray", subcategory: "cheating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt abandoned by everyone at the same time", de: "Ich hab mich noch nie gleichzeitig von allen verlassen gefühlt", es: "Nunca me he sentido abandonado por todos al mismo tiempo", category: "deep", subcategory: "vulnerability", intensity: 6, is_nsfw: false },
{ en: "Never have I ever slept with a friend and then acted like it never happened", de: "Ich hab noch nie mit einem Freund geschlafen und dann so getan, als wäre nichts gewesen", es: "Nunca me he acostado con un amigo y luego actué como si nada hubiera pasado", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever lost respect for someone I once admired", de: "Ich hab noch nie den Respekt vor jemandem verloren, den ich einmal bewundert hab", es: "Nunca he perdido el respeto por alguien que antes admiraba", category: "deep", subcategory: "growth", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt guilty about something I did at a party", de: "Ich hab mich noch nie schuldig gefühlt wegen etwas, das ich auf einer Party gemacht hab", es: "Nunca me he sentido culpable por algo que hice en una fiesta", category: "party", subcategory: "wild_nights", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had a one-night stand I'm ashamed of", de: "Ich hatte noch nie einen One-Night-Stand, für den ich mich schäme", es: "Nunca he tenido un encuentro de una noche del que me avergüenzo", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever intentionally made someone feel insecure", de: "Ich hab noch nie absichtlich jemanden unsicher gemacht", es: "Nunca he hecho sentir inseguro a alguien intencionalmente", category: "moral_gray", subcategory: "manipulation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever questioned whether I'm actually a good person", de: "Ich hab noch nie infrage gestellt, ob ich wirklich ein guter Mensch bin", es: "Nunca me he preguntado si realmente soy una buena persona", category: "deep", subcategory: "identity", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been afraid my partner would leave me", de: "Ich hatte noch nie Angst, dass mein Partner mich verlassen würde", es: "Nunca he tenido miedo de que mi pareja me dejara", category: "relationships", subcategory: "heartbreak", intensity: 6, is_nsfw: false },
{ en: "Never have I ever talked badly about someone who trusted me", de: "Ich hab noch nie schlecht über jemanden geredet, der mir vertraut hat", es: "Nunca he hablado mal de alguien que confiaba en mí", category: "moral_gray", subcategory: "loyalty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever kissed someone who was already taken", de: "Ich hab noch nie jemanden geküsst, der vergeben war", es: "Nunca he besado a alguien que ya tenía pareja", category: "moral_gray", subcategory: "cheating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been the other person in a love affair", de: "Ich war noch nie die andere Person in einer Affäre", es: "Nunca he sido la otra persona en una aventura amorosa", category: "moral_gray", subcategory: "cheating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt I couldn't trust anyone completely", de: "Ich hatte noch nie das Gefühl, dass ich niemandem komplett vertrauen kann", es: "Nunca he sentido que no puedo confiar en nadie completamente", category: "deep", subcategory: "vulnerability", intensity: 6, is_nsfw: false },
{ en: "Never have I ever cut off a family member", de: "Ich hab noch nie den Kontakt zu einem Familienmitglied abgebrochen", es: "Nunca he cortado relación con un familiar", category: "deep", subcategory: "growth", intensity: 6, is_nsfw: false },
{ en: "Never have I ever gone skinny-dipping", de: "Ich war noch nie nackt baden", es: "Nunca me he bañado desnudo", category: "party", subcategory: "dares", intensity: 6, is_nsfw: false },
{ en: "Never have I ever done something so wild at a party that I still can't believe it", de: "Ich hab noch nie auf einer Party was so Wildes gemacht, dass ich es immer noch nicht glauben kann", es: "Nunca he hecho algo tan loco en una fiesta que todavía no puedo creerlo", category: "party", subcategory: "wild_nights", intensity: 6, is_nsfw: false },
{ en: "Never have I ever felt like I'm repeating my parents' mistakes", de: "Ich hatte noch nie das Gefühl, die Fehler meiner Eltern zu wiederholen", es: "Nunca he sentido que estoy repitiendo los errores de mis padres", category: "deep", subcategory: "identity", intensity: 6, is_nsfw: false },
{ en: "Never have I ever taken back a cheater", de: "Ich hab noch nie einen Fremdgeher zurückgenommen", es: "Nunca he perdonado y vuelto con alguien que me fue infiel", category: "relationships", subcategory: "heartbreak", intensity: 6, is_nsfw: false },
{ en: "Never have I ever tried something illegal out of curiosity", de: "Ich hab noch nie aus Neugier etwas Illegales ausprobiert", es: "Nunca he probado algo ilegal por curiosidad", category: "risk", subcategory: "substances", intensity: 6, is_nsfw: false },
{ en: "Never have I ever woken up in a stranger's bed", de: "Ich bin noch nie im Bett eines Fremden aufgewacht", es: "Nunca me he despertado en la cama de un desconocido", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 7 — need 102 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever hooked up with two friends who didn't know about each other", de: "Ich hab noch nie was mit zwei Freunden gehabt, die nichts voneinander wussten", es: "Nunca me he liado con dos amigos que no sabían el uno del otro", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever kept someone's nudes after we stopped talking", de: "Ich hab noch nie die Nudes von jemandem behalten, nachdem wir aufgehört haben zu reden", es: "Nunca he guardado las fotos íntimas de alguien después de dejar de hablarnos", category: "sexual", subcategory: "desire", intensity: 7, is_nsfw: true },
{ en: "Never have I ever fantasized about a friend's partner", de: "Ich hatte noch nie Fantasien über den Partner eines Freundes", es: "Nunca he fantaseado con la pareja de un amigo", category: "sexual", subcategory: "temptation", intensity: 7, is_nsfw: true },
{ en: "Never have I ever told a lie so big that I started believing it myself", de: "Ich hab noch nie eine so große Lüge erzählt, dass ich selbst angefangen hab, sie zu glauben", es: "Nunca he dicho una mentira tan grande que empecé a creerla yo mismo", category: "confessions", subcategory: "dishonesty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever cheated on a test or exam", de: "Ich hab noch nie bei einem Test oder einer Prüfung geschummelt", es: "Nunca he hecho trampa en un examen", category: "confessions", subcategory: "dishonesty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever done something self-destructive on purpose", de: "Ich hab noch nie absichtlich etwas Selbstzerstörerisches getan", es: "Nunca he hecho algo autodestructivo a propósito", category: "deep", subcategory: "mental_health", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been in a relationship just for the sex", de: "Ich war noch nie in einer Beziehung, nur wegen dem Sex", es: "Nunca he estado en una relación solo por el sexo", category: "sexual", subcategory: "desire", intensity: 7, is_nsfw: true },
{ en: "Never have I ever sexted someone I'd never met in person", de: "Ich hab noch nie mit jemandem gesextet, den ich nie persönlich getroffen hab", es: "Nunca he sexteado con alguien que nunca conocí en persona", category: "sexual", subcategory: "desire", intensity: 7, is_nsfw: true },
{ en: "Never have I ever been caught having sex", de: "Ich wurde noch nie beim Sex erwischt", es: "Nunca me han pillado teniendo sexo", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever had sex in a public place", de: "Ich hatte noch nie Sex an einem öffentlichen Ort", es: "Nunca he tenido sexo en un lugar público", category: "sexual", subcategory: "kinks", intensity: 7, is_nsfw: true },
{ en: "Never have I ever used a fake identity online", de: "Ich hab noch nie eine falsche Identität online benutzt", es: "Nunca he usado una identidad falsa en línea", category: "confessions", subcategory: "dishonesty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had feelings for my best friend", de: "Ich hatte noch nie Gefühle für meinen besten Freund", es: "Nunca he tenido sentimientos por mi mejor amigo", category: "relationships", subcategory: "situationship", intensity: 7, is_nsfw: false },
{ en: "Never have I ever let someone take the blame for something I did", de: "Ich hab noch nie jemanden für etwas die Schuld nehmen lassen, das ich gemacht hab", es: "Nunca he dejado que alguien cargue con la culpa de algo que hice", category: "moral_gray", subcategory: "dark", intensity: 7, is_nsfw: false },
{ en: "Never have I ever used intimacy to get something I wanted", de: "Ich hab noch nie Intimität benutzt, um etwas zu bekommen, das ich wollte", es: "Nunca he usado la intimidad para conseguir algo que quería", category: "sexual", subcategory: "boundaries", intensity: 7, is_nsfw: true },
{ en: "Never have I ever slept with an ex long after we broke up", de: "Ich hab noch nie lange nach der Trennung mit einem Ex geschlafen", es: "Nunca me he acostado con un ex mucho después de terminar", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever been addicted to something I still struggle with", de: "Ich war noch nie süchtig nach etwas, womit ich immer noch kämpfe", es: "Nunca he sido adicto a algo con lo que todavía lucho", category: "deep", subcategory: "mental_health", intensity: 7, is_nsfw: false },
{ en: "Never have I ever realized mid-argument that I was wrong but kept going", de: "Ich hab noch nie mitten im Streit gemerkt, dass ich falsch lag, und trotzdem weitergemacht", es: "Nunca me he dado cuenta en medio de una discusión de que estaba equivocado pero seguí", category: "confessions", subcategory: "guilt", intensity: 7, is_nsfw: false },
{ en: "Never have I ever done a dare that could have gotten me seriously hurt", de: "Ich hab noch nie eine Mutprobe gemacht, bei der ich mich ernsthaft hätte verletzen können", es: "Nunca he aceptado un reto que podría haberme lastimado seriamente", category: "risk", subcategory: "stunts", intensity: 7, is_nsfw: false },
{ en: "Never have I ever broken into somewhere", de: "Ich bin noch nie irgendwo eingebrochen", es: "Nunca me he metido a algún lugar sin permiso", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been in a situation where I feared for my safety", de: "Ich war noch nie in einer Situation, in der ich um meine Sicherheit gebangt hab", es: "Nunca he estado en una situación donde temí por mi seguridad", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 114 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever cheated and felt no remorse", de: "Ich bin noch nie fremdgegangen und hab keine Reue empfunden", es: "Nunca he sido infiel sin sentir remordimiento", category: "moral_gray", subcategory: "cheating", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had a sexual fantasy about two people at the same time", de: "Ich hatte noch nie eine sexuelle Fantasie über zwei Personen gleichzeitig", es: "Nunca he tenido una fantasía sexual con dos personas al mismo tiempo", category: "sexual", subcategory: "kinks", intensity: 8, is_nsfw: true },
{ en: "Never have I ever manipulated someone into staying in a relationship", de: "Ich hab noch nie jemanden manipuliert, damit er in einer Beziehung bleibt", es: "Nunca he manipulado a alguien para que se quedara en una relación", category: "moral_gray", subcategory: "manipulation", intensity: 8, is_nsfw: false },
{ en: "Never have I ever done something during sex I was uncomfortable with just to please my partner", de: "Ich hab noch nie beim Sex etwas gemacht, bei dem ich mich unwohl gefühlt hab, nur um meinen Partner zufriedenzustellen", es: "Nunca he hecho algo durante el sexo que me incomodaba solo para complacer a mi pareja", category: "sexual", subcategory: "boundaries", intensity: 8, is_nsfw: true },
{ en: "Never have I ever had revenge on someone who deserved it", de: "Ich hab mich noch nie an jemandem gerächt, der es verdient hatte", es: "Nunca me he vengado de alguien que lo merecía", category: "moral_gray", subcategory: "dark", intensity: 8, is_nsfw: false },
{ en: "Never have I ever discovered a partner's biggest lie", de: "Ich hab noch nie die größte Lüge eines Partners entdeckt", es: "Nunca he descubierto la mentira más grande de una pareja", category: "relationships", subcategory: "heartbreak", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been involved in a scandal", de: "Ich war noch nie in einen Skandal verwickelt", es: "Nunca he estado involucrado en un escándalo", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had to choose between two people I was seeing at the same time", de: "Ich musste mich noch nie zwischen zwei Leuten entscheiden, mit denen ich gleichzeitig was hatte", es: "Nunca he tenido que elegir entre dos personas con las que salía al mismo tiempo", category: "relationships", subcategory: "situationship", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been arrested", de: "Ich wurde noch nie verhaftet", es: "Nunca me han arrestado", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever considered myself capable of real cruelty", de: "Ich hab mich noch nie für fähig gehalten, wirklich grausam zu sein", es: "Nunca me he considerado capaz de verdadera crueldad", category: "deep", subcategory: "identity", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been so obsessed with someone it scared me", de: "Ich war noch nie so besessen von jemandem, dass es mir Angst gemacht hat", es: "Nunca he estado tan obsesionado con alguien que me asustó", category: "deep", subcategory: "mental_health", intensity: 8, is_nsfw: false },
{ en: "Never have I ever secretly recorded a conversation", de: "Ich hab noch nie heimlich ein Gespräch aufgenommen", es: "Nunca he grabado una conversación en secreto", category: "moral_gray", subcategory: "dark", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had a sexual experience I've never told anyone about", de: "Ich hatte noch nie ein sexuelles Erlebnis, von dem ich niemandem erzählt hab", es: "Nunca he tenido una experiencia sexual de la que nunca le he contado a nadie", category: "sexual", subcategory: "desire", intensity: 8, is_nsfw: true },
{ en: "Never have I ever been sexually attracted to someone in a position of authority over me", de: "Ich war noch nie sexuell von jemandem angezogen, der eine Autoritätsposition über mich hatte", es: "Nunca me he sentido atraído sexualmente por alguien en posición de autoridad sobre mí", category: "sexual", subcategory: "temptation", intensity: 8, is_nsfw: true },
{ en: "Never have I ever kept going back to someone I knew was destroying me", de: "Ich bin noch nie immer wieder zu jemandem zurückgegangen, von dem ich wusste, dass er mich zerstört", es: "Nunca he seguido volviendo a alguien que sabía que me estaba destruyendo", category: "deep", subcategory: "mental_health", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had to testify or give a statement about something serious", de: "Ich musste noch nie in einer ernsten Sache aussagen", es: "Nunca he tenido que testificar sobre algo serio", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been confronted with evidence of something I lied about", de: "Ich wurde noch nie mit Beweisen für etwas konfrontiert, worüber ich gelogen hatte", es: "Nunca me han confrontado con evidencia de algo sobre lo que mentí", category: "confessions", subcategory: "dishonesty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever done something that if it came out would end a relationship permanently", de: "Ich hab noch nie etwas getan, das, wenn es rauskäme, eine Beziehung für immer beenden würde", es: "Nunca he hecho algo que si saliera a la luz terminaría una relación permanentemente", category: "confessions", subcategory: "secrets", intensity: 8, is_nsfw: false },
{ en: "Never have I ever seen my own double standard in relationships", de: "Ich hab noch nie meine eigene Doppelmoral in Beziehungen erkannt", es: "Nunca he visto mi propio doble estándar en relaciones", category: "deep", subcategory: "growth", intensity: 8, is_nsfw: false },
{ en: "Never have I ever played both sides in a conflict", de: "Ich hab noch nie in einem Konflikt beide Seiten gespielt", es: "Nunca he jugado ambos lados en un conflicto", category: "moral_gray", subcategory: "manipulation", intensity: 8, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 120 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever watched someone get hurt and did nothing", de: "Ich hab noch nie zugesehen, wie jemand verletzt wurde, und nichts getan", es: "Nunca he visto a alguien ser lastimado y no hice nada", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been caught in a lie that destroyed a relationship", de: "Ich wurde noch nie bei einer Lüge erwischt, die eine Beziehung zerstört hat", es: "Nunca me han cachado en una mentira que destruyó una relación", category: "confessions", subcategory: "dishonesty", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a secret that controls how I live my life", de: "Ich hatte noch nie ein Geheimnis, das bestimmt, wie ich mein Leben lebe", es: "Nunca he tenido un secreto que controla cómo vivo mi vida", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had sex with someone to get over someone else", de: "Ich hatte noch nie Sex mit jemandem, um jemand anderen zu vergessen", es: "Nunca me he acostado con alguien para olvidar a otra persona", category: "sexual", subcategory: "hookups", intensity: 9, is_nsfw: true },
{ en: "Never have I ever felt like I was living a lie", de: "Ich hatte noch nie das Gefühl, eine Lüge zu leben", es: "Nunca he sentido que estoy viviendo una mentira", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever used someone's trust as leverage to get what I wanted", de: "Ich hab noch nie jemandes Vertrauen als Hebel benutzt, um zu bekommen, was ich wollte", es: "Nunca he usado la confianza de alguien como palanca para obtener lo que quería", category: "moral_gray", subcategory: "manipulation", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been completely honest about my past with anyone", de: "Ich war noch nie mit irgendjemandem komplett ehrlich über meine Vergangenheit", es: "Nunca he sido completamente honesto sobre mi pasado con alguien", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever enjoyed someone else's pain more than I should", de: "Ich hab noch nie die Schmerzen von jemand anderem mehr genossen, als ich es sollte", es: "Nunca he disfrutado del dolor de alguien más de lo que debería", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been so low I didn't care what happened to me", de: "Ich war noch nie so am Boden, dass es mir egal war, was mit mir passiert", es: "Nunca he estado tan bajo que no me importaba qué me pasara", category: "deep", subcategory: "mental_health", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a sexual kink I would never admit to", de: "Ich hatte noch nie einen sexuellen Kink, den ich niemals zugeben würde", es: "Nunca he tenido un fetiche sexual que nunca admitiría", category: "sexual", subcategory: "kinks", intensity: 9, is_nsfw: true },
{ en: "Never have I ever willingly put myself in a dangerous situation for the thrill", de: "Ich hab mich noch nie absichtlich in eine gefährliche Situation begeben, nur wegen dem Kick", es: "Nunca me he puesto voluntariamente en una situación peligrosa por la emoción", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },
{ en: "Never have I ever lost myself so completely in someone that I forgot who I was", de: "Ich hab mich noch nie so komplett in jemandem verloren, dass ich vergessen hab, wer ich bin", es: "Nunca me he perdido tan completamente en alguien que olvidé quién soy", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever crossed a line I told myself I'd never cross", de: "Ich hab noch nie eine Grenze überschritten, die ich mir selbst gesetzt hatte", es: "Nunca he cruzado una línea que me dije que nunca cruzaría", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had a sexual encounter that involved power dynamics", de: "Ich hatte noch nie ein sexuelles Erlebnis, bei dem es um Machtdynamiken ging", es: "Nunca he tenido un encuentro sexual que involucrara dinámicas de poder", category: "sexual", subcategory: "kinks", intensity: 9, is_nsfw: true },
{ en: "Never have I ever confronted someone about something they did and it got violent", de: "Ich hab noch nie jemanden zur Rede gestellt und es wurde gewalttätig", es: "Nunca he confrontado a alguien por algo que hizo y se volvió violento", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 130 more
// ═══════════════════════════════════════════════════════════

{ en: "Never have I ever been involved in something that still haunts me", de: "Ich war noch nie in etwas verwickelt, das mich bis heute verfolgt", es: "Nunca he estado involucrado en algo que todavía me persigue", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had to make a choice that permanently hurt someone I love", de: "Ich musste noch nie eine Entscheidung treffen, die jemanden, den ich liebe, dauerhaft verletzt hat", es: "Nunca he tenido que tomar una decisión que lastimó permanentemente a alguien que amo", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been capable of something that society would consider unforgivable", de: "Ich war noch nie fähig zu etwas, das die Gesellschaft als unverzeihlich betrachten würde", es: "Nunca he sido capaz de algo que la sociedad consideraría imperdonable", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a sexual experience that I deeply regret", de: "Ich hatte noch nie ein sexuelles Erlebnis, das ich zutiefst bereue", es: "Nunca he tenido una experiencia sexual de la que me arrepiento profundamente", category: "sexual", subcategory: "boundaries", intensity: 10, is_nsfw: true },
{ en: "Never have I ever manipulated someone's emotions so well they thanked me for it", de: "Ich hab noch nie jemandes Emotionen so gut manipuliert, dass die Person mir dafür gedankt hat", es: "Nunca he manipulado las emociones de alguien tan bien que me agradeció por ello", category: "moral_gray", subcategory: "manipulation", intensity: 10, is_nsfw: false },
{ en: "Never have I ever known I was toxic but chosen not to change", de: "Ich hab noch nie gewusst, dass ich toxisch bin, und mich bewusst dagegen entschieden, mich zu ändern", es: "Nunca he sabido que soy tóxico pero elegí no cambiar", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been in a sexual situation that violated someone's trust", de: "Ich war noch nie in einer sexuellen Situation, die jemandes Vertrauen verletzt hat", es: "Nunca he estado en una situación sexual que violó la confianza de alguien", category: "sexual", subcategory: "boundaries", intensity: 10, is_nsfw: true },
{ en: "Never have I ever seen the worst part of myself and not known how to fix it", de: "Ich hab noch nie den schlimmsten Teil von mir selbst gesehen und nicht gewusst, wie ich es reparieren soll", es: "Nunca he visto la peor parte de mí mismo y no supe cómo arreglarla", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever lived with a guilt so strong it physically hurts", de: "Ich hab noch nie mit einer Schuld gelebt, die so stark war, dass sie physisch wehtat", es: "Nunca he vivido con una culpa tan fuerte que duele físicamente", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever done something during sex I wasn't proud of", de: "Ich hab noch nie beim Sex etwas getan, worauf ich nicht stolz war", es: "Nunca he hecho algo durante el sexo de lo que no estuve orgulloso", category: "sexual", subcategory: "boundaries", intensity: 10, is_nsfw: true },
];

// ═══════════════════════════════════════════════════════════
//  MERGE AND WRITE
// ═══════════════════════════════════════════════════════════

const BASE_PATH = path.resolve(__dirname, '../app/assets/questions.json');
const base = JSON.parse(fs.readFileSync(BASE_PATH, 'utf-8'));

console.log(`Base questions: ${base.length}`);
console.log(`Batch 2 questions: ${BATCH2.length}`);

const startIdx = base.length;
const batch2Built = BATCH2.map((q, idx) => {
  const meta = computeMetadata(q);
  return {
    id: `q${String(startIdx + idx + 1).padStart(4, '0')}`,
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
  };
});

const merged = [...base, ...batch2Built];
console.log(`Merged total: ${merged.length}`);

const byIntensity = new Map<number, number>();
for (const q of merged) {
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
for (const q of merged) {
  byCat.set(q.category, (byCat.get(q.category) || 0) + 1);
}
console.log('\nDistribution by category:');
for (const [cat, count] of [...byCat.entries()].sort((a, b) => b[1] - a[1])) {
  console.log(`  ${cat}: ${count}`);
}

const texts = new Set<string>();
let dupes = 0;
for (const q of merged) {
  const key = q.text_en.toLowerCase().trim();
  if (texts.has(key)) {
    dupes++;
    console.log(`  DUPE: ${q.text_en}`);
  }
  texts.add(key);
}
console.log(`\nExact EN duplicates: ${dupes}`);

fs.writeFileSync(BASE_PATH, JSON.stringify(merged, null, 2) + '\n', 'utf-8');
console.log(`\n✅ Wrote ${merged.length} questions to ${BASE_PATH}`);
