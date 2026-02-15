# Supabase Setup Instructions

## 1. Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com) and sign in
2. Click "New Project"
3. Fill in project details:
   - Name: `call-carl` (or your preferred name)
   - Database Password: Choose a strong password (save it!)
   - Region: Choose closest to your users
4. Wait for project to be created (takes ~2 minutes)

## 2. Set Up Database Schema

1. In your Supabase project, go to **SQL Editor**
2. Copy and paste the contents of `supabase-setup.sql`
3. Click "Run" to execute the SQL
4. Verify the table was created by going to **Table Editor** → you should see `waitlist_signups`

## 3. Get API Credentials

1. Go to **Settings** → **API**
2. Copy the following:
   - **Project URL** (e.g., `https://xxxxx.supabase.co`)
   - **anon/public key** (starts with `eyJ...`)
   - **service_role key** (starts with `eyJ...`) - **KEEP THIS SECRET!**

## 4. Configure config.js

1. Open `config.js` in your project
2. Fill in:
   - `SUPABASE_URL`: Your Project URL
   - `SUPABASE_ANON_KEY`: Your anon/public key
   - `ADMIN_PASSWORD`: Choose a strong password for admin panel
   - `EMAIL_API_KEY`: (Optional) If using external email service

## 5. Set Up Email Notifications

### Option A: Using Supabase Edge Function (Recommended)

1. Install Supabase CLI: `npm install -g supabase`
2. Login: `supabase login`
3. Link project: `supabase link --project-ref your-project-ref`
4. Create function: `supabase functions new send-signup-alert`
5. See `supabase/functions/send-signup-alert/index.ts` for implementation
6. Deploy: `supabase functions deploy send-signup-alert`

### Option B: Using Database Trigger with External Service

1. Set up an email service (Resend, SendGrid, etc.)
2. Create a webhook or use Supabase's built-in email (if available)
3. See email service documentation for integration

## 6. Security Notes

- **Never commit** `config.js` with real credentials to git
- Add `config.js` to `.gitignore` if it contains secrets
- Use environment variables in production
- The `service_role` key has full database access - keep it secret!
- Consider using Supabase Auth for proper admin authentication in production

## 7. Test the Setup

1. Open `index.html` in a browser
2. Submit the waitlist form
3. Check Supabase Table Editor to see if data was inserted
4. Check your email (hello@call-carl.com) for alert
5. Access admin panel at `admin.html` and log in
