# Email Alert Setup Instructions

This guide will help you set up email notifications to hello@call-carl.com whenever someone signs up for the waitlist.

## Option 1: Using Supabase Edge Function with Resend (Recommended)

### Step 1: Set Up Resend Account

1. Go to [https://resend.com](https://resend.com) and create an account
2. Verify your domain (call-carl.com) or use their test domain for development
3. Get your API key from the dashboard

### Step 2: Install Supabase CLI

```bash
npm install -g supabase
```

### Step 3: Login and Link Project

```bash
supabase login
supabase link --project-ref your-project-ref
```

Find your project ref in Supabase project settings → API.

### Step 4: Set Secrets

```bash
supabase secrets set RESEND_API_KEY=re_your_api_key_here
supabase secrets set ALERT_EMAIL=hello@call-carl.com
```

### Step 5: Deploy Edge Function

```bash
cd /Users/divyaagarwal/gh/call-carl
supabase functions deploy send-signup-alert
```

### Step 6: Set Up Database Trigger

1. Go to your Supabase SQL Editor
2. Open `supabase/trigger-setup.sql`
3. Replace `YOUR_PROJECT_REF` with your actual project reference
4. Replace `YOUR_SERVICE_ROLE_KEY` with your service role key (from Settings → API)
5. Run the SQL script

### Step 7: Test

1. Submit a test signup through the waitlist form
2. Check hello@call-carl.com for the email notification
3. Check function logs: `supabase functions logs send-signup-alert`

## Option 2: Using Webhook with External Service

If you prefer not to use Edge Functions, you can:

1. Set up a webhook service (Zapier, Make.com, etc.)
2. Point it to your Supabase database
3. Configure it to send emails when new rows are inserted

## Option 3: Using Supabase Database Webhooks (if available)

Supabase may offer database webhooks in your plan. Check your Supabase dashboard for webhook options.

## Troubleshooting

### Email not sending

1. Check Edge Function logs: `supabase functions logs send-signup-alert`
2. Verify Resend API key is correct
3. Check that your domain is verified in Resend (if using custom domain)
4. Verify the trigger is created: Check Supabase → Database → Triggers

### Function deployment fails

1. Make sure you're logged in: `supabase login`
2. Verify project is linked: `supabase projects list`
3. Check that you have the correct permissions

### Trigger not firing

1. Verify the trigger exists in Supabase → Database → Triggers
2. Check that the function `notify_new_signup()` exists
3. Test by manually inserting a row and checking logs

## Security Notes

- Never commit API keys or service role keys to git
- Use Supabase secrets for sensitive values
- The service role key has full database access - keep it secret!
- Consider rate limiting to prevent abuse
