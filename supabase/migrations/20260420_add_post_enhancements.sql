-- Add post enhancement columns for better content control
ALTER TABLE posts
  ADD COLUMN is_important boolean NOT NULL DEFAULT false,
  ADD COLUMN is_pinned boolean NOT NULL DEFAULT false,
  ADD COLUMN send_notification boolean NOT NULL DEFAULT false,
  ADD COLUMN highlight_in_feed boolean NOT NULL DEFAULT false;
