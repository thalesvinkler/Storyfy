import { createClient } from "npm:@supabase/supabase-js@2";

const appId = Deno.env.get("INSTAGRAM_APP_ID") ?? "1372485041694551";
const appSecret = Deno.env.get("INSTAGRAM_APP_SECRET") ?? "";
const publicBaseURL = Deno.env.get("INSTAGRAM_PUBLIC_BASE_URL") ?? "";
const supabase = createClient(
  Deno.env.get("SUPABASE_URL") ?? "",
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "",
  { auth: { persistSession: false } },
);

Deno.serve(async (request) => {
  const url = new URL(request.url);
  const marker = "/instagram-oauth";
  const markerIndex = url.pathname.indexOf(marker);
  const route = markerIndex >= 0 ? url.pathname.slice(markerIndex + marker.length) || "/" : url.pathname;
  try {
    if (request.method === "GET" && route === "/health") return json({ status: "ok" });
    if (request.method === "GET" && route === "/connect") return connect();
    if (request.method === "GET" && route === "/callback") return callback(url);
    if (request.method === "GET" && route === "/profile") return profile(url);
    if (request.method === "POST" && route === "/disconnect") return disconnect(request);
    return json({ error: "not_found" }, 404);
  } catch (error) {
    console.error(error);
    return json({ error: "instagram_request_failed" }, 502);
  }
});

async function connect() {
  if (!appSecret || !publicBaseURL) return json({ error: "instagram_not_configured" }, 503);
  const state = crypto.randomUUID();
  const { error } = await supabase.from("instagram_oauth_states").insert({ state });
  if (error) return json({ error: "state_creation_failed" }, 500);
  const authorizationURL = new URL("https://www.instagram.com/oauth/authorize");
  authorizationURL.search = new URLSearchParams({
    enable_fb_login: "0", force_authentication: "1", client_id: appId,
    redirect_uri: `${publicBaseURL}/callback`, response_type: "code",
    scope: "instagram_business_basic", state,
  }).toString();
  return Response.redirect(authorizationURL.toString(), 302);
}

async function callback(url: URL) {
  const state = url.searchParams.get("state");
  const code = url.searchParams.get("code")?.replace(/#_$/, "");
  if (!state || !code) return json({ error: "invalid_callback" }, 400);
  const { data: storedState } = await supabase.from("instagram_oauth_states").select("state").eq("state", state).maybeSingle();
  if (!storedState) return json({ error: "invalid_oauth_state" }, 400);
  let token;
  try {
    token = await exchangeCode(code);
  } catch (error) {
    console.error("token_exchange", error);
    const reason = error instanceof InstagramTokenError ? error.reason : "unknown";
    return errorPage(`token_exchange_${reason}`);
  }
  await supabase.from("instagram_oauth_states").delete().eq("state", state);
  let instagram;
  try {
    instagram = await fetchProfile(token.accessToken, token.userId);
  } catch (error) {
    console.error("profile_fetch", error);
    const reason = error instanceof InstagramAPIError ? error.reason : "unknown";
    return errorPage(`profile_fetch_${reason}`);
  }
  const { data, error } = await supabase.from("instagram_connections").insert({
    instagram_user_id: instagram.userId, username: instagram.username,
    access_token: token.accessToken, captions: instagram.captions,
  }).select("id").single();
  if (error) {
    console.error("database_save", error.code, error.message);
    return errorPage(`database_save_${error.code ?? "unknown"}`);
  }
  return appReturnPage(data.id);
}

async function profile(url: URL) {
  const connectionId = url.searchParams.get("connection_id");
  if (!connectionId) return json({ error: "missing_connection" }, 400);
  const { data } = await supabase.from("instagram_connections").select("username,captions").eq("id", connectionId).maybeSingle();
  return data ? json(data) : json({ error: "invalid_connection" }, 401);
}

async function disconnect(request: Request) {
  const body = await request.json().catch(() => ({}));
  const connectionId = String(body.connection_id ?? "");
  if (!connectionId) return json({ error: "missing_connection" }, 400);
  const { error } = await supabase.from("instagram_connections").delete().eq("id", connectionId);
  if (error) {
    console.error("instagram_disconnect_failed", error.code, error.message);
    return json({ error: "disconnect_failed" }, 500);
  }
  return json({ status: "disconnected" });
}

async function exchangeCode(code: string) {
  const body = new URLSearchParams({ client_id: appId, client_secret: appSecret,
    grant_type: "authorization_code", redirect_uri: `${publicBaseURL}/callback`, code });
  const response = await fetch("https://api.instagram.com/oauth/access_token", { method: "POST", body });
  if (!response.ok) {
    const details = await response.json().catch(() => ({}));
    const reason = String(details.error_type ?? details.error?.type ?? details.error?.code ?? response.status)
      .toLowerCase().replace(/[^a-z0-9_-]/g, "_").slice(0, 60);
    throw new InstagramTokenError(reason || "unknown");
  }
  const data = await response.json();
  if (!data.access_token || !data.user_id) throw new Error("token: missing access token or user id");
  return { accessToken: data.access_token, userId: String(data.user_id) };
}

class InstagramTokenError extends Error {
  constructor(readonly reason: string) {
    super(reason);
  }
}

async function fetchProfile(accessToken: string, userId: string) {
  const apiVersion = Deno.env.get("INSTAGRAM_API_VERSION") ?? "v25.0";
  const profileURL = new URL(`https://graph.instagram.com/${apiVersion}/me`);
  profileURL.searchParams.set("fields", "user_id,username");
  profileURL.searchParams.set("access_token", accessToken);
  const profileResponse = await fetch(profileURL);
  if (!profileResponse.ok) throw await instagramAPIError(profileResponse, "profile");
  const profile = await profileResponse.json();
  if (!profile.username) throw new Error("profile: missing username");

  const mediaURL = new URL(`https://graph.instagram.com/${apiVersion}/me/media`);
  mediaURL.searchParams.set("fields", "caption,timestamp");
  mediaURL.searchParams.set("limit", "50");
  mediaURL.searchParams.set("access_token", accessToken);
  const mediaResponse = await fetch(mediaURL);
  if (!mediaResponse.ok) throw await instagramAPIError(mediaResponse, "media");
  const media = await mediaResponse.json();
  return { userId, username: profile.username,
    captions: (media.data ?? []).map((item: any) => item.caption).filter(Boolean) };
}

async function instagramAPIError(response: Response, stage: string) {
  const details = await response.json().catch(() => ({}));
  const code = details.error?.code ?? response.status;
  const subcode = details.error?.error_subcode ? `_${details.error.error_subcode}` : "";
  return new InstagramAPIError(`${stage}_${code}${subcode}`);
}

class InstagramAPIError extends Error {
  constructor(readonly reason: string) {
    super(reason);
  }
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}

function appReturnPage(connectionId: string) {
  const appURL = `storyfy://instagram-auth?connection_id=${encodeURIComponent(connectionId)}`;
  return new Response(null, { status: 302, headers: { Location: appURL } });
}

function errorPage(code: string) {
  const safeCode = code.replace(/[^a-zA-Z0-9_-]/g, "");
  const html = `<!doctype html><html lang="pt-BR"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Storyfy</title></head>
  <body style="font-family:-apple-system,sans-serif;text-align:center;padding:48px 24px;background:#111216;color:#f4f4f1">
  <h1>Não foi possível conectar</h1><p style="color:#b0b1b7">Código: ${safeCode}</p><p>Feche esta tela e tente novamente.</p></body></html>`;
  return new Response(html, { status: 200, headers: { "Content-Type": "text/html; charset=utf-8" } });
}
