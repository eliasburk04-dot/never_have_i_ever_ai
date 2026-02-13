const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Language = "en" | "de" | "es";

type DeckStatement = {
  id: string;
  language: Language;
  riskLevel: number;
  text: string;
};

type GenerateStatementsRequest = {
  language: Language;
  risk_level: number;
  previous_ids?: string[];
};

type GroqResponse = {
  choices?: Array<{
    message?: {
      content?: string;
    };
  }>;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = (await req.json()) as GenerateStatementsRequest;

    const language = parseLanguage(body.language);
    const riskLevel = parseRiskLevel(body.risk_level);
    const previousIds = Array.isArray(body.previous_ids)
      ? body.previous_ids.filter((id) => typeof id === "string")
      : [];

    const deck = buildDeck();
    const selected = selectDeckStatement({
      deck,
      language,
      riskLevel,
      previousIds,
    });

    if (!selected) {
      return json(
        {
          error: `No deck statements available for language=${language}, risk_level=${riskLevel}`,
        },
        409,
      );
    }

    const rewritten = await rewriteWithGroq({
      baseText: selected.text,
      language,
      riskLevel,
    });

    return json({
      statement: rewritten,
      risk_level: riskLevel,
      statement_id: selected.id,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error";
    return json({ error: message }, 400);
  }
});

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function parseLanguage(value: unknown): Language {
  if (value === "en" || value === "de" || value === "es") {
    return value;
  }
  throw new Error("language must be one of: en, de, es");
}

function parseRiskLevel(value: unknown): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 1 || parsed > 5) {
    throw new Error("risk_level must be an integer between 1 and 5");
  }
  return parsed;
}

function selectDeckStatement(args: {
  deck: DeckStatement[];
  language: Language;
  riskLevel: number;
  previousIds: string[];
}): DeckStatement | null {
  const previous = new Set(args.previousIds);

  const available = args.deck
    .filter((item) => item.language === args.language && item.riskLevel === args.riskLevel)
    .filter((item) => !previous.has(item.id))
    .sort((a, b) => a.id.localeCompare(b.id));

  if (available.length === 0) {
    return null;
  }

  const seed = hashString(
    `${args.language}:${args.riskLevel}:${[...previous].sort().join("|")}`,
  );
  const index = seed % available.length;
  return available[index];
}

function hashString(value: string): number {
  let hash = 0;
  for (let i = 0; i < value.length; i += 1) {
    hash = (hash * 31 + value.charCodeAt(i)) >>> 0;
  }
  return hash;
}

async function rewriteWithGroq(args: {
  baseText: string;
  language: Language;
  riskLevel: number;
}): Promise<string> {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  const model = Deno.env.get("GROQ_MODEL") ?? "llama-3.1-8b-instant";

  if (!apiKey) {
    return args.baseText;
  }

  const systemPrompt = [
    "You rewrite Never Have I Ever statements.",
    "Keep the meaning and same risk level.",
    "Make tone fresh and concise.",
    "Do not make it more extreme than the original.",
    "Return only the rewritten statement, one sentence.",
  ].join(" ");

  const userPrompt = [
    `Language: ${args.language}`,
    `Risk level: ${args.riskLevel}`,
    `Original statement: ${args.baseText}`,
  ].join("\n");

  const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      temperature: 0.4,
      max_tokens: 80,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
    }),
  });

  if (!response.ok) {
    return args.baseText;
  }

  const data = (await response.json()) as GroqResponse;
  const rewritten = data.choices?.[0]?.message?.content?.trim();
  return rewritten && rewritten.length > 0 ? rewritten : args.baseText;
}

function buildDeck(): DeckStatement[] {
  const deck: DeckStatement[] = [];

  for (const language of ["en", "de", "es"] as const) {
    const templates = templatesByLanguage[language];
    const actions = actionsByLanguage[language];

    for (let risk = 1; risk <= 5; risk += 1) {
      const template = templates[risk - 1];
      for (let i = 0; i < actions.length; i += 1) {
        deck.push({
          id: `${language}-r${risk}-${i + 1}`,
          language,
          riskLevel: risk,
          text: template.replace("{action}", actions[i]),
        });
      }
    }
  }

  return deck;
}

const templatesByLanguage: Record<Language, [string, string, string, string, string]> = {
  en: [
    "Never have I ever {action}.",
    "Never have I ever {action} and hoped nobody noticed.",
    "Never have I ever {action} and then lied to avoid embarrassment.",
    "Never have I ever {action} and let someone else take the blame.",
    "Never have I ever {action} even though I knew it could seriously damage trust.",
  ],
  de: [
    "Ich habe noch nie {action}.",
    "Ich habe noch nie {action} und gehofft, dass es niemand merkt.",
    "Ich habe noch nie {action} und danach gelogen, um Peinlichkeit zu vermeiden.",
    "Ich habe noch nie {action} und jemand anderen die Schuld tragen lassen.",
    "Ich habe noch nie {action}, obwohl ich wusste, dass es Vertrauen ernsthaft verletzen kann.",
  ],
  es: [
    "Nunca he {action}.",
    "Nunca he {action} y esperado que nadie lo notara.",
    "Nunca he {action} y luego mentido para evitar verguenza.",
    "Nunca he {action} y dejado que otra persona cargara con la culpa.",
    "Nunca he {action} aunque sabia que podia danar seriamente la confianza.",
  ],
};

const actionsByLanguage: Record<Language, string[]> = {
  en: [
    "forgotten to answer a message for days",
    "pretended I had seen a movie I never watched",
    "arrived late and blamed traffic when it was my fault",
    "taken food from a roommate without asking",
    "laughed at a joke I did not understand",
    "copied homework from a friend",
    "left a group chat because of drama and quietly rejoined later",
    "looked at my phone during an important conversation",
    "said I was almost there while still at home",
    "canceled plans at the last minute for no real reason",
    "searched my own name online",
    "used someone else's streaming account without permission",
    "re-gifted a present",
    "stayed silent when I should have apologized",
    "checked an ex profile more than once in one day",
    "snoozed an alarm so long that I missed something important",
    "taken credit for a team idea",
    "ignored a family call and said my battery died",
    "read a spoiler and still acted surprised",
    "hidden snacks so I would not have to share",
  ],
  de: [
    "tagelang nicht auf eine Nachricht geantwortet",
    "so getan, als haette ich einen Film gesehen, den ich nie geschaut habe",
    "mich verspaetet und den Verkehr beschuldigt, obwohl ich selbst schuld war",
    "Essen von Mitbewohnern genommen, ohne zu fragen",
    "ueber einen Witz gelacht, den ich nicht verstanden habe",
    "Hausaufgaben von einer Freundin oder einem Freund abgeschrieben",
    "einen Gruppenchat wegen Drama verlassen und spaeter heimlich wieder betreten",
    "waehrend eines wichtigen Gespraechs auf mein Handy geschaut",
    "gesagt, ich sei gleich da, waehrend ich noch zu Hause war",
    "Plaene in letzter Minute ohne guten Grund abgesagt",
    "meinen eigenen Namen online gesucht",
    "den Streaming Account von jemand anderem ohne Erlaubnis benutzt",
    "ein Geschenk weiter verschenkt",
    "geschwiegen, obwohl ich mich haette entschuldigen sollen",
    "das Profil einer Ex Person mehrmals an einem Tag gecheckt",
    "einen Wecker so oft verschoben, dass ich etwas Wichtiges verpasst habe",
    "die Anerkennung fuer eine Teamidee genommen",
    "einen Anruf aus der Familie ignoriert und gesagt, mein Akku sei leer",
    "einen Spoiler gelesen und trotzdem ueberrascht getan",
    "Snacks versteckt, damit ich nicht teilen muss",
  ],
  es: [
    "dejado un mensaje sin responder durante dias",
    "fingido que vi una pelicula que nunca vi",
    "llegado tarde y culpado al trafico cuando fue mi culpa",
    "tomado comida de un companero de piso sin pedir permiso",
    "reido de un chiste que no entendi",
    "copiado la tarea de una amistad",
    "salido de un chat grupal por drama y vuelto en silencio despues",
    "mirado el telefono durante una conversacion importante",
    "dicho que ya casi llegaba cuando aun estaba en casa",
    "cancelado planes a ultimo minuto sin una razon real",
    "buscado mi propio nombre en internet",
    "usado la cuenta de streaming de otra persona sin permiso",
    "regalado de nuevo un regalo que me dieron",
    "quedado en silencio cuando debi pedir perdon",
    "revisado el perfil de mi ex mas de una vez en un dia",
    "puesto la alarma en repeticion tanto que perdi algo importante",
    "quedado con el credito de una idea del equipo",
    "ignorado una llamada familiar y dicho que no tenia bateria",
    "leido un spoiler y aun asi actuado con sorpresa",
    "escondido snacks para no compartir",
  ],
};
