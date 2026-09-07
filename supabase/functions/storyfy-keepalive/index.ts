import { createClient } from "npm:@supabase/supabase-js@2";

const keepAliveSecret = Deno.env.get("STORYFY_KEEPALIVE_SECRET") ?? "";
const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { persistSession: false } },
);

Deno.serve(async (request) => {
  if (request.method !== "GET" && request.method !== "POST") {
    return json({ error: "method_not_allowed" }, 405);
  }

  if (!keepAliveSecret) return json({ error: "keepalive_not_configured" }, 503);
  if (request.headers.get("x-storyfy-keepalive-secret") !== keepAliveSecret) {
    return json({ error: "unauthorized" }, 401);
  }

  const { error } = await supabase
    .from("caption_usage_events")
    .select("id", { count: "exact", head: true })
    .limit(1);

  if (error) {
    console.error("keepalive_failed", error.code, error.message);
    return json({ error: "keepalive_failed" }, 500);
  }

  return json({ status: "ok", checked_at: new Date().toISOString() });
});

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
