import { createClient } from "npm:@supabase/supabase-js@2.49.1"

type WalletRequest = {
  action?: "balance" | "topup"
  device_id?: string
  user_id?: string
  product_id?: string
  transaction_id?: string
  original_transaction_id?: string
}

const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY") ?? ""
const productCredits: Record<string, number> = {
  "com.eula.stars.p028": 28,
  "com.eula.stars.p066": 66,
  "com.eula.stars.p150": 150,
  "com.eula.stars.p330": 330,
  "com.eula.stars.p530": 530,
  "com.eula.stars.p950": 950,
}

const json = (status: number, body: Record<string, unknown>) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  })

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
      },
    })
  }

  if (req.method !== "POST") {
    return json(405, { error: "METHOD_NOT_ALLOWED" })
  }

  if (!supabaseUrl || !supabaseAnonKey) {
    return json(500, { error: "MISSING_SUPABASE_CONFIG" })
  }

  let payload: WalletRequest = {}
  try {
    payload = await req.json()
  } catch {
    return json(400, { error: "INVALID_JSON" })
  }

  const deviceId = payload.device_id?.trim()
  if (!deviceId) {
    return json(400, { error: "MISSING_DEVICE_ID" })
  }

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: req.headers.get("Authorization") ?? "",
      },
    },
  })

  const { data: authData } = await authClient.auth.getUser()
  const userId = authData.user?.id ?? null

  const action = payload.action ?? "balance"
  if (action === "topup") {
    if (!userId) {
      return json(401, { error: "UNAUTHORIZED" })
    }
    const productId = payload.product_id?.trim()
    const transactionId = payload.transaction_id?.trim()
    if (!productId || !transactionId) {
      return json(400, { error: "MISSING_TOPUP_FIELDS" })
    }
    const delta = productCredits[productId]
    if (!delta) {
      return json(400, { error: "INVALID_PRODUCT_ID" })
    }

    const { data, error } = await authClient.rpc("wallet_apply_delta", {
      p_user_id: userId,
      p_device_id: deviceId,
      p_delta: delta,
      p_reason: "iap_topup",
      p_source: "app_store",
      p_idempotency_key: transactionId,
      p_metadata: {
        product_id: productId,
        transaction_id: transactionId,
        original_transaction_id: payload.original_transaction_id ?? null,
      },
    })

    if (error) {
      return json(500, { error: "WALLET_TOPUP_RPC_FAILED", detail: error.message })
    }

    return json(200, { coins: Number(data ?? 0) })
  }

  const { data, error } = await authClient.rpc("wallet_get_balance", {
    p_user_id: userId,
    p_device_id: deviceId,
  })

  if (error) {
    return json(500, { error: "WALLET_RPC_FAILED", detail: error.message })
  }

  return json(200, { coins: Number(data ?? 0) })
})
