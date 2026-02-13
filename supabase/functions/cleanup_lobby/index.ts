import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type CleanupLobbyRequest = {
  lobby_id: string;
};

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!supabaseUrl || !serviceRoleKey) {
      throw new Error("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env var.");
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return json({ error: "Missing bearer token." }, 401);
    }

    const token = authHeader.replace("Bearer ", "").trim();

    const body = (await req.json()) as CleanupLobbyRequest;
    const lobbyId = String(body?.lobby_id ?? "").trim();
    if (!lobbyId) {
      return json({ error: "lobby_id is required." }, 400);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const userResult = await admin.auth.getUser(token);
    if (userResult.error || !userResult.data.user) {
      return json({ error: "Unauthorized." }, 401);
    }
    const requesterUserId = userResult.data.user.id;

    const lobbyResult = await admin
      .from("lobbies")
      .select("id,host_user_id")
      .eq("id", lobbyId)
      .maybeSingle();

    if (lobbyResult.error) {
      return json({ error: lobbyResult.error.message }, 400);
    }

    if (!lobbyResult.data) {
      return json({ error: "Lobby not found." }, 404);
    }

    if (lobbyResult.data.host_user_id !== requesterUserId) {
      return json({ error: "Only host_user_id may trigger cleanup." }, 403);
    }

    const roundsResult = await admin
      .from("rounds")
      .select("id")
      .eq("lobby_id", lobbyId);

    if (roundsResult.error) {
      return json({ error: roundsResult.error.message }, 400);
    }

    const roundIds = (roundsResult.data ?? []).map((r) => r.id as string);

    if (roundIds.length > 0) {
      const deleteAnswers = await admin
        .from("answers")
        .delete()
        .in("round_id", roundIds);

      if (deleteAnswers.error) {
        return json({ error: deleteAnswers.error.message }, 400);
      }
    }

    const deleteRounds = await admin
      .from("rounds")
      .delete()
      .eq("lobby_id", lobbyId);

    if (deleteRounds.error) {
      return json({ error: deleteRounds.error.message }, 400);
    }

    const deletePlayers = await admin
      .from("players")
      .delete()
      .eq("lobby_id", lobbyId);

    if (deletePlayers.error) {
      return json({ error: deletePlayers.error.message }, 400);
    }

    const deleteLobby = await admin
      .from("lobbies")
      .delete()
      .eq("id", lobbyId);

    if (deleteLobby.error) {
      return json({ error: deleteLobby.error.message }, 400);
    }

    return json({ ok: true, lobby_id: lobbyId });
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
