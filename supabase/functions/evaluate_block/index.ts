const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type EvaluateBlockRequest = {
  avg_yes_ratio: number;
  avg_response_time: number;
  solo_confessions: number;
  current_risk_level?: number;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const body = (await req.json()) as EvaluateBlockRequest;

    const avgYesRatio = clamp(Number(body.avg_yes_ratio), 0, 1);
    const avgResponseTimeMs = Math.max(0, Number(body.avg_response_time));
    const soloConfessions = Math.max(0, Number(body.solo_confessions));
    const currentRisk = body.current_risk_level == null
      ? 3
      : clamp(Math.round(Number(body.current_risk_level)), 1, 5);

    const paceScore = avgResponseTimeMs <= 2500 ? 1 : avgResponseTimeMs >= 7000 ? -1 : 0;
    const honestyScore = avgYesRatio >= 0.65 ? 1 : avgYesRatio <= 0.3 ? -1 : 0;
    const soloScore = soloConfessions >= 2 ? 1 : soloConfessions === 0 ? -1 : 0;

    const adjustment = paceScore + honestyScore + soloScore;
    const nextRiskLevel = clamp(currentRisk + adjustment, 1, 5);

    return json({ next_risk_level: nextRiskLevel });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unknown server error";
    return json({ error: message }, 400);
  }
});

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
