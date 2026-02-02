/**
 * Reset Monthly Usage
 *
 * This function should be called by a cron job on the 1st of each month
 * to reset all users' monthly synthesis counts.
 *
 * Setup cron job in Supabase:
 * SELECT cron.schedule('reset-monthly-usage', '0 0 1 * *', $$
 *   SELECT net.http_post(
 *     'https://your-project.supabase.co/functions/v1/reset-monthly-usage',
 *     '{}',
 *     'application/json',
 *     ARRAY[http_header('Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY')]
 *   );
 * $$);
 */
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify authorization (service role or cron secret)
    const authHeader = req.headers.get("Authorization");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const cronSecret = Deno.env.get("CRON_SECRET");

    const isAuthorized =
      authHeader === `Bearer ${serviceKey}` ||
      authHeader === `Bearer ${cronSecret}`;

    if (!isAuthorized) {
      return new Response(
        JSON.stringify({ error: "Unauthorized" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabase = createClient(supabaseUrl, serviceKey!);

    // Reset all users' monthly counts
    const { data, error } = await supabase
      .from("profiles")
      .update({
        monthly_synthesis_count: 0,
        current_period_start: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      })
      .neq("id", "00000000-0000-0000-0000-000000000000") // Update all
      .select("id");

    if (error) {
      console.error("Reset failed:", error);
      throw error;
    }

    const count = data?.length || 0;
    console.log(`Successfully reset usage for ${count} profiles`);

    return new Response(
      JSON.stringify({
        success: true,
        message: `Reset monthly usage for ${count} profiles`,
        timestamp: new Date().toISOString(),
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (error) {
    console.error("Error:", error);

    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
