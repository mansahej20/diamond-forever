/* Diamond Forever — backend configuration.
 *
 * These values are PUBLISHABLE and belong in the browser. The key can only do
 * what row-level security allows: anyone may READ the catalogue, and only an
 * address listed in the `editors` table may change it.
 *
 * Never put the service_role key in this file.
 *
 * Who may edit is decided in the database, not here — see README.md.
 */
window.DF_CONFIG = {
  SUPABASE_URL: "https://apslfvemkdvkximzvgwn.supabase.co",
  SUPABASE_ANON_KEY: "sb_publishable_LF0fVqCpruRntZFJfDkOyw_r18nxXMM"
};
