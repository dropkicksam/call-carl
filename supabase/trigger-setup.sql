-- Database Trigger Setup for Email Alerts
-- Run this SQL in your Supabase SQL Editor after deploying the Edge Function
-- Replace YOUR_PROJECT_REF with your actual Supabase project reference

-- Enable the http extension (required for calling Edge Functions)
CREATE EXTENSION IF NOT EXISTS http;

-- Create a function that calls the Edge Function
CREATE OR REPLACE FUNCTION notify_new_signup()
RETURNS TRIGGER AS $$
DECLARE
  project_url TEXT;
  service_role_key TEXT;
BEGIN
  -- Get project URL and service role key from environment
  -- You'll need to set these as database secrets or use your actual values
  project_url := current_setting('app.settings.supabase_url', true);
  service_role_key := current_setting('app.settings.service_role_key', true);
  
  -- If not set, use placeholder (you'll need to replace these)
  IF project_url IS NULL THEN
    project_url := 'https://YOUR_PROJECT_REF.supabase.co';
  END IF;
  
  -- Call the Edge Function
  PERFORM
    net.http_post(
      url := project_url || '/functions/v1/send-signup-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || COALESCE(service_role_key, 'YOUR_SERVICE_ROLE_KEY')
      ),
      body := jsonb_build_object(
        'id', NEW.id,
        'first_name', NEW.first_name,
        'email', NEW.email,
        'phone', NEW.phone,
        'zip_code', NEW.zip_code,
        'created_at', NEW.created_at
      )
    );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger that fires after insert
CREATE TRIGGER on_new_signup
  AFTER INSERT ON waitlist_signups
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_signup();

-- Note: You'll need to:
-- 1. Replace YOUR_PROJECT_REF with your actual Supabase project reference
-- 2. Replace YOUR_SERVICE_ROLE_KEY with your actual service role key
-- 3. Or set them as database secrets using:
--    ALTER DATABASE postgres SET app.settings.supabase_url = 'https://your-project.supabase.co';
--    ALTER DATABASE postgres SET app.settings.service_role_key = 'your-service-role-key';
