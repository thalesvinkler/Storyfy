import { createClient } from "npm:@supabase/supabase-js@2";

const openAIKey = Deno.env.get("OPENAI_API_KEY") ?? "";
const supabaseURL = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const authClient = createClient(supabaseURL, supabaseAnonKey, { auth: { persistSession: false } });
const serviceClient = createClient(supabaseURL, supabaseServiceRoleKey, { auth: { persistSession: false } });

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!openAIKey) return json({ error: "openai_not_configured" }, 503);
  if (!supabaseURL || !supabaseAnonKey || !supabaseServiceRoleKey) return json({ error: "supabase_not_configured" }, 503);
  try {
    const user = await authenticatedUser(request);
    if (!user) return json({ error: "unauthorized" }, 401);

    const quota = await reserveCaptionUsage(user.id);
    if (!quota.allowed) {
      return json({
        error: "monthly_limit_reached",
        plan: quota.plan,
        monthly_limit: quota.monthlyLimit,
        used: quota.used,
        remaining: 0,
        reset_at: quota.resetAt,
      }, 429);
    }

    const payload = await request.json();
    const examples = String(payload.writingExamples ?? "").trim();
    const exampleList = examples.split(/\n\s*\n/).map((item: string) => item.trim()).filter(Boolean).slice(0, 30);
    const averageLength = exampleList.length ? Math.round(exampleList.reduce((sum: number, item: string) => sum + item.length, 0) / exampleList.length) : 180;
    const input = [
      `Crie uma legenda para ${payload.month}, com ${payload.photoCount} fotos.`,
      `Momentos identificados: ${(payload.events ?? []).join(", ") || "momentos do mês"}.`,
      examples ? `Use estes exemplos para reproduzir voz, ritmo, tamanho, pontuação, quebras de linha e frequência de emojis, sem copiar frases:\n${exampleList.join("\n---\n")}` : "Use um tom pessoal, direto e afetuoso.",
      `Tamanho de referência: aproximadamente ${averageLength} caracteres. Não invente lugares, pessoas ou acontecimentos que não estejam nos momentos informados.`,
      `Crie a variação ${Number(payload.variant ?? 0) + 1}.`,
    ].join("\n\n");
    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: { Authorization: `Bearer ${openAIKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({ model: Deno.env.get("OPENAI_MODEL") ?? "gpt-5.4-mini",
        instructions: "Escreva legendas naturais em português do Brasil na voz do usuário. Evite clichês, tom publicitário e listas genéricas. Entregue somente a legenda final.",
        input, max_output_tokens: 350 }),
    });
    if (!response.ok) {
      const details = await response.json().catch(() => ({}));
      console.error("OpenAI request failed", response.status, details?.error?.code, details?.error?.type);
      return json({
        error: "generation_failed",
        upstream_status: response.status,
        upstream_code: details?.error?.code ?? null,
        upstream_type: details?.error?.type ?? null,
      }, 502);
    }
    const result = await response.json();
    const caption = result.output_text ?? result.output?.flatMap((item: any) => item.content ?? []).find((item: any) => item.type === "output_text")?.text;
    return caption ? json({
      caption: caption.trim(),
      quota: {
        plan: quota.plan,
        monthly_limit: quota.monthlyLimit,
        used: quota.used,
        remaining: quota.remaining,
        reset_at: quota.resetAt,
      },
    }) : json({ error: "empty_caption" }, 502);
  } catch (error) {
    console.error(error);
    return json({ error: "invalid_request" }, 400);
  }
});

async function authenticatedUser(request: Request) {
  const authorization = request.headers.get("Authorization") ?? "";
  const token = authorization.replace(/^Bearer\s+/i, "").trim();
  if (!token) return null;
  const { data, error } = await authClient.auth.getUser(token);
  if (error || !data.user) return null;
  return data.user;
}

async function reserveCaptionUsage(userId: string) {
  const { data, error } = await serviceClient.rpc("reserve_caption_usage_monthly", {
    p_user_id: userId,
  }).single();
  if (error) throw error;
  return {
    allowed: Boolean(data.allowed),
    plan: String(data.plan ?? "free"),
    monthlyLimit: Number(data.monthly_limit ?? 0),
    used: Number(data.used ?? 0),
    remaining: Number(data.remaining ?? 0),
    resetAt: String(data.reset_at),
  };
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
