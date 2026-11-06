/* Diamond Forever — backend configuration.
 *
 * These values are PUBLISHABLE and belong in the browser. The key can only do
 * what the database's row-level security allows, which here is: anyone may READ
 * the catalogue, only the signed-in owner may change it.
 *
 * Never put the service_role key in this file.
 */
window.DF_CONFIG = {
  SUPABASE_URL: "https://apslfvemkdvkximzvgwn.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_LF0fVqCpruRntZFJfDkOyw_r18nxXMM",
  /* Only this address may sign in to edit the catalogue. It must match the
     address in the is_owner() function in supabase/schema.sql. */
  OWNER_EMAIL: "mansahej3009@gmail.com"
};
