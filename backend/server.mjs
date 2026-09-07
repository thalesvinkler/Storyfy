import http from "node:http";
import crypto from "node:crypto";

const port = Number(process.env.PORT || 8787);
const apiKey = process.env.OPENAI_API_KEY;
const instagramAppID = process.env.INSTAGRAM_APP_ID || "1372485041694551";
const instagramAppSecret = process.env.INSTAGRAM_APP_SECRET;
const publicBaseURL = process.env.PUBLIC_BASE_URL || "https://api-storyfy.taurasystems.com.br";
const pendingStates = new Map();
const instagramConnections = new Map();

const server = http.createServer(async (request, response) => {
  const requestURL = new URL(request.url, publicBaseURL);
  if (request.method === "GET" && requestURL.pathname === "/health") {
    return json(response, 200, { status: "ok" });
  }

  if (request.method === "GET" && requestURL.pathname === "/instagram/connect") {
    if (!instagramAppSecret) return json(response, 503, { error: "instagram_not_configured" });
    const state = crypto.randomBytes(24).toString("hex");
    pendingStates.set(state, Date.now());
    const authorizationURL = new URL("https://www.instagram.com/oauth/authorize");
    authorizationURL.search = new URLSearchParams({
      enable_fb_login: "0",
      force_authentication: "1",
      client_id: instagramAppID,
      redirect_uri: `${publicBaseURL}/instagram/callback`,
      response_type: "code",
      scope: "instagram_business_basic",
      state
    }).toString();
    response.writeHead(302, { Location: authorizationURL.toString() });
    return response.end();
  }

  if (request.method === "GET" && requestURL.pathname === "/instagram/callback") {
    const state = requestURL.searchParams.get("state");
    const code = requestURL.searchParams.get("code")?.replace(/#_$/, "");
    if (!state || !code || !pendingStates.has(state)) return json(response, 400, { error: "invalid_oauth_state" });
    pendingStates.delete(state);
    try {
      const token = await exchangeInstagramCode(code);
      const connectionID = crypto.randomUUID();
      instagramConnections.set(connectionID, token);
      response.writeHead(302, { Location: `storyfy://instagram-auth?connection_id=${encodeURIComponent(connectionID)}` });
      return response.end();
    } catch (error) {
      console.error(error);
      return json(response, 502, { error: "instagram_token_exchange_failed" });
    }
  }

  if (request.method === "GET" && requestURL.pathname === "/instagram/profile") {
    const connectionID = requestURL.searchParams.get("connection_id");
    const token = instagramConnections.get(connectionID);
    if (!token) return json(response, 401, { error: "invalid_connection" });
    try {
      return json(response, 200, await fetchInstagramProfile(token));
    } catch (error) {
      console.error(error);
      return json(response, 502, { error: "instagram_fetch_failed" });
    }
  }

  if (request.method !== "POST" || requestURL.pathname !== "/caption") {
    return json(response, 404, { error: "not_found" });
  }

  if (!apiKey) {
    return json(response, 503, { error: "OPENAI_API_KEY_not_configured" });
  }

  try {
    const payload = await readJSON(request);
    const prompt = buildPrompt(payload);
    const openAIResponse = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || "gpt-5.4-mini",
        instructions: "Você escreve legendas naturais para carrosséis pessoais em português do Brasil. Entregue somente a legenda final, sem explicações ou aspas.",
        input: prompt,
        max_output_tokens: 350
      })
    });

    if (!openAIResponse.ok) {
      const details = await openAIResponse.text();
      console.error("OpenAI error", openAIResponse.status, details);
      return json(response, 502, { error: "generation_failed" });
    }

    const result = await openAIResponse.json();
    const caption = extractOutputText(result);
    if (!caption) return json(response, 502, { error: "empty_caption" });
    return json(response, 200, { caption });
  } catch (error) {
    console.error(error);
    return json(response, 400, { error: "invalid_request" });
  }
});

async function exchangeInstagramCode(code) {
  const body = new URLSearchParams({
    client_id: instagramAppID,
    client_secret: instagramAppSecret,
    grant_type: "authorization_code",
    redirect_uri: `${publicBaseURL}/instagram/callback`,
    code
  });
  const response = await fetch("https://api.instagram.com/oauth/access_token", { method: "POST", body });
  if (!response.ok) throw new Error(`Instagram token error: ${await response.text()}`);
  return (await response.json()).access_token;
}

async function fetchInstagramProfile(accessToken) {
  const url = new URL("https://graph.instagram.com/me");
  url.searchParams.set("fields", "user_id,username,media.limit(50){caption,timestamp}");
  url.searchParams.set("access_token", accessToken);
  const response = await fetch(url);
  if (!response.ok) throw new Error(`Instagram profile error: ${await response.text()}`);
  const profile = await response.json();
  return {
    username: profile.username,
    captions: (profile.media?.data || []).map(item => item.caption).filter(Boolean)
  };
}

server.listen(port, "0.0.0.0", () => console.log(`Storyfy caption API listening on ${port}`));

function buildPrompt(payload) {
  const examples = String(payload.writingExamples || "").trim();
  return [
    `Crie uma legenda para ${payload.month}, com ${payload.photoCount} fotos.`,
    `Momentos identificados: ${(payload.events || []).join(", ") || "momentos do mês"}.`,
    payload.profile ? `Perfil de referência: ${payload.profile}.` : "",
    examples ? `Imite o estilo, ritmo e uso de emojis destes exemplos, sem copiar frases:\n${examples}` : "Use um tom pessoal, direto e afetuoso, sem exageros.",
    `Esta é a variação ${Number(payload.variant || 0) + 1}. Não use hashtags, salvo se elas forem frequentes nos exemplos.`
  ].filter(Boolean).join("\n\n");
}

function extractOutputText(result) {
  if (typeof result.output_text === "string") return result.output_text.trim();
  for (const item of result.output || []) {
    for (const content of item.content || []) {
      if (content.type === "output_text" && content.text) return content.text.trim();
    }
  }
  return "";
}

async function readJSON(request) {
  const chunks = [];
  for await (const chunk of request) chunks.push(chunk);
  return JSON.parse(Buffer.concat(chunks).toString("utf8"));
}

function json(response, status, body) {
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(body));
}
