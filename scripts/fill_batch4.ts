#!/usr/bin/env npx tsx
/**
 * BATCH 4 — FINAL fill to reach 1600
 * Focus: intensities 3-10, categories: party, risk, food, embarrassing (underrepresented)
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

const BATCH4: QuestionDef[] = [

// ═══════════════════════════════════════════════════════════
//  INTENSITY 3 — need 3 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever spilled a drink on my laptop", de: "Ich hab noch nie ein Getränk auf meinen Laptop verschüttet", es: "Nunca he derramado una bebida en mi laptop", category: "embarrassing", subcategory: "cringe", intensity: 3, is_nsfw: false },
{ en: "Never have I ever accidentally butt-dialed someone during an awkward moment", de: "Ich hab noch nie versehentlich jemanden angerufen in einem peinlichen Moment", es: "Nunca he marcado a alguien por accidente en un momento incómodo", category: "embarrassing", subcategory: "cringe", intensity: 3, is_nsfw: false },
{ en: "Never have I ever been afraid to check my bank account", de: "Ich hatte noch nie Angst, auf meinen Kontostand zu schauen", es: "Nunca he tenido miedo de revisar mi cuenta bancaria", category: "confessions", subcategory: "shame", intensity: 3, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 4 — need 5 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever started a rumor", de: "Ich hab noch nie ein Gerücht gestartet", es: "Nunca he empezado un rumor", category: "moral_gray", subcategory: "dark", intensity: 4, is_nsfw: false },
{ en: "Never have I ever been someone's plan B", de: "Ich war noch nie jemandes Plan B", es: "Nunca he sido el plan B de alguien", category: "relationships", subcategory: "situationship", intensity: 4, is_nsfw: false },
{ en: "Never have I ever eaten something I dropped on the floor at a restaurant", de: "Ich hab noch nie etwas aufgehoben und gegessen, das mir in einem Restaurant runtergefallen ist", es: "Nunca he comido algo que se me cayó al piso en un restaurante", category: "food", subcategory: "gross", intensity: 4, is_nsfw: false },
{ en: "Never have I ever thrown a party without telling my roommate", de: "Ich hab noch nie eine Party geschmissen, ohne meinem Mitbewohner Bescheid zu sagen", es: "Nunca he hecho una fiesta sin avisarle a mi compañero de cuarto", category: "party", subcategory: "faux_pas", intensity: 4, is_nsfw: false },
{ en: "Never have I ever drunk-ordered food I didn't remember ordering", de: "Ich hab noch nie betrunken Essen bestellt, an das ich mich nicht erinnern konnte", es: "Nunca he pedido comida borracho que no recordaba haber pedido", category: "food", subcategory: "drunk_eating", intensity: 4, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 5 — need 31 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever crashed a wedding", de: "Ich hab noch nie eine Hochzeit gecrasht", es: "Nunca me he colado en una boda", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been in a bar fight", de: "Ich war noch nie in einer Schlägerei in einer Bar", es: "Nunca me he peleado en un bar", category: "risk", subcategory: "reckless", intensity: 5, is_nsfw: false },
{ en: "Never have I ever had a guilty pleasure that my friends would roast me for", de: "Ich hatte noch nie ein Guilty Pleasure, für das meine Freunde mich aufziehen würden", es: "Nunca he tenido un placer culposo por el que mis amigos se burlarían de mí", category: "confessions", subcategory: "shame", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been with someone my friends all warned me about", de: "Ich war noch nie mit jemandem zusammen, vor dem mich alle meine Freunde gewarnt haben", es: "Nunca he estado con alguien de quien todos mis amigos me advirtieron", category: "relationships", subcategory: "dating", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been involved in a prank that went too far", de: "Ich war noch nie an einem Streich beteiligt, der zu weit ging", es: "Nunca he participado en una broma que se pasó de la raya", category: "risk", subcategory: "bets", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been escorted out of a building by security", de: "Ich wurde noch nie von Security aus einem Gebäude begleitet", es: "Nunca me ha sacado seguridad de un edificio", category: "risk", subcategory: "reckless", intensity: 5, is_nsfw: false },
{ en: "Never have I ever cooked something inedible and served it to guests anyway", de: "Ich hab noch nie etwas Ungenießbares gekocht und es trotzdem Gästen serviert", es: "Nunca he cocinado algo que no se podía comer y se lo serví a invitados igual", category: "food", subcategory: "cooking", intensity: 5, is_nsfw: false },
{ en: "Never have I ever eaten a whole dessert that was meant for the table", de: "Ich hab noch nie ein ganzes Dessert gegessen, das für den ganzen Tisch gedacht war", es: "Nunca me he comido un postre entero que era para toda la mesa", category: "food", subcategory: "gross", intensity: 5, is_nsfw: false },
{ en: "Never have I ever thrown up in public and had to keep walking", de: "Ich hab mich noch nie in der Öffentlichkeit übergeben und musste einfach weiterlaufen", es: "Nunca he vomitado en público y tuve que seguir caminando", category: "embarrassing", subcategory: "gross", intensity: 5, is_nsfw: false },
{ en: "Never have I ever caused a scene at a restaurant", de: "Ich hab noch nie eine Szene in einem Restaurant gemacht", es: "Nunca he armado una escena en un restaurante", category: "embarrassing", subcategory: "public", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been the reason a party got shut down", de: "Ich war noch nie der Grund, warum eine Party aufgelöst wurde", es: "Nunca he sido la razón por la que se acabó una fiesta", category: "party", subcategory: "wild_nights", intensity: 5, is_nsfw: false },
{ en: "Never have I ever fallen asleep at a party and been drawn on", de: "Ich bin noch nie auf einer Party eingeschlafen und wurde angemalt", es: "Nunca me he quedado dormido en una fiesta y me dibujaron encima", category: "party", subcategory: "dares", intensity: 5, is_nsfw: false },
{ en: "Never have I ever dared someone to do something I wouldn't do myself", de: "Ich hab noch nie jemanden zu etwas herausgefordert, das ich selbst nicht tun würde", es: "Nunca he retado a alguien a hacer algo que yo no haría", category: "party", subcategory: "dares", intensity: 5, is_nsfw: false },
{ en: "Never have I ever cried while apologizing to someone", de: "Ich hab noch nie geweint, während ich mich bei jemandem entschuldigt hab", es: "Nunca he llorado mientras me disculpaba con alguien", category: "deep", subcategory: "vulnerability", intensity: 5, is_nsfw: false },
{ en: "Never have I ever had a secret I was afraid would get out", de: "Ich hatte noch nie ein Geheimnis, von dem ich Angst hatte, dass es rauskommt", es: "Nunca he tenido un secreto del que tenía miedo de que se supiera", category: "confessions", subcategory: "secrets", intensity: 5, is_nsfw: false },
{ en: "Never have I ever eaten something at a party that I later found out was special", de: "Ich hab noch nie auf einer Party was gegessen, von dem ich später erfahren hab, dass es besonders war", es: "Nunca he comido algo en una fiesta que luego me enteré que era especial", category: "food", subcategory: "drunk_eating", intensity: 5, is_nsfw: false },
{ en: "Never have I ever done karaoke sober", de: "Ich hab noch nie nüchtern Karaoke gemacht", es: "Nunca he hecho karaoke sobrio", category: "party", subcategory: "dares", intensity: 5, is_nsfw: false },
{ en: "Never have I ever skinny-dipped with people I barely knew", de: "Ich war noch nie nackt baden mit Leuten, die ich kaum kannte", es: "Nunca me he bañado desnudo con gente que apenas conocía", category: "party", subcategory: "dares", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been publicly called out for lying", de: "Ich wurde noch nie öffentlich für eine Lüge bloßgestellt", es: "Nunca me han exhibido públicamente por mentir", category: "embarrassing", subcategory: "caught", intensity: 5, is_nsfw: false },
{ en: "Never have I ever been dared to eat something disgusting and actually did it", de: "Ich wurde noch nie herausgefordert, etwas Ekliges zu essen, und hab es tatsächlich gemacht", es: "Nunca me han retado a comer algo asqueroso y lo hice", category: "food", subcategory: "gross", intensity: 5, is_nsfw: false },
{ en: "Never have I ever hitchhiked", de: "Ich bin noch nie getrampt", es: "Nunca he hecho autostop", category: "risk", subcategory: "stunts", intensity: 5, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 6 — need 48 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever had a forbidden crush", de: "Ich hatte noch nie einen verbotenen Crush", es: "Nunca he tenido un crush prohibido", category: "relationships", subcategory: "flirting", intensity: 6, is_nsfw: false },
{ en: "Never have I ever drunk-cried in front of strangers", de: "Ich hab noch nie betrunken vor Fremden geweint", es: "Nunca he llorado borracho frente a desconocidos", category: "party", subcategory: "wild_nights", intensity: 6, is_nsfw: false },
{ en: "Never have I ever set fire to something on purpose", de: "Ich hab noch nie absichtlich etwas angezündet", es: "Nunca he prendido fuego a algo a propósito", category: "risk", subcategory: "reckless", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been in a car chase", de: "Ich war noch nie in einer Verfolgungsjagd", es: "Nunca he estado en una persecución en auto", category: "risk", subcategory: "driving", intensity: 6, is_nsfw: false },
{ en: "Never have I ever sent an anonymous message to someone", de: "Ich hab noch nie eine anonyme Nachricht an jemanden geschickt", es: "Nunca he mandado un mensaje anónimo a alguien", category: "confessions", subcategory: "secrets", intensity: 6, is_nsfw: false },
{ en: "Never have I ever betrayed someone's trust to save my own reputation", de: "Ich hab noch nie jemandes Vertrauen verraten, um meinen eigenen Ruf zu retten", es: "Nunca he traicionado la confianza de alguien para salvar mi propia reputación", category: "moral_gray", subcategory: "loyalty", intensity: 6, is_nsfw: false },
{ en: "Never have I ever changed my opinion just because everyone else disagreed", de: "Ich hab noch nie meine Meinung geändert, nur weil alle anderen anderer Meinung waren", es: "Nunca he cambiado mi opinión solo porque todos los demás no estaban de acuerdo", category: "social", subcategory: "people_pleasing", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had someone cry because of something I did at a party", de: "Ich hab noch nie dafür gesorgt, dass jemand auf einer Party wegen mir geweint hat", es: "Nunca he hecho llorar a alguien por algo que hice en una fiesta", category: "party", subcategory: "faux_pas", intensity: 6, is_nsfw: false },
{ en: "Never have I ever flirted with someone to get free drinks", de: "Ich hab noch nie mit jemandem geflirtet, um Freigetränke zu bekommen", es: "Nunca he coqueteado con alguien para obtener tragos gratis", category: "party", subcategory: "dares", intensity: 6, is_nsfw: false },
{ en: "Never have I ever secretly judged someone for their food choices", de: "Ich hab noch nie jemanden heimlich für seine Essgewohnheiten verurteilt", es: "Nunca he juzgado en secreto a alguien por lo que come", category: "food", subcategory: "picky", intensity: 6, is_nsfw: false },
{ en: "Never have I ever eaten something at a party that I'm pretty sure wasn't food", de: "Ich hab noch nie auf einer Party was gegessen, von dem ich mir ziemlich sicher bin, dass es kein Essen war", es: "Nunca he comido algo en una fiesta de lo que estoy bastante seguro que no era comida", category: "food", subcategory: "drunk_eating", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been in the middle of a friend breakup", de: "Ich war noch nie mitten in einem Freundschafts-Breakup", es: "Nunca he estado en medio de una ruptura de amigos", category: "social", subcategory: "status", intensity: 6, is_nsfw: false },
{ en: "Never have I ever done a body shot off someone", de: "Ich hab noch nie einen Body-Shot von jemandem gemacht", es: "Nunca he tomado un shot del cuerpo de alguien", category: "party", subcategory: "dares", intensity: 6, is_nsfw: false },
{ en: "Never have I ever ended a friendship and felt nothing", de: "Ich hab noch nie eine Freundschaft beendet und nichts dabei empfunden", es: "Nunca he terminado una amistad y no sentí nada", category: "deep", subcategory: "growth", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been so hungover I swore off drinking forever", de: "Ich hatte noch nie so einen Kater, dass ich geschworen hab, nie wieder zu trinken", es: "Nunca he tenido tanta resaca que juré nunca más beber", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever said something I knew would start a fight", de: "Ich hab noch nie etwas gesagt, von dem ich wusste, dass es einen Streit auslösen würde", es: "Nunca he dicho algo que sabía que iniciaría una pelea", category: "moral_gray", subcategory: "manipulation", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been the third wheel and pretended I was fine with it", de: "Ich war noch nie das fünfte Rad und hab so getan, als wäre es mir egal", es: "Nunca he sido el mal tercio y fingí que estaba bien con eso", category: "social", subcategory: "awkward", intensity: 6, is_nsfw: false },
{ en: "Never have I ever lost a dare and had to do something I actually enjoyed", de: "Ich hab noch nie eine Mutprobe verloren und musste etwas machen, das mir eigentlich gefallen hat", es: "Nunca he perdido un reto y tuve que hacer algo que en realidad disfruté", category: "party", subcategory: "dares", intensity: 6, is_nsfw: false },
{ en: "Never have I ever snuck food into a movie theater", de: "Ich hab noch nie Essen ins Kino geschmuggelt", es: "Nunca he metido comida al cine a escondidas", category: "food", subcategory: "habits", intensity: 6, is_nsfw: false },
{ en: "Never have I ever had a coworker develop feelings for me that I didn't return", de: "In mich hat sich noch nie ein Arbeitskollege verliebt, obwohl ich die Gefühle nicht erwidert hab", es: "Nunca un compañero de trabajo ha desarrollado sentimientos por mí que no correspondí", category: "social", subcategory: "awkward", intensity: 6, is_nsfw: false },
{ en: "Never have I ever called someone the wrong name in bed", de: "Ich hab noch nie jemanden im Bett mit dem falschen Namen angesprochen", es: "Nunca he llamado a alguien por el nombre equivocado en la cama", category: "sexual", subcategory: "hookups", intensity: 6, is_nsfw: false },
{ en: "Never have I ever been so drunk I forgot where I lived", de: "Ich war noch nie so betrunken, dass ich vergessen hab, wo ich wohne", es: "Nunca he estado tan borracho que olvidé dónde vivo", category: "party", subcategory: "drinking", intensity: 6, is_nsfw: false },
{ en: "Never have I ever witnessed something I wish I could unsee", de: "Ich hab noch nie etwas gesehen, das ich am liebsten ungesehen machen würde", es: "Nunca he presenciado algo que desearía poder des-ver", category: "deep", subcategory: "vulnerability", intensity: 6, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 7 — need 65 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever been physically removed from a venue", de: "Ich wurde noch nie physisch aus einem Veranstaltungsort entfernt", es: "Nunca me han sacado físicamente de un lugar", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been involved in a hit and run", de: "Ich war noch nie in eine Fahrerflucht verwickelt", es: "Nunca he estado involucrado en un choque y fuga", category: "risk", subcategory: "driving", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had a relationship that was purely physical and I told nobody", de: "Ich hatte noch nie eine rein körperliche Beziehung, von der ich niemandem erzählt hab", es: "Nunca he tenido una relación puramente física de la que no le conté a nadie", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever taken something that didn't belong to me and felt justified", de: "Ich hab noch nie etwas genommen, das mir nicht gehörte, und mich dabei gerechtfertigt gefühlt", es: "Nunca he tomado algo que no me pertenecía y me sentí justificado", category: "moral_gray", subcategory: "temptation", intensity: 7, is_nsfw: false },
{ en: "Never have I ever gotten a tattoo while drunk", de: "Ich hab mir noch nie betrunken ein Tattoo stechen lassen", es: "Nunca me he hecho un tatuaje borracho", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had sex on a first date", de: "Ich hatte noch nie Sex beim ersten Date", es: "Nunca he tenido sexo en la primera cita", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever had a secret friends-with-benefits with someone in my social circle", de: "Ich hatte noch nie eine geheime Freundschaft Plus mit jemandem aus meinem Freundeskreis", es: "Nunca he tenido un amigo con beneficios secreto en mi círculo social", category: "sexual", subcategory: "hookups", intensity: 7, is_nsfw: true },
{ en: "Never have I ever thought about leaving everything behind with no plan", de: "Ich hab noch nie darüber nachgedacht, alles ohne Plan hinter mir zu lassen", es: "Nunca he pensado en dejarlo todo atrás sin un plan", category: "deep", subcategory: "mental_health", intensity: 7, is_nsfw: false },
{ en: "Never have I ever felt attracted to danger", de: "Ich hab mich noch nie von Gefahr angezogen gefühlt", es: "Nunca me he sentido atraído por el peligro", category: "risk", subcategory: "stunts", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been someone else's affair", de: "Ich war noch nie die Affäre von jemand anderem", es: "Nunca he sido la aventura de alguien más", category: "moral_gray", subcategory: "cheating", intensity: 7, is_nsfw: true },
{ en: "Never have I ever done something at a party that I can't tell my family about", de: "Ich hab noch nie was auf einer Party gemacht, das ich meiner Familie nicht erzählen kann", es: "Nunca he hecho algo en una fiesta que no puedo contarle a mi familia", category: "party", subcategory: "wild_nights", intensity: 7, is_nsfw: false },
{ en: "Never have I ever gambled more than I could afford to lose", de: "Ich hab noch nie mehr verspielt, als ich mir leisten konnte zu verlieren", es: "Nunca he apostado más de lo que podía perder", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever had a secret so heavy I considered confessing to a stranger", de: "Ich hatte noch nie ein so schweres Geheimnis, dass ich es fast einem Fremden gestanden hätte", es: "Nunca he tenido un secreto tan pesado que consideré confesárselo a un desconocido", category: "confessions", subcategory: "secrets", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been in a physical fight over someone I was dating", de: "Ich hatte noch nie eine körperliche Auseinandersetzung wegen jemandem, mit dem ich zusammen war", es: "Nunca he tenido una pelea física por alguien con quien salía", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been so drunk I made a decision that changed the trajectory of my life", de: "Ich war noch nie so betrunken, dass ich eine Entscheidung getroffen hab, die meinen Lebensweg verändert hat", es: "Nunca he estado tan borracho que tomé una decisión que cambió la trayectoria de mi vida", category: "party", subcategory: "drinking", intensity: 7, is_nsfw: false },
{ en: "Never have I ever found out a friend was talking behind my back through screenshots", de: "Ich hab noch nie durch Screenshots herausgefunden, dass ein Freund hinter meinem Rücken geredet hat", es: "Nunca me he enterado por capturas de pantalla de que un amigo hablaba a mis espaldas", category: "social", subcategory: "status", intensity: 7, is_nsfw: false },
{ en: "Never have I ever stolen from a store to impress someone", de: "Ich hab noch nie in einem Laden geklaut, um jemanden zu beeindrucken", es: "Nunca he robado de una tienda para impresionar a alguien", category: "risk", subcategory: "reckless", intensity: 7, is_nsfw: false },
{ en: "Never have I ever lied to a significant other about where I was", de: "Ich hab noch nie meinen Partner angelogen, wo ich war", es: "Nunca le he mentido a mi pareja sobre dónde estaba", category: "confessions", subcategory: "dishonesty", intensity: 7, is_nsfw: false },
{ en: "Never have I ever been afraid of what I might do if I had no consequences", de: "Ich hatte noch nie Angst davor, was ich tun könnte, wenn es keine Konsequenzen gäbe", es: "Nunca he tenido miedo de lo que podría hacer si no hubiera consecuencias", category: "deep", subcategory: "identity", intensity: 7, is_nsfw: false },
{ en: "Never have I ever consumed something at a party without knowing what it was", de: "Ich hab noch nie auf einer Party etwas konsumiert, ohne zu wissen, was es war", es: "Nunca he consumido algo en una fiesta sin saber qué era", category: "risk", subcategory: "substances", intensity: 7, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 8 — need 76 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever blackmailed someone", de: "Ich hab noch nie jemanden erpresst", es: "Nunca he chantajeado a alguien", category: "moral_gray", subcategory: "dark", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been in a physical confrontation with a partner", de: "Ich hatte noch nie eine körperliche Auseinandersetzung mit einem Partner", es: "Nunca he tenido una confrontación física con una pareja", category: "relationships", subcategory: "boundaries", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had sex while someone else was in the same room", de: "Ich hatte noch nie Sex, während jemand anderes im selben Raum war", es: "Nunca he tenido sexo mientras alguien más estaba en la misma habitación", category: "sexual", subcategory: "kinks", intensity: 8, is_nsfw: true },
{ en: "Never have I ever stolen something valuable", de: "Ich hab noch nie etwas Wertvolles gestohlen", es: "Nunca he robado algo valioso", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever seriously considered disappearing from everyone's life", de: "Ich hab noch nie ernsthaft in Betracht gezogen, aus dem Leben aller zu verschwinden", es: "Nunca he considerado seriamente desaparecer de la vida de todos", category: "deep", subcategory: "mental_health", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been emotionally abused and stayed anyway", de: "Ich wurde noch nie emotional missbraucht und bin trotzdem geblieben", es: "Nunca he sido abusado emocionalmente y me quedé igual", category: "relationships", subcategory: "boundaries", intensity: 8, is_nsfw: false },
{ en: "Never have I ever shared someone's intimate secret with a third person", de: "Ich hab noch nie jemandes intimes Geheimnis an eine dritte Person weitererzählt", es: "Nunca he compartido el secreto íntimo de alguien con una tercera persona", category: "moral_gray", subcategory: "loyalty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had a substance problem I hid from everyone", de: "Ich hatte noch nie ein Suchtproblem, das ich vor allen versteckt hab", es: "Nunca he tenido un problema de sustancias que escondí de todos", category: "risk", subcategory: "substances", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had a sexual experience that involved substances", de: "Ich hatte noch nie ein sexuelles Erlebnis unter dem Einfluss von Substanzen", es: "Nunca he tenido una experiencia sexual bajo la influencia de sustancias", category: "sexual", subcategory: "boundaries", intensity: 8, is_nsfw: true },
{ en: "Never have I ever been confronted with the consequences of my actions long after", de: "Ich wurde noch nie lange nach einer Tat mit den Konsequenzen konfrontiert", es: "Nunca me han confrontado con las consecuencias de mis acciones mucho después", category: "deep", subcategory: "regret", intensity: 8, is_nsfw: false },
{ en: "Never have I ever done something for money that I'm not proud of", de: "Ich hab noch nie etwas für Geld getan, worauf ich nicht stolz bin", es: "Nunca he hecho algo por dinero de lo que no estoy orgulloso", category: "moral_gray", subcategory: "temptation", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been hospitalized because of something reckless", de: "Ich war noch nie im Krankenhaus wegen etwas Leichtsinnigem", es: "Nunca he sido hospitalizado por algo imprudente", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever covered up for someone who did something truly wrong", de: "Ich hab noch nie jemanden gedeckt, der etwas wirklich Falsches getan hat", es: "Nunca he encubierto a alguien que hizo algo verdaderamente malo", category: "moral_gray", subcategory: "loyalty", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been attracted to chaos in a relationship", de: "Ich war noch nie von Chaos in einer Beziehung angezogen", es: "Nunca me ha atraído el caos en una relación", category: "relationships", subcategory: "boundaries", intensity: 8, is_nsfw: false },
{ en: "Never have I ever faked who I am for so long I lost track of the real me", de: "Ich hab noch nie so lange jemand anderes gespielt, dass ich den echten mich aus den Augen verloren hab", es: "Nunca he fingido ser alguien por tanto tiempo que perdí de vista quién soy realmente", category: "deep", subcategory: "identity", intensity: 8, is_nsfw: false },
{ en: "Never have I ever discovered something about my family that changed everything", de: "Ich hab noch nie etwas über meine Familie erfahren, das alles verändert hat", es: "Nunca he descubierto algo sobre mi familia que cambió todo", category: "deep", subcategory: "vulnerability", intensity: 8, is_nsfw: false },
{ en: "Never have I ever had to physically stop myself from doing something I'd regret", de: "Ich musste mich noch nie physisch davon abhalten, etwas zu tun, das ich bereuen würde", es: "Nunca he tenido que detenerme físicamente de hacer algo que lamentaría", category: "deep", subcategory: "vulnerability", intensity: 8, is_nsfw: false },
{ en: "Never have I ever kissed someone just to win a dare or bet", de: "Ich hab noch nie jemanden geküsst, nur um eine Wette zu gewinnen", es: "Nunca he besado a alguien solo para ganar un reto o apuesta", category: "party", subcategory: "dares", intensity: 8, is_nsfw: true },
{ en: "Never have I ever done something that made me fear for my future", de: "Ich hab noch nie etwas getan, das mich um meine Zukunft fürchten ließ", es: "Nunca he hecho algo que me hizo temer por mi futuro", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },
{ en: "Never have I ever been caught doing something I could have gone to jail for", de: "Ich wurde noch nie bei etwas erwischt, wofür ich ins Gefängnis hätte kommen können", es: "Nunca me han cachado haciendo algo por lo que podría haber ido a la cárcel", category: "risk", subcategory: "reckless", intensity: 8, is_nsfw: false },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 9 — need 90 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever thought about what life would be like if I had made a different choice at a key moment", de: "Ich hab noch nie darüber nachgedacht, wie mein Leben wäre, wenn ich in einem entscheidenden Moment anders entschieden hätte", es: "Nunca he pensado en cómo sería mi vida si hubiera tomado una decisión diferente en un momento clave", category: "deep", subcategory: "regret", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had my deepest secret threatened", de: "Mir wurde noch nie mit meinem tiefsten Geheimnis gedroht", es: "Nunca me han amenazado con mi secreto más profundo", category: "confessions", subcategory: "secrets", intensity: 9, is_nsfw: false },
{ en: "Never have I ever completely cut off someone who once meant the world to me", de: "Ich hab noch nie jemanden komplett abgeschnitten, der mir einmal die Welt bedeutet hat", es: "Nunca he cortado completamente a alguien que una vez significó el mundo para mí", category: "deep", subcategory: "growth", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something so reckless it could have ended my life", de: "Ich hab noch nie etwas so Verrücktes gemacht, dass es mein Leben hätte beenden können", es: "Nunca he hecho algo tan imprudente que podría haber acabado con mi vida", category: "risk", subcategory: "reckless", intensity: 9, is_nsfw: false },
{ en: "Never have I ever genuinely thought I was a bad person", de: "Ich hab noch nie ernsthaft gedacht, dass ich ein schlechter Mensch bin", es: "Nunca he pensado genuinamente que soy una mala persona", category: "deep", subcategory: "identity", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been so broken by a relationship I needed professional help", de: "Ich war noch nie so zerstört von einer Beziehung, dass ich professionelle Hilfe brauchte", es: "Nunca he estado tan destruido por una relación que necesité ayuda profesional", category: "deep", subcategory: "mental_health", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the person others told horror stories about", de: "Ich war noch nie die Person, über die andere Horrorgeschichten erzählt haben", es: "Nunca he sido la persona de la que otros cuentan historias de terror", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had an addiction that controlled my life", de: "Ich hatte noch nie eine Sucht, die mein Leben kontrolliert hat", es: "Nunca he tenido una adicción que controlara mi vida", category: "risk", subcategory: "substances", intensity: 9, is_nsfw: false },
{ en: "Never have I ever confronted my worst fear and lost", de: "Ich hab mich noch nie meiner größten Angst gestellt und verloren", es: "Nunca he enfrentado mi peor miedo y perdí", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been the catalyst for someone else's breakdown", de: "Ich war noch nie der Auslöser für den Zusammenbruch von jemand anderem", es: "Nunca he sido el catalizador del colapso de alguien más", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had intrusive thoughts that disturbed me", de: "Ich hatte noch nie aufdringliche Gedanken, die mich verstört haben", es: "Nunca he tenido pensamientos intrusivos que me perturbaron", category: "deep", subcategory: "mental_health", intensity: 9, is_nsfw: false },
{ en: "Never have I ever been completely alone in a crisis with no one to call", de: "Ich war noch nie komplett allein in einer Krise, ohne jemanden zum Anrufen", es: "Nunca he estado completamente solo en una crisis sin nadie a quien llamar", category: "deep", subcategory: "vulnerability", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had to choose between doing the right thing and protecting myself", de: "Ich musste mich noch nie zwischen dem Richtigen und meinem eigenen Schutz entscheiden", es: "Nunca he tenido que elegir entre hacer lo correcto y protegerme a mí mismo", category: "moral_gray", subcategory: "temptation", intensity: 9, is_nsfw: false },
{ en: "Never have I ever had sex while actively being dishonest with someone about something major", de: "Ich hatte noch nie Sex, während ich jemanden aktiv über etwas Großes belogen hab", es: "Nunca he tenido sexo mientras activamente le mentía a alguien sobre algo importante", category: "sexual", subcategory: "boundaries", intensity: 9, is_nsfw: true },
{ en: "Never have I ever caused irreparable damage to someone's life", de: "Ich hab noch nie irreparablen Schaden im Leben von jemandem angerichtet", es: "Nunca he causado un daño irreparable en la vida de alguien", category: "moral_gray", subcategory: "dark", intensity: 9, is_nsfw: false },
{ en: "Never have I ever felt like my past is a cage I can't escape", de: "Ich hatte noch nie das Gefühl, dass meine Vergangenheit ein Käfig ist, aus dem ich nicht entkommen kann", es: "Nunca he sentido que mi pasado es una jaula de la que no puedo escapar", category: "deep", subcategory: "regret", intensity: 9, is_nsfw: false },
{ en: "Never have I ever manipulated someone's feelings to get them to stay", de: "Ich hab noch nie jemandes Gefühle manipuliert, damit die Person bleibt", es: "Nunca he manipulado los sentimientos de alguien para que se quedara", category: "moral_gray", subcategory: "manipulation", intensity: 9, is_nsfw: false },
{ en: "Never have I ever seen something at a party that no one would believe if I told them", de: "Ich hab noch nie auf einer Party was gesehen, das mir keiner glauben würde, wenn ich es erzähle", es: "Nunca he visto algo en una fiesta que nadie creería si se los cuento", category: "party", subcategory: "wild_nights", intensity: 9, is_nsfw: false },
{ en: "Never have I ever done something that if it were public, would end my career", de: "Ich hab noch nie etwas getan, das, wenn es öffentlich würde, meine Karriere beenden würde", es: "Nunca he hecho algo que si se hiciera público, acabaría con mi carrera", category: "confessions", subcategory: "secrets", intensity: 9, is_nsfw: false },
{ en: "Never have I ever taken a risk sexually that I now realize was incredibly dangerous", de: "Ich bin noch nie ein sexuelles Risiko eingegangen, das, wie mir jetzt klar wird, unglaublich gefährlich war", es: "Nunca he tomado un riesgo sexual que ahora me doy cuenta que fue increíblemente peligroso", category: "sexual", subcategory: "boundaries", intensity: 9, is_nsfw: true },

// ═══════════════════════════════════════════════════════════
//  INTENSITY 10 — need 110 more
// ═══════════════════════════════════════════════════════════
{ en: "Never have I ever questioned whether my entire personality is a mask", de: "Ich hab mich noch nie gefragt, ob meine gesamte Persönlichkeit eine Maske ist", es: "Nunca me he preguntado si toda mi personalidad es una máscara", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever experienced a betrayal so deep it changed my ability to trust", de: "Ich hab noch nie einen Verrat erlebt, der so tief war, dass er meine Fähigkeit zu vertrauen verändert hat", es: "Nunca he experimentado una traición tan profunda que cambió mi capacidad de confiar", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had an experience so raw I still can't process it", de: "Ich hatte noch nie ein so rohes Erlebnis, dass ich es immer noch nicht verarbeiten kann", es: "Nunca he tenido una experiencia tan cruda que todavía no puedo procesarla", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been a completely different person behind closed doors", de: "Ich war noch nie hinter verschlossenen Türen ein komplett anderer Mensch", es: "Nunca he sido una persona completamente diferente a puertas cerradas", category: "deep", subcategory: "identity", intensity: 10, is_nsfw: false },
{ en: "Never have I ever done something unforgivable and been forgiven anyway", de: "Ich hab noch nie etwas Unverzeihliches getan und wurde trotzdem verziehen", es: "Nunca he hecho algo imperdonable y me perdonaron de todos modos", category: "deep", subcategory: "growth", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a sexual encounter that left lasting psychological effects", de: "Ich hatte noch nie ein sexuelles Erlebnis, das bleibende psychologische Auswirkungen hinterlassen hat", es: "Nunca he tenido un encuentro sexual que dejó efectos psicológicos duraderos", category: "sexual", subcategory: "boundaries", intensity: 10, is_nsfw: true },
{ en: "Never have I ever destroyed something precious to someone just to hurt them", de: "Ich hab noch nie etwas Wertvolles von jemandem zerstört, nur um die Person zu verletzen", es: "Nunca he destruido algo valioso de alguien solo para lastimarlo", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever had a moment where I genuinely didn't want to exist anymore", de: "Ich hatte noch nie einen Moment, in dem ich wirklich nicht mehr existieren wollte", es: "Nunca he tenido un momento en el que genuinamente no quería existir más", category: "deep", subcategory: "mental_health", intensity: 10, is_nsfw: false },
{ en: "Never have I ever willingly hurt someone I love to protect a secret", de: "Ich hab noch nie wissentlich jemanden verletzt, den ich liebe, um ein Geheimnis zu schützen", es: "Nunca he lastimado a alguien que amo voluntariamente para proteger un secreto", category: "moral_gray", subcategory: "loyalty", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been someone's darkest chapter", de: "Ich war noch nie jemandes dunkelstes Kapitel", es: "Nunca he sido el capítulo más oscuro de alguien", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever made a choice that split my life into 'before' and 'after'", de: "Ich hab noch nie eine Entscheidung getroffen, die mein Leben in 'davor' und 'danach' geteilt hat", es: "Nunca he tomado una decisión que dividió mi vida en 'antes' y 'después'", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever known the real reason someone left me but pretended I didn't", de: "Ich hab noch nie den wahren Grund gekannt, warum jemand mich verlassen hat, und so getan, als wüsste ich ihn nicht", es: "Nunca he sabido la verdadera razón por la que alguien me dejó pero fingí que no", category: "relationships", subcategory: "heartbreak", intensity: 10, is_nsfw: false },
{ en: "Never have I ever witnessed cruelty and done nothing to stop it", de: "Ich hab noch nie Grausamkeit gesehen und nichts dagegen getan", es: "Nunca he presenciado crueldad y no hice nada para detenerla", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever used my body to get something I wanted", de: "Ich hab noch nie meinen Körper benutzt, um etwas zu bekommen, das ich wollte", es: "Nunca he usado mi cuerpo para conseguir algo que quería", category: "sexual", subcategory: "temptation", intensity: 10, is_nsfw: true },
{ en: "Never have I ever felt the weight of regret so heavy that it physically suffocates me", de: "Ich hab noch nie die Last der Reue so schwer empfunden, dass sie mich physisch erdrückt", es: "Nunca he sentido el peso del arrepentimiento tan fuerte que me sofoca físicamente", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever participated in something I knew was morally wrong", de: "Ich hab noch nie an etwas teilgenommen, von dem ich wusste, dass es moralisch falsch ist", es: "Nunca he participado en algo que sabía que era moralmente incorrecto", category: "moral_gray", subcategory: "dark", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been someone's reason for not trusting anyone again", de: "Ich war noch nie der Grund dafür, dass jemand niemandem mehr vertraut", es: "Nunca he sido la razón por la que alguien no confía en nadie de nuevo", category: "deep", subcategory: "regret", intensity: 10, is_nsfw: false },
{ en: "Never have I ever been in a sexual situation that I couldn't control", de: "Ich war noch nie in einer sexuellen Situation, die ich nicht kontrollieren konnte", es: "Nunca he estado en una situación sexual que no pude controlar", category: "sexual", subcategory: "boundaries", intensity: 10, is_nsfw: true },
{ en: "Never have I ever had something happen to me that I'll take to the grave", de: "Mir ist noch nie etwas passiert, das ich mit ins Grab nehmen werde", es: "Nunca me ha pasado algo que me llevaré a la tumba", category: "deep", subcategory: "vulnerability", intensity: 10, is_nsfw: false },
{ en: "Never have I ever sacrificed my values for a relationship", de: "Ich hab noch nie meine Werte für eine Beziehung geopfert", es: "Nunca he sacrificado mis valores por una relación", category: "relationships", subcategory: "boundaries", intensity: 10, is_nsfw: false },
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

let added = 0;
for (const q of BATCH4) {
  const key = q.en.toLowerCase().trim();
  if (seenEN.has(key)) { continue; }
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

console.log(`Base: ${base.length} → After dedup + batch4: ${deduped.length} (added ${added})`);

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
