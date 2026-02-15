-- Supabase Database Setup for Call Carl Waitlist
-- Run this SQL in your Supabase SQL Editor: https://app.supabase.com/project/_/sql

-- Create waitlist_signups table
CREATE TABLE IF NOT EXISTS waitlist_signups (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    phone TEXT NOT NULL,
    zip_code TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create index on email for faster lookups
CREATE INDEX IF NOT EXISTS idx_waitlist_signups_email ON waitlist_signups(email);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_waitlist_signups_created_at ON waitlist_signups(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE waitlist_signups ENABLE ROW LEVEL SECURITY;

-- Policy: Allow anonymous inserts (for form submissions)
CREATE POLICY "Allow anonymous inserts" ON waitlist_signups
    FOR INSERT
    TO anon
    WITH CHECK (true);

-- Policy: Allow authenticated reads (for admin panel - you'll need to set up auth)
-- For now, we'll use a service role key in the admin panel
-- In production, you should use proper Supabase Auth
CREATE POLICY "Allow service role reads" ON waitlist_signups
    FOR SELECT
    TO service_role
    USING (true);

-- Note: For the admin panel, you'll need to use the service_role key (keep it secret!)
-- Or implement proper Supabase Auth with user authentication
