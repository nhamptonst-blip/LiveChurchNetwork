-- Extended church profile fields surfaced through the web edit form.
--   * postal_code  — completes the mailing address (we already have address_line, city, state, country)
--   * pastor_name  — lead pastor / primary contact person
--   * year_founded — when the church was established (integer year)
--   * facebook_url, instagram_url, tiktok_url, x_url — social media presence
--
-- All nullable. iOS uses explicit Codable CodingKeys, so adding columns won't
-- break iOS decoding.

alter table public.church_submissions
  add column if not exists postal_code text,
  add column if not exists pastor_name text,
  add column if not exists year_founded integer,
  add column if not exists facebook_url text,
  add column if not exists instagram_url text,
  add column if not exists tiktok_url text,
  add column if not exists x_url text;
