-- Add dedicated contact and giving fields to church_submissions.
-- Previously these were either crammed into the `about` text or dropped silently
-- by the onboarding flow. Surfacing them as real columns lets the web edit form
-- and the public church page render them properly.

alter table public.church_submissions
  add column if not exists donation_url text,
  add column if not exists contact_email text,
  add column if not exists address_line text;
