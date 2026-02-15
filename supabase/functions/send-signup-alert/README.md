# Send Signup Alert Edge Function

This Supabase Edge Function sends email notifications to hello@call-carl.com whenever a new waitlist signup is created.

## Setup

### 1. Install Supabase CLI

```bash
npm install -g supabase
```

### 2. Login to Supabase

```bash
supabase login
```

### 3. Link Your Project

```bash
supabase link --project-ref your-project-ref
```

You can find your project ref in your Supabase project settings.

### 4. Set Up Resend (Email Service)

1. Sign up for Resend at [https://resend.com](https://resend.com)
2. Get your API key from the Resend dashboard
3. Set it as a Supabase secret:

```bash
supabase secrets set RESEND_API_KEY=your_resend_api_key
supabase secrets set ALERT_EMAIL=hello@call-carl.com
```

### 5. Deploy the Function

```bash
supabase functions deploy send-signup-alert
```

### 6. Create Database Trigger

Run this SQL in your Supabase SQL Editor to automatically call the function when a new signup is created:

```sql
-- Create a function that calls the Edge Function
CREATE OR REPLACE FUNCTION notify_new_signup()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM
    net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/send-signup-alert',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
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

-- Create trigger
CREATE TRIGGER on_new_signup
  AFTER INSERT ON waitlist_signups
  FOR EACH ROW
  EXECUTE FUNCTION notify_new_signup();
```

**Important:** Replace `YOUR_PROJECT_REF` with your actual Supabase project reference.

## Alternative: Using Supabase's Built-in Email (if available)

If Supabase offers built-in email in your plan, you can modify the function to use that instead of Resend.

## Testing

1. Submit a test signup through the waitlist form
2. Check your email (hello@call-carl.com) for the notification
3. Check Supabase function logs: `supabase functions logs send-signup-alert`
