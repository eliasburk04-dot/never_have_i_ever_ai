const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type PlayerStats = {
  player_id: string;
  nickname?: string;
  score?: number;
  avg_response_time_ms?: number;
  yes_ratio?: number;
  solo_confessions?: number;
};

type FinalSummaryRequest = {
  stats: {
    players?: PlayerStats[];
    rounds_played?: number;
    language?: string;
    [key: string]: unknown;
  };
};

type SummaryPlayer = {
  player_id: string;
  nickname: string;
  value: number;
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
    const body = (await req.json()) as FinalSummaryRequest;

    if (!body?.stats || typeof body.stats !== "object") {
      throw new Error("stats is required");
    }

    const players = normalizePlayers(body.stats.players ?? []);
    if (players.length === 0) {
      return json({
        winner: null,
        fastest: null,
        bravest: null,
        highlights: ["No player stats were provided."],
      });
    }

    const winner = pickWinner(players);
    const fastest = pickFastest(players);
    const bravest = pickBravest(players);

    const highlights = await buildHighlights({
      stats: body.stats,
      winner,
      fastest,
      bravest,
    });

    return json({
      winner,
      fastest,
      bravest,
      highlights,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error";
    return json({ error: message }, 400);
  }
});

function normalizePlayers(players: PlayerStats[]): Required<PlayerStats>[] {
  return players.map((player, index) => ({
    player_id: String(player.player_id ?? `player_${index + 1}`),
    nickname: String(player.nickname ?? `Player ${index + 1}`),
    score: Number(player.score ?? 0),
    avg_response_time_ms: Math.max(0, Number(player.avg_response_time_ms ?? 0)),
    yes_ratio: clamp(Number(player.yes_ratio ?? 0), 0, 1),
    solo_confessions: Math.max(0, Number(player.solo_confessions ?? 0)),
  }));
}

function pickWinner(players: Required<PlayerStats>[]): SummaryPlayer {
  const sorted = [...players].sort((a, b) => b.score - a.score || a.player_id.localeCompare(b.player_id));
  return {
    player_id: sorted[0].player_id,
    nickname: sorted[0].nickname,
    value: sorted[0].score,
  };
}

function pickFastest(players: Required<PlayerStats>[]): SummaryPlayer {
  const sorted = [...players].sort((a, b) =>
    a.avg_response_time_ms - b.avg_response_time_ms || a.player_id.localeCompare(b.player_id)
  );
  return {
    player_id: sorted[0].player_id,
    nickname: sorted[0].nickname,
    value: sorted[0].avg_response_time_ms,
  };
}

function pickBravest(players: Required<PlayerStats>[]): SummaryPlayer {
  const sorted = [...players].sort((a, b) => {
    if (b.yes_ratio !== a.yes_ratio) return b.yes_ratio - a.yes_ratio;
    if (b.solo_confessions !== a.solo_confessions) return b.solo_confessions - a.solo_confessions;
    return a.player_id.localeCompare(b.player_id);
  });

  const braveryValue = Math.round((sorted[0].yes_ratio * 100) + sorted[0].solo_confessions * 5);

  return {
    player_id: sorted[0].player_id,
    nickname: sorted[0].nickname,
    value: braveryValue,
  };
}

async function buildHighlights(args: {
  stats: Record<string, unknown>;
  winner: SummaryPlayer;
  fastest: SummaryPlayer;
  bravest: SummaryPlayer;
}): Promise<string[]> {
  const apiKey = Deno.env.get("GROQ_API_KEY");
  const model = Deno.env.get("GROQ_MODEL") ?? "llama-3.1-8b-instant";

  const fallback = [
    `${args.winner.nickname} won with ${args.winner.value} points.`,
    `${args.fastest.nickname} was fastest (${args.fastest.value} ms average response).`,
    `${args.bravest.nickname} showed the most courage.`,
  ];

  if (!apiKey) {
    return fallback;
  }

  const systemPrompt = [
    "You create concise game recap highlights.",
    "Return exactly 3 bullet lines.",
    "No markdown, no numbering.",
    "Keep it positive and short.",
  ].join(" ");

  const userPrompt = JSON.stringify({
    winner: args.winner,
    fastest: args.fastest,
    bravest: args.bravest,
    stats: args.stats,
  });

  try {
    const response = await fetch("https://api.groq.com/openai/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        temperature: 0.5,
        max_tokens: 220,
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userPrompt },
        ],
      }),
    });

    if (!response.ok) {
      return fallback;
    }

    const data = (await response.json()) as GroqResponse;
    const raw = data.choices?.[0]?.message?.content?.trim();
    if (!raw) {
      return fallback;
    }

    const lines = raw
      .split(/\r?\n/)
      .map((line) => line.replace(/^[-*\d.\s]+/, "").trim())
      .filter((line) => line.length > 0)
      .slice(0, 3);

    return lines.length > 0 ? lines : fallback;
  } catch {
    return fallback;
  }
}

function clamp(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}
