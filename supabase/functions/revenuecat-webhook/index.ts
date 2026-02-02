/**
 * RevenueCat Webhook Handler
 *
 * Handles subscription events from RevenueCat and updates
 * the user's subscription status in Supabase.
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RevenueCatEvent {
  type: string;
  id: string;
  app_user_id: string;
  product_id?: string;
  entitlement_ids?: string[];
  period_type?: string;
  purchased_at_ms?: number;
  expiration_at_ms?: number;
  store?: string;
  environment?: string;
  is_family_share?: boolean;
  price?: number;
  currency?: string;
}

interface WebhookPayload {
  api_version: string;
  event: RevenueCatEvent;
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify webhook authorization
    const authHeader = req.headers.get("Authorization");
    const expectedToken = Deno.env.get("REVENUECAT_WEBHOOK_SECRET");

    if (!expectedToken || authHeader !== `Bearer ${expectedToken}`) {
      console.error("Unauthorized webhook request");
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Parse payload
    const payload: WebhookPayload = await req.json();
    const event = payload.event;

    console.log(`Processing RevenueCat event: ${event.type}`);
    console.log(`User ID: ${event.app_user_id}`);
    console.log(`Product ID: ${event.product_id}`);

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Log the event
    const { error: logError } = await supabase
      .from("subscription_events")
      .insert({
        profile_id: event.app_user_id,
        event_type: event.type,
        product_id: event.product_id,
        revenuecat_event_id: event.id,
        raw_payload: payload,
      });

    if (logError) {
      console.error("Failed to log event:", logError);
    }

    // Determine subscription tier from product ID
    const tier = getTierFromProductId(event.product_id);
    const limit = getLimitForTier(tier);

    // Update profile based on event type
    let updateData: Record<string, unknown> | null = null;

    switch (event.type) {
      case "INITIAL_PURCHASE":
      case "RENEWAL":
      case "PRODUCT_CHANGE":
      case "UNCANCELLATION":
        updateData = {
          subscription_tier: tier,
          subscription_status: "active",
          subscription_expires_at: event.expiration_at_ms
            ? new Date(event.expiration_at_ms).toISOString()
            : null,
          monthly_synthesis_limit: limit,
          revenuecat_user_id: event.app_user_id,
          updated_at: new Date().toISOString(),
        };
        break;

      case "CANCELLATION":
        updateData = {
          subscription_status: "cancelled",
          updated_at: new Date().toISOString(),
        };
        break;

      case "EXPIRATION":
        updateData = {
          subscription_tier: "free",
          subscription_status: "expired",
          subscription_expires_at: null,
          monthly_synthesis_limit: 10,
          updated_at: new Date().toISOString(),
        };
        break;

      case "BILLING_ISSUE":
        updateData = {
          subscription_status: "inactive",
          updated_at: new Date().toISOString(),
        };
        break;

      default:
        console.log(`Unhandled event type: ${event.type}`);
    }

    // Apply update if needed
    if (updateData) {
      const { error: updateError } = await supabase
        .from("profiles")
        .update(updateData)
        .eq("id", event.app_user_id);

      if (updateError) {
        console.error("Failed to update profile:", updateError);
        throw updateError;
      }

      console.log(`Successfully updated profile for ${event.app_user_id}`);
    }

    return new Response(
      JSON.stringify({ received: true, event_type: event.type }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Webhook processing error:", error);

    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

function getTierFromProductId(productId?: string): string {
  if (!productId) return "free";

  if (productId.includes("premium")) return "premium";
  if (productId.includes("basic")) return "basic";

  return "free";
}

function getLimitForTier(tier: string): number {
  switch (tier) {
    case "premium":
      return 999999; // Unlimited
    case "basic":
      return 100;
    default:
      return 10;
  }
}
