class CreatorPack {
  const CreatorPack({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
    this.isPremium = false,
    this.startersEn = const [],
    this.startersDe = const [],
    this.startersEs = const [],
  });

  final String id;
  final String title;
  final String description;
  final List<String> categories;
  final bool isPremium;
  final List<String> startersEn;
  final List<String> startersDe;
  final List<String> startersEs;

  List<String> startersForLanguage(String language) {
    switch (language) {
      case 'de':
        return startersDe;
      case 'es':
        return startersEs;
      default:
        return startersEn;
    }
  }
}

List<String> _buildPrompts({
  required String prefix,
  required List<String> starts,
  required List<String> closers,
}) {
  final prompts = <String>[];
  for (final start in starts) {
    for (final closer in closers) {
      final prompt = '$prefix $start $closer'
          .replaceAll(RegExp(r'\\s+'), ' ')
          .trim();
      prompts.add(prompt);
    }
  }
  return prompts;
}

void _validatePacks(List<CreatorPack> packs) {
  if (packs.length < 10) {
    throw StateError('Creator packs must contain at least 10 packs.');
  }

  final seenEn = <String>{};
  final seenDe = <String>{};
  final seenEs = <String>{};

  for (final pack in packs) {
    if (pack.startersEn.length < 60 ||
        pack.startersDe.length < 60 ||
        pack.startersEs.length < 60) {
      throw StateError(
        'Each pack must contain at least 60 starters per language.',
      );
    }

    for (final prompt in pack.startersEn) {
      if (!prompt.startsWith('Never have I ever ')) {
        throw StateError('Invalid EN prefix in pack ${pack.id}');
      }
      if (!seenEn.add(prompt)) {
        throw StateError('Duplicate EN starter detected: $prompt');
      }
    }

    for (final prompt in pack.startersDe) {
      if (!prompt.startsWith('Ich hab noch nie ')) {
        throw StateError('Invalid DE prefix in pack ${pack.id}');
      }
      if (!seenDe.add(prompt)) {
        throw StateError('Duplicate DE starter detected: $prompt');
      }
    }

    for (final prompt in pack.startersEs) {
      if (!prompt.startsWith('Nunca ')) {
        throw StateError('Invalid ES prefix in pack ${pack.id}');
      }
      if (!seenEs.add(prompt)) {
        throw StateError('Duplicate ES starter detected: $prompt');
      }
    }
  }
}

class CreatorPacks {
  CreatorPacks._();

  static final List<String> _closersEn = [
    'and acted like it was completely normal',
    'before realizing everyone noticed immediately',
    'and replayed the moment in my head all day',
    'and later laughed about it with the group',
    'while pretending I had planned it that way',
  ];

  static final List<String> _closersDe = [
    'und so getan als waere alles ganz normal',
    'bevor ich gemerkt habe dass es allen aufgefallen ist',
    'und die Szene den ganzen Tag im Kopf wiederholt',
    'und spaeter mit der Gruppe darueber gelacht',
    'waehrend ich so tat als waere es Absicht gewesen',
  ];

  static final List<String> _closersEs = [
    'y actue como si fuera totalmente normal',
    'antes de darme cuenta de que todos lo notaron',
    'y me quede pensando en eso todo el dia',
    'y despues me rei de eso con el grupo',
    'mientras fingia que asi lo habia planeado',
  ];

  static final List<CreatorPack> all = _build();

  static const String defaultSelectionId = 'icebreakers';

  static List<CreatorPack> _build() {
    final packs = [
      CreatorPack(
        id: 'icebreakers',
        title: 'Icebreakers',
        description: 'Fast warmup prompts for fresh groups and first rounds.',
        categories: ['social', 'embarrassing', 'food'],
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'mixed up two names during introductions',
            'waved at someone and realized they were greeting another person',
            'laughed at a joke I did not fully understand',
            'answered a question that was meant for someone else',
            'joined a group chat and stayed silent for days',
            'walked into a room and forgot why I went there',
            'sent a message to the wrong person in a hurry',
            'started telling a story and forgotten the point halfway through',
            'tried to be funny and created an awkward silence',
            'introduced two people and forgotten one name immediately',
            'used a phrase from another language with total confidence and got it wrong',
            'pretended to recognize someone because I felt too awkward to ask',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'bei einer Vorstellungsrunde zwei Namen verwechselt',
            'jemandem gewinkt und erst spaeter gemerkt dass die Person jemand anderen meinte',
            'ueber einen Witz gelacht den ich nicht ganz verstanden habe',
            'eine Frage beantwortet die fuer jemand anderen gedacht war',
            'einen Gruppenchat betreten und tagelang nichts geschrieben',
            'einen Raum betreten und sofort den Grund vergessen',
            'eine Nachricht in Eile an die falsche Person geschickt',
            'eine Geschichte angefangen und in der Mitte den Punkt verloren',
            'lustig sein wollen und eine peinliche Stille erzeugt',
            'zwei Leute vorgestellt und direkt danach einen Namen vergessen',
            'eine fremde Redewendung selbstsicher falsch benutzt',
            'so getan als wuerde ich jemanden kennen weil fragen unangenehm war',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he confundido dos nombres en una presentacion',
            'he saludado a alguien y luego entendi que saludaba a otra persona',
            'me he reido de un chiste que no entendi del todo',
            'he respondido una pregunta que era para otra persona',
            'he entrado a un chat grupal y no he escrito por dias',
            'he entrado a una habitacion y he olvidado por que fui',
            'he enviado un mensaje a la persona equivocada por prisa',
            'he empezado una historia y he perdido el hilo a mitad',
            'he intentado ser gracioso y he creado un silencio incomodo',
            'he presentado a dos personas y he olvidado un nombre al instante',
            'he usado una expresion de otro idioma con seguridad y la dije mal',
            'he fingido reconocer a alguien porque me dio pena preguntar',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'deep_talk',
        title: 'Deep Talk',
        description: 'Reflective prompts around values, identity, and growth.',
        categories: ['deep', 'confessions', 'moral_gray'],
        isPremium: true,
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'changed my opinion after one honest conversation',
            'hidden a dream because I feared being judged',
            'stayed quiet even though I disagreed strongly',
            'outgrown a friendship and not known how to say it',
            'apologized late because my pride got in the way',
            'realized I was chasing approval instead of meaning',
            'set a boundary that changed a relationship for the better',
            'felt lonely in a room full of people I liked',
            'chosen comfort over something I truly wanted',
            'pretended to be fine while carrying heavy stress',
            'held onto a belief long after I knew it was wrong',
            'learned something hard about myself and kept it private for months',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'meine Meinung nach einem ehrlichen Gespraech geaendert',
            'einen Traum verschwiegen aus Angst bewertet zu werden',
            'geschwiegen obwohl ich deutlich anderer Meinung war',
            'eine Freundschaft innerlich losgelassen und nicht gewusst wie ich es sagen soll',
            'mich zu spaet entschuldigt weil mein Stolz im Weg stand',
            'gemerkt dass ich Anerkennung statt Sinn gesucht habe',
            'eine Grenze gesetzt die eine Beziehung verbessert hat',
            'mich in einem vollen Raum mit lieben Menschen einsam gefuehlt',
            'Sicherheit gewaehlt obwohl ich etwas anderes wirklich wollte',
            'so getan als waere alles okay waehrend ich viel Stress getragen habe',
            'an einer Ueberzeugung festgehalten obwohl ich wusste dass sie nicht stimmt',
            'eine schwierige Erkenntnis ueber mich monatelang fuer mich behalten',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he cambiado mi opinion despues de una conversacion honesta',
            'he ocultado un sueno por miedo al juicio de otros',
            'me he quedado callado aunque no estaba de acuerdo',
            'he superado una amistad y no supe como decirlo',
            'he pedido perdon tarde porque mi orgullo me freno',
            'he notado que buscaba aprobacion en lugar de sentido',
            'he puesto un limite que mejoro una relacion importante',
            'me he sentido solo en una sala llena de gente que aprecio',
            'he elegido comodidad en lugar de algo que de verdad queria',
            'he fingido estar bien mientras cargaba mucho estres',
            'he sostenido una creencia aun sabiendo que era equivocada',
            'he descubierto algo dificil sobre mi y lo guarde por meses',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'date_night',
        title: 'Date Night',
        description: 'Romantic and emotionally open prompts for close bonds.',
        categories: ['relationships', 'confessions', 'deep'],
        isPremium: true,
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'rewritten a message ten times before hitting send',
            'waited for someone to text first while checking my phone constantly',
            'misread a signal because I wanted it to be true',
            'planned a perfect date in my head that never happened',
            'kept feelings hidden even when the timing felt right',
            'replayed a first kiss moment for weeks afterward',
            'felt jealous and acted completely unbothered',
            'sent a risky message and regretted it immediately',
            'said I was over it while still thinking about it daily',
            'fallen for someone because of one small thoughtful gesture',
            'pulled back when a connection started feeling serious',
            'looked confident on the outside while panicking inside before a date',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'eine Nachricht zehnmal umgeschrieben bevor ich sie gesendet habe',
            'darauf gewartet dass die andere Person zuerst schreibt und staendig aufs Handy geschaut',
            'ein Signal falsch gedeutet weil ich es so sehen wollte',
            'ein perfektes Date im Kopf geplant das nie stattfand',
            'Gefuehle verschwiegen obwohl der Moment passend war',
            'einen ersten Kuss wochenlang im Kopf wiederholt',
            'Eifersucht gefuehlt und so getan als waere mir alles egal',
            'eine mutige Nachricht geschickt und sofort bereut',
            'gesagt ich sei drueber hinweg obwohl ich taeglich daran dachte',
            'mich wegen einer kleinen aufmerksamen Geste verliebt',
            'mich zurueckgezogen als es ploetzlich ernst wurde',
            'nach aussen cool gewirkt und innerlich vor einem Date Panik gehabt',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he reescrito un mensaje diez veces antes de enviarlo',
            'he esperado que la otra persona escriba primero mientras revisaba el movil',
            'he interpretado mal una senal porque queria que fuera cierta',
            'he imaginado una cita perfecta que nunca ocurrio',
            'he guardado mis sentimientos aunque el momento parecia ideal',
            'he recordado un primer beso durante semanas',
            'he sentido celos y he actuado como si no me importara',
            'he enviado un mensaje arriesgado y me he arrepentido al instante',
            'he dicho que ya lo supere mientras seguia pensandolo cada dia',
            'me he enamorado por un gesto pequeno y muy atento',
            'me he alejado cuando una conexion se volvio seria',
            'he parecido seguro por fuera mientras me ponia nervioso antes de una cita',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'friendship_drama',
        title: 'Friendship Drama',
        description: 'Messy social dynamics, loyalty tests, and hard truths.',
        categories: ['social', 'confessions', 'moral_gray'],
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'kept a friend secret because I did not want to pick sides',
            'felt left out and pretended I did not care',
            'cancelled plans and then saw everyone together online',
            'given advice I did not follow in my own life',
            'stayed in a group chat just to keep the peace',
            'avoided one friend because another friend disliked them',
            'shared a private story and later regretted it',
            'forgiven someone but not trusted them the same way again',
            'agreed with a plan I knew I did not want',
            'realized I was the one causing the misunderstanding',
            'distanced myself without clearly explaining why',
            'defended a friend in public and challenged them in private',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'ein Geheimnis von Freunden behalten weil ich keine Seite waehlen wollte',
            'mich ausgeschlossen gefuehlt und so getan als waere es mir egal',
            'Plaene abgesagt und spaeter online gesehen dass alle zusammen waren',
            'einen Rat gegeben den ich selbst nie befolgt habe',
            'in einem Gruppenchat geblieben nur um Streit zu vermeiden',
            'eine Person gemieden weil eine andere sie nicht mochte',
            'eine private Geschichte weitergegeben und es spaeter bereut',
            'jemandem vergeben aber nie wieder gleich vertraut',
            'einem Plan zugestimmt obwohl ich ihn nicht wollte',
            'gemerkt dass ich selbst das Missverstaendnis ausgeloest habe',
            'Abstand genommen ohne den Grund klar zu sagen',
            'einen Freund oeffentlich verteidigt und ihn privat kritisch angesprochen',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he guardado un secreto entre amigos para no elegir un bando',
            'me he sentido fuera del grupo y he fingido que no importaba',
            'he cancelado planes y luego vi a todos juntos en linea',
            'he dado un consejo que yo mismo no segui',
            'me he quedado en un chat grupal solo para evitar conflictos',
            'he evitado a un amigo porque otro no lo soportaba',
            'he contado algo privado y luego me arrepenti',
            'he perdonado a alguien pero nunca volvi a confiar igual',
            'he aceptado un plan que en realidad no queria',
            'he descubierto que yo era la causa del malentendido',
            'me he distanciado sin explicar claramente el motivo',
            'he defendido a un amigo en publico y lo confronte en privado',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'work_chaos',
        title: 'Work Chaos',
        description: 'Office pressure, team dynamics, and career decisions.',
        categories: ['social', 'risk', 'moral_gray'],
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'joined a call while still mentally in weekend mode',
            'nodded through feedback I did not fully understand',
            'sent an email and found a typo one second later',
            'forgot to hit reply all and changed the whole context',
            'taken on extra work before checking my real capacity',
            'postponed a hard conversation until it became urgent',
            'stayed late to fix a task I could have asked help for',
            'said yes in a meeting and changed my mind afterward',
            'kept a strong idea to myself to avoid conflict',
            'overprepared for a presentation and still felt underprepared',
            'celebrated finishing one task while five new ones appeared',
            'questioned my career plan after one exhausting week',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'an einem Call teilgenommen obwohl ich gedanklich noch im Wochenende war',
            'Feedback abgenickt das ich nicht komplett verstanden habe',
            'eine Mail gesendet und eine Sekunde spaeter einen Fehler gesehen',
            'vergessen auf alle zu antworten und damit den Kontext veraendert',
            'zusatzliche Aufgaben angenommen ohne meine Kapazitaet zu pruefen',
            'ein schwieriges Gespraech aufgeschoben bis es dringend wurde',
            'lange gearbeitet um etwas allein zu loesen obwohl Hilfe moeglich war',
            'im Meeting ja gesagt und spaeter die Meinung geaendert',
            'eine gute Idee fuer mich behalten um Konflikte zu vermeiden',
            'eine Praesentation uebervorbereitet und mich trotzdem unsicher gefuehlt',
            'eine erledigte Aufgabe gefeiert waehrend fuenf neue auftauchten',
            'nach einer anstrengenden Woche meinen Karriereplan hinterfragt',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he entrado a una llamada aun pensando como si fuera fin de semana',
            'he asentido a un comentario que no entendi del todo',
            'he enviado un correo y vi un error un segundo despues',
            'he olvidado responder a todos y cambie todo el contexto',
            'he aceptado trabajo extra sin revisar mi capacidad real',
            'he aplazado una conversacion dificil hasta que fue urgente',
            'me he quedado tarde para arreglar algo que podia pedir ayuda',
            'he dicho que si en una reunion y luego cambie de opinion',
            'he guardado una buena idea para evitar conflicto',
            'he preparado demasiado una presentacion y aun asi me senti inseguro',
            'he celebrado terminar una tarea mientras llegaron cinco nuevas',
            'he cuestionado mi plan profesional despues de una semana dura',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'travel_mishaps',
        title: 'Travel Mishaps',
        description:
            'Unexpected turns, navigation fails, and adventure stories.',
        categories: ['risk', 'social', 'embarrassing'],
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'booked a trip and forgotten one important detail',
            'taken the wrong train and called it an adventure',
            'arrived at the gate right as boarding was closing',
            'packed for weather that never showed up',
            'used offline maps and still managed to get lost',
            'chosen a random restaurant and found a hidden favorite',
            'mispronounced a place name with full confidence',
            'planned a strict itinerary and ignored it on day one',
            'carried way too much and still forgot something essential',
            'missed a turn and discovered a better route',
            'made friends with strangers during a delay',
            'returned from vacation needing another vacation',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'eine Reise gebucht und ein wichtiges Detail vergessen',
            'den falschen Zug genommen und es als Abenteuer verkauft',
            'das Gate genau beim letzten Boarding erreicht',
            'fuer Wetter gepackt das nie eingetreten ist',
            'Offline Karten genutzt und mich trotzdem verlaufen',
            'spontan ein Restaurant gewaehlt und einen Lieblingsort gefunden',
            'einen Ortsnamen selbstsicher falsch ausgesprochen',
            'einen strengen Plan gemacht und ihn am ersten Tag ignoriert',
            'viel zu viel getragen und trotzdem etwas Wichtiges vergessen',
            'eine Abzweigung verpasst und dadurch den besseren Weg gefunden',
            'waehrend einer Verspaetung neue Leute kennengelernt',
            'aus dem Urlaub zurueckgekommen und noch einen Urlaub gebraucht',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he reservado un viaje y olvide un detalle clave',
            'he tomado el tren equivocado y lo llame aventura',
            'he llegado a la puerta justo cuando cerraba el embarque',
            'he empacado para un clima que nunca aparecio',
            'he usado mapas sin conexion y aun asi me perdi',
            'he elegido un restaurante al azar y encontre un favorito',
            'he pronunciado mal un lugar con total seguridad',
            'he hecho un itinerario estricto y lo ignore el primer dia',
            'he cargado demasiado y aun asi olvide algo importante',
            'he perdido un giro y descubri una ruta mejor',
            'he hecho amigos con desconocidos durante un retraso',
            'he vuelto de vacaciones necesitando otras vacaciones',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'digital_life',
        title: 'Digital Life',
        description: 'Online habits, social media moments, and tech fails.',
        categories: ['social', 'confessions', 'embarrassing'],
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'opened an app for one minute and lost half an hour',
            'typed a long comment and deleted it before posting',
            'screenshot a conversation to ask for a second opinion',
            'looked up an old profile and scrolled way too far',
            'left a voice note and regretted my tone afterward',
            'posted something and checked reactions too often',
            'muted a chat because notifications took over my focus',
            'forgotten a password and reset it three times in one week',
            'joined a trend late and pretended I discovered it first',
            'accidentally liked a very old post while lurking',
            'started a digital cleanup and made my home screen worse',
            'read terms and conditions only after clicking accept',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'eine App nur kurz geoeffnet und eine halbe Stunde verloren',
            'einen langen Kommentar geschrieben und vor dem Senden geloescht',
            'einen Chatverlauf gescreenshottet um eine zweite Meinung zu holen',
            'ein altes Profil gesucht und viel zu weit runtergescrollt',
            'eine Sprachnachricht geschickt und meinen Ton danach bereut',
            'etwas gepostet und staendig auf Reaktionen geschaut',
            'einen Chat stummgeschaltet weil die Meldungen meinen Fokus geklaut haben',
            'ein Passwort vergessen und es dreimal in einer Woche neu gesetzt',
            'einen Trend spaet mitgemacht und getan als haette ich ihn entdeckt',
            'beim Stoebern aus Versehen einen uralten Beitrag geliked',
            'digital aufgeraeumt und den Startbildschirm schlechter gemacht',
            'Bedingungen erst gelesen nachdem ich akzeptiert hatte',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he abierto una app un minuto y perdi media hora',
            'he escrito un comentario largo y lo borre antes de publicarlo',
            'he tomado captura de un chat para pedir segunda opinion',
            'he buscado un perfil antiguo y deslice demasiado hacia abajo',
            'he enviado una nota de voz y luego me arrepenti del tono',
            'he publicado algo y revise reacciones demasiadas veces',
            'he silenciado un chat porque las notificaciones me quitaban foco',
            'he olvidado una contrasena y la cambie tres veces en una semana',
            'me he unido tarde a una tendencia y fingi descubrirla primero',
            'he dado me gusta por accidente a una publicacion muy antigua',
            'he intentado ordenar mi vida digital y empeore mi pantalla principal',
            'he leido condiciones solo despues de aceptar',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'family_dynamics',
        title: 'Family Dynamics',
        description: 'Generational stories, traditions, and chaotic love.',
        categories: ['deep', 'social', 'confessions'],
        isPremium: true,
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'noticed I sound exactly like one of my parents',
            'kept peace at dinner by changing the subject quickly',
            'broken a family tradition and felt strangely relieved',
            'learned a family story years later than everyone else',
            'called home for advice and pretended I already knew the answer',
            'avoided one topic because I knew it would start a debate',
            'felt grateful for family support while still needing more space',
            'promised to visit soon and then delayed it again',
            'tried to mediate a family argument and made it louder',
            'inherited a habit I once said I would never copy',
            'realized an older relative was right much later',
            'found comfort in a routine I once called old fashioned',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'gemerkt dass ich genau wie ein Elternteil klinge',
            'beim Essen das Thema gewechselt um Frieden zu halten',
            'eine Familientradition gebrochen und mich unerwartet erleichtert gefuehlt',
            'eine Familiengeschichte erst Jahre spaeter erfahren',
            'zu Hause um Rat gefragt und so getan als wuesste ich die Antwort schon',
            'ein Thema gemieden weil ich wusste dass es Streit ausloest',
            'Dankbarkeit fuer meine Familie gefuehlt und trotzdem mehr Abstand gebraucht',
            'einen baldigen Besuch versprochen und wieder verschoben',
            'einen Familienkonflikt schlichten wollen und ihn lauter gemacht',
            'eine Angewohnheit uebernommen die ich frueher kritisiert habe',
            'erst viel spaeter erkannt dass eine aeltere Person recht hatte',
            'Trost in einer Routine gefunden die ich frueher altmodisch nannte',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he notado que hablo igual que uno de mis padres',
            'he cambiado de tema en la cena para mantener la paz',
            'he roto una tradicion familiar y senti alivio',
            'he conocido una historia familiar muchos anos despues',
            'he llamado a casa por consejo y fingi que ya sabia la respuesta',
            'he evitado un tema porque sabia que causaria debate',
            'he agradecido el apoyo familiar y aun asi necesite distancia',
            'he prometido visitar pronto y lo volvi a posponer',
            'he intentado mediar una discusion familiar y la hice mas intensa',
            'he heredado un habito que antes criticaba',
            'me he dado cuenta tarde de que un mayor tenia razon',
            'he encontrado calma en una rutina que antes llamaba anticuada',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'bold_choices',
        title: 'Bold Choices',
        description:
            'Courage moments, decisive moves, and uncomfortable leaps.',
        categories: ['risk', 'deep', 'moral_gray'],
        isPremium: true,
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'made a big decision with less certainty than I admitted',
            'said no to something good because it was not right for me',
            'taken a chance before feeling fully ready',
            'defended my boundary when it would have been easier to stay quiet',
            'walked away from a role that looked perfect on paper',
            'chosen long term peace over short term approval',
            'admitted I needed help before reaching my limit',
            'asked for what I wanted even though rejection felt likely',
            'changed plans suddenly because my priorities became clearer',
            'accepted being misunderstood to stay true to myself',
            'started over in one area of life from zero',
            'trusted my instincts when logic and fear were arguing loudly',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'eine grosse Entscheidung mit weniger Sicherheit getroffen als ich gezeigt habe',
            'zu etwas Gutem nein gesagt weil es nicht zu mir passte',
            'eine Chance genutzt bevor ich mich ganz bereit gefuehlt habe',
            'eine klare Grenze gesetzt obwohl Schweigen einfacher gewesen waere',
            'eine Rolle verlassen die auf dem Papier perfekt aussah',
            'langfristige Ruhe ueber kurzfristige Zustimmung gestellt',
            'frueh zugegeben dass ich Hilfe brauche',
            'klar gesagt was ich will obwohl Ablehnung moeglich war',
            'Plaene abrupt geaendert weil meine Prioritaeten klarer wurden',
            'in Kauf genommen missverstanden zu werden um mir treu zu bleiben',
            'in einem Lebensbereich komplett neu angefangen',
            'meinem Bauchgefuehl vertraut obwohl Kopf und Angst laut waren',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he tomado una decision grande con menos certeza de la que mostre',
            'he dicho no a algo bueno porque no era para mi',
            'he tomado una oportunidad antes de sentirme listo',
            'he defendido un limite cuando era mas facil callar',
            'he dejado un rol que parecia perfecto en papel',
            'he elegido paz a largo plazo sobre aprobacion inmediata',
            'he admitido que necesitaba ayuda antes de llegar al limite',
            'he pedido lo que queria aunque podia ser rechazado',
            'he cambiado planes de golpe porque vi prioridades mas claras',
            'he aceptado ser malinterpretado para ser fiel a mi mismo',
            'he empezado de cero en una parte de mi vida',
            'he confiado en mi intuicion cuando la logica y el miedo discutian',
          ],
          closers: _closersEs,
        ),
      ),
      CreatorPack(
        id: 'secret_habits',
        title: 'Secret Habits',
        description: 'Private routines, little rituals, and hidden quirks.',
        categories: ['confessions', 'social', 'embarrassing'],
        isPremium: true,
        startersEn: _buildPrompts(
          prefix: 'Never have I ever',
          starts: [
            'created a tiny routine that makes no sense to anyone else',
            'talked to myself out loud while solving a problem',
            'organized something by a rule only I understand',
            'saved random notes because they felt too useful to delete',
            'kept a comfort item longer than I like to admit',
            'checked the same thing twice even after confirming it',
            'made a private playlist for one specific mood',
            'used a weird shortcut daily because it somehow works',
            'rehearsed a conversation in advance in my head',
            'had a productivity ritual that looked chaotic from the outside',
            'kept an old object purely for nostalgia',
            'invented a personal rule and followed it seriously',
          ],
          closers: _closersEn,
        ),
        startersDe: _buildPrompts(
          prefix: 'Ich hab noch nie',
          starts: [
            'eine kleine Routine entwickelt die nur fuer mich Sinn ergibt',
            'laut mit mir selbst gesprochen um ein Problem zu loesen',
            'etwas nach einer Regel sortiert die nur ich verstehe',
            'zufaellige Notizen aufgehoben weil sie zu nuetzlich wirkten',
            'einen Gegenstand aus Gewohnheit laenger behalten als gedacht',
            'etwas doppelt geprueft obwohl ich schon sicher war',
            'eine geheime Playlist fuer genau eine Stimmung erstellt',
            'einen seltsamen Shortcut taeglich genutzt weil er funktioniert',
            'ein Gespraech im Kopf vorab geuebt',
            'ein Produktivitaetsritual gehabt das von aussen chaotisch wirkte',
            'einen alten Gegenstand nur aus Nostalgie behalten',
            'eine persoenliche Regel erfunden und konsequent befolgt',
          ],
          closers: _closersDe,
        ),
        startersEs: _buildPrompts(
          prefix: 'Nunca',
          starts: [
            'he creado una rutina pequena que solo yo entiendo',
            'he hablado solo en voz alta para resolver un problema',
            'he ordenado algo con una regla que solo yo conozco',
            'he guardado notas aleatorias porque parecian utiles',
            'he conservado un objeto de comodidad mas tiempo del esperado',
            'he revisado lo mismo dos veces aunque ya estaba seguro',
            'he hecho una lista de musica privada para un solo estado de animo',
            'he usado un atajo raro cada dia porque funciona',
            'he ensayado una conversacion en mi cabeza antes de tenerla',
            'he tenido un ritual de productividad que parecia caos por fuera',
            'he guardado un objeto viejo solo por nostalgia',
            'he inventado una regla personal y la segui en serio',
          ],
          closers: _closersEs,
        ),
      ),
    ];

    _validatePacks(packs);
    return packs;
  }

  static CreatorPack? byId(String id) {
    for (final pack in all) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}
