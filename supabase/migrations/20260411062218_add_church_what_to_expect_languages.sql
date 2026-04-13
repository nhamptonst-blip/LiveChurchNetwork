-- Add dedicated `what_to_expect` and `languages` columns to church_submissions.
-- iOS currently concatenates these into the `about` text with prefixes like
-- "What to expect: ..." and "Languages: ...". Now that the web edit form needs
-- structured access to them, store them as real columns. iOS can keep its
-- legacy concat behavior until updated separately — extra columns won't break
-- iOS Codable decoding since `ChurchSubmission` uses explicit CodingKeys.

alter table public.church_submissions
  add column if not exists what_to_expect text,
  add column if not exists languages text;
