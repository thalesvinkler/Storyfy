import { createClient } from "npm:@supabase/supabase-js@2";

const appId = Deno.env.get("INSTAGRAM_APP_ID") ?? "1372485041694551";
const appSecret = Deno.env.get("INSTAGRAM_APP_SECRET") ?? "";
const openAIKey = Deno.env.get("OPENAI_API_KEY") ?? "";
const publicBaseURL = Deno.env.get("PUBLIC_BASE_URL") ?? "";
const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { persistSession: false } },
);

Deno.serve(async (request) => {
  const url = new URL(request.url);
  const route = routePath(url.pathname);

  if (request.method === "GET" && route === "/health") return json({ status: "ok" });
  if (request.method === "GET" && route === "/instagram/connect") return connectInstagram();
  if (request.method === "GET" && route === "/instagram/callback") return instagramCallback(url);
  if (request.method === "GET" && route === "/instagram/profile") return instagramProfile(url);
  if (request.method === "POST" && route === "/caption") return generateCaption(request);
  return json({ error: "not_found" }, 404);
});

function routePath(pathname: string) {
  const marker = "/storyfy-api";
  const index = pathname.indexOf(marker);
  return index >= 0 ? pathname.slice(index + marker.length) || "/" : pathname;
}

async function connectInstagram() {
  if (!appSecret || !publicBaseURL) return json({ error: "instagram_not_configured" }, 503);
  const state = crypto.randomUUID();
  const { error } = await supabase.from("instagram_oauth_states").insert({ state });
  if (error) return json({ error: "state_creation_failed" }, 500);

  const authorizationURL = new URL("https://www.instagram.com/oauth/authorize");
  authorizationURL.search = new URLSearchParams({
    enable_fb_login: "0",
    force_authentication: "1",
    client_id: appId,
    redirect_uri: `${publicBaseURL}/instagram/callback`,
    response_type: "code",
    scope: "instagram_business_basic",
    state,
  }).toString();
  return Response.redirect(authorizationURL.toString(), 302);
}

async function instagramCallback(url: URL) {
  const state = url.searchParams.get("state");
  const code = url.searchParams.get("code")?.replace(/#_$/, "");
  if (!state || !code) return json({ error: "invalid_callback" }, 400);

  const { data: storedState } = await supabase.from("instagram_oauth_states").select("state").eq("state", state).maybeSingle();
  if (!storedState) return json({ error: "invalid_oauth_state" }, 400);
  await supabase.from("instagram_oauth_states").delete().eq("state", state);

  const accessToken = await exchangeCode(code);
  const profile = await fetchInstagramProfile(accessToken);
  const { data, error } = await supabase.from("instagram_connections").insert({
    instagram_user_id: profile.userId,
    username: profile.username,
    access_token: accessToken,
    captions: profile.captions,
  }).select("id").single();
  if (error) return json({ error: "connection_creation_failed" }, 500);
  return Response.redirect(`storyfy://instagram-auth?connection_id=${data.id}`, 302);
}

async function instagramProfile(url: URL) {
  const connectionId = url.searchParams.get("connection_id");
  if (!connectionId) return json({ error: "missing_connection" }, 400);
  const { data } = await supabase.from("instagram_connections").select("username,captions").eq("id", connectionId).maybeSingle();
  if (!data) return json({ error: "invalid_connection" }, 401);
  return json({ username: data.username, captions: data.captions });
}

async function generateCaption(request: Request) {
  if (!openAIKey) return json({ error: "openai_not_configured" }, 503);
  const payload = await request.json();
  const examples = String(payload.writingExamples ?? "").trim();
  const input = [
    `Crie uma legenda para ${payload.month}, com ${payload.photoCount} fotos.`,
    `Momentos identificados: ${(payload.events ?? []).join(", ") || "momentos do mês"}.`,
    examples ? `Imite o estilo destes exemplos sem copiar frases:\n${examples}` : "Use um tom pessoal, direto e afetuoso.",
    `Crie a variação ${Number(payload.variant ?? 0) + 1}.`,
  ].join("\n\n");
  const response = await fetch("https://api.openai.com/v1/responses", {
    method: "POST",
    headers: { Authorization: `Bearer ${openAIKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_MODEL") ?? "gpt-5.4-mini",
      instructions: "Escreva legendas naturais em português do Brasil. Entregue somente a legenda final.",
      input,
      max_output_tokens: 350,
    }),
  });
  if (!response.ok) return json({ error: "generation_failed" }, 502);
  const result = await response.json();
  const caption = result.output_text ?? result.output?.flatMap((item: any) => item.content ?? []).find((item: any) => item.type === "output_text")?.text;
  return caption ? json({ caption: caption.trim() }) : json({ error: "empty_caption" }, 502);
}

async function exchangeCode(code: string) {
  const body = new URLSearchParams({
    client_id: appId,
    client_secret: appSecret,
    grant_type: "authorization_code",
    redirect_uri: `${publicBaseURL}/instagram/callback`,
    code,
  });
  const response = await fetch("https://api.instagram.com/oauth/access_token", { method: "POST", body });
  if (!response.ok) throw new Error(await response.text());
  return (await response.json()).access_token;
}

async function fetchInstagramProfile(accessToken: string) {
  const url = new URL("https://graph.instagram.com/me");
  url.searchParams.set("fields", "user_id,username,media.limit(50){caption,timestamp}");
  url.searchParams.set("access_token", accessToken);
  const response = await fetch(url);
  if (!response.ok) throw new Error(await response.text());
  const data = await response.json();
  return {
    userId: String(data.user_id),
    username: data.username,
    captions: (data.media?.data ?? []).map((item: any) => item.caption).filter(Boolean),
  };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json; charset=utf-8" } });
}
