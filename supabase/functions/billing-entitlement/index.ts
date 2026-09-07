import { createClient } from "npm:@supabase/supabase-js@2";

const supabaseURL = Deno.env.get("SUPABASE_URL") ?? "";
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const authClient = createClient(supabaseURL, supabaseAnonKey, { auth: { persistSession: false } });
const serviceClient = createClient(supabaseURL, supabaseServiceRoleKey, { auth: { persistSession: false } });

const products: Record<string, { plan: "plus" | "creator"; months: number }> = {
  storyfy_plus_monthly: { plan: "plus", months: 1 },
  storyfy_plus_yearly: { plan: "plus", months: 12 },
  storyfy_creator_monthly: { plan: "creator", months: 1 },
  storyfy_creator_yearly: { plan: "creator", months: 12 },
};

Deno.serve(async (request) => {
  if (request.method !== "POST") return json({ error: "method_not_allowed" }, 405);
  if (!supabaseURL || !supabaseAnonKey || !supabaseServiceRoleKey) return json({ error: "supabase_not_configured" }, 503);

  try {
    const user = await authenticatedUser(request);
    if (!user) return json({ error: "unauthorized" }, 401);

    const payload = await request.json();
    const productId = String(payload.product_id ?? "");
    const entitlement = products[productId];
    if (!entitlement) return json({ error: "invalid_product" }, 400);
    const transactionId = optionalString(payload.transaction_id);
    const originalTransactionId = optionalString(payload.original_transaction_id);
    const purchasedAt = validDateOrNull(payload.purchased_at);
    const clientExpiresAt = validDateOrNull(payload.expires_at);

    const fallbackExpiresAt = new Date();
    fallbackExpiresAt.setUTCMonth(fallbackExpiresAt.getUTCMonth() + entitlement.months);
    const expiresAt = clientExpiresAt ?? fallbackExpiresAt;

    const eventPayload = {
      user_id: user.id,
      product_id: productId,
      transaction_id: transactionId,
      original_transaction_id: originalTransactionId,
      plan: entitlement.plan,
      source: "storekit_local_verified",
      purchased_at: purchasedAt?.toISOString() ?? null,
      expires_at: expiresAt.toISOString(),
    };

    const { error: eventError } = transactionId
      ? await serviceClient.from("billing_events").upsert(eventPayload, { onConflict: "transaction_id" })
      : await serviceClient.from("billing_events").insert(eventPayload);

    if (eventError) {
      console.error("billing_event_failed", eventError.code, eventError.message);
    }

    const { data, error } = await serviceClient
      .from("user_entitlements")
      .upsert({
        user_id: user.id,
        plan: entitlement.plan,
        source: "storekit_local_verified",
        product_id: productId,
        expires_at: expiresAt.toISOString(),
        updated_at: new Date().toISOString(),
      }, { onConflict: "user_id" })
      .select("plan,product_id,expires_at")
      .single();

    if (error) {
      console.error("entitlement_upsert_failed", error.code, error.message);
      return json({ error: "entitlement_upsert_failed" }, 500);
    }

    return json(data);
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

function optionalString(value: unknown) {
  const text = String(value ?? "").trim();
  return text.length ? text : null;
}

function validDateOrNull(value: unknown) {
  const text = String(value ?? "").trim();
  if (!text) return null;
  const date = new Date(text);
  return Number.isNaN(date.getTime()) ? null : date;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });
}
