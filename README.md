# Call Carl - Home Maintenance Reminder Service

A simple, text-based home maintenance reminder service. Never forget home maintenance again!

## Features

- Landing page with waitlist signup form
- Admin panel to view and manage signups
- Email alerts for new signups
- Privacy Policy and Terms pages

## Setup Instructions

### 1. Supabase Setup

1. Follow the instructions in [SUPABASE_SETUP.md](SUPABASE_SETUP.md)
2. Create your Supabase project
3. Run the SQL from `supabase-setup.sql` in your Supabase SQL Editor
4. Get your Supabase URL and API keys

### 2. Configuration

1. Copy `config.js` and fill in your credentials:
   - `SUPABASE_URL`: Your Supabase project URL
   - `SUPABASE_ANON_KEY`: Your Supabase anon/public key
   - `ADMIN_PASSWORD`: Choose a strong password for admin panel access

**Important:** Never commit `config.js` with real credentials to git!

### 3. Email Alerts Setup

1. Follow the instructions in [EMAIL_SETUP.md](EMAIL_SETUP.md)
2. Set up Resend (or another email service)
3. Deploy the Edge Function
4. Set up the database trigger

### 4. Local Development

1. Open `index.html` in a browser, or
2. Run a local server:
   ```bash
   python3 -m http.server 8000
   ```
3. Visit `http://localhost:8000`

### 5. Admin Panel

1. Access the admin panel at `admin.html`
2. Log in with the password you set in `config.js`
3. View all waitlist signups

## File Structure

```
call-carl/
├── index.html          # Landing page
├── admin.html                  # Admin panel
├── admin.js                # Admin panel logic
├── privacy.html            # Privacy policy
├── terms.html              # Terms & conditions
├── styles.css              # All styles
├── config.js               # Configuration (DO NOT COMMIT WITH SECRETS)
├── supabase-setup.sql      # Database schema
├── SUPABASE_SETUP.md       # Supabase setup guide
├── EMAIL_SETUP.md          # Email alerts setup guide
└── supabase/
    └── functions/
        └── send-signup-alert/  # Edge function for email alerts
```

## Security Notes

- Never commit `config.js` with real credentials
- Add `config.js` to `.gitignore` if it contains secrets
- Use environment variables in production
- The admin password is stored in client-side code (consider server-side auth for production)
- Supabase service role key should be kept secret

## Deployment

This site is configured for GitHub Pages (see `CNAME` file). 

1. Push your code to GitHub
2. Enable GitHub Pages in repository settings
3. Update `config.js` with production credentials (or use environment variables)
4. Deploy Supabase Edge Functions

## License

Copyright 2026 Call Carl
