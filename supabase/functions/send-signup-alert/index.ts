// Supabase Edge Function to send email alerts for new waitlist signups
// Deploy with: supabase functions deploy send-signup-alert

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const RESEND_API_KEY = Deno.env.get('RESEND_API_KEY')
const ALERT_EMAIL = Deno.env.get('ALERT_EMAIL') || 'hello@call-carl.com'

interface SignupData {
  id: string
  email: string
  phone?: string
  zip_code: string
  sms_consent: boolean
  terms_consent: boolean
  created_at: string
}

serve(async (req) => {
  try {
    // Get the signup data from the request
    const signup: SignupData = await req.json()

    if (!RESEND_API_KEY) {
      console.error('RESEND_API_KEY not configured')
      return new Response(
        JSON.stringify({ error: 'Email service not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    // Format the email
    const emailSubject = `New Call Carl Waitlist Signup`
    const emailBody = `
      <h2>New Waitlist Signup</h2>
      <p>A new person has joined the Call Carl waitlist!</p>

      <h3>Signup Details:</h3>
      <ul>
        <li><strong>Email:</strong> ${signup.email}</li>
        ${signup.phone ? `<li><strong>Phone:</strong> ${signup.phone}</li>` : '<li><strong>Phone:</strong> Not provided</li>'}
        <li><strong>Zip Code:</strong> ${signup.zip_code}</li>
        <li><strong>SMS Consent:</strong> ${signup.sms_consent ? '✅ Yes' : '❌ No'}</li>
        <li><strong>Terms Consent:</strong> ${signup.terms_consent ? '✅ Yes' : '❌ No'}</li>
        <li><strong>Signed up:</strong> ${new Date(signup.created_at).toLocaleString()}</li>
      </ul>

      <p><a href="https://call-carl.com/admin.html">View in Admin Panel</a></p>
    `

    // Send email via Resend
    const resendResponse = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${RESEND_API_KEY}`,
      },
      body: JSON.stringify({
        from: 'Call Carl <noreply@call-carl.com>', // Update with your verified domain
        to: [ALERT_EMAIL],
        subject: emailSubject,
        html: emailBody,
      }),
    })

    if (!resendResponse.ok) {
      const error = await resendResponse.text()
      console.error('Resend API error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to send email', details: error }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const result = await resendResponse.json()
    console.log('Email sent successfully:', result)

    return new Response(
      JSON.stringify({ success: true, message: 'Email sent successfully' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in send-signup-alert function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { 'Content-Type': 'application/json' } }
    )
  }
})
