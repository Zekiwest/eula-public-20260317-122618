# App Review Notes Template (Guideline 2.1)

## Copy-Paste Version (English)

App Purpose:
[Describe the problem the app solves, intended audience, and key value in 3-5 sentences.]

Main Feature Access Instructions:
1. Launch the app.
2. Sign in with the demo account below (or register a new account).
3. Navigate core tabs: Home, Shorts, Add, Messages, Profile.
4. Open Settings from Profile to review Privacy Policy, User Agreement, and Delete Account flow.
5. Open Wallet from Profile to test in-app purchases and Restore Purchases flow.

Demo Credentials:
- Email: [demo_email]
- Password: [demo_password]
- Notes: [If there are multiple roles, list each account and role behavior.]

Screen Recording:
- Included as attachment.
- Recording starts from app launch and shows typical user flow through core features.
- The video includes:
  - account registration/login flow
  - account deletion flow
  - paid feature access and purchase flow
  - user-generated content flow with reporting/blocking entry points
  - permission prompts (microphone/photo library) when triggered

External Services / Tools / Platforms:
- Supabase (authentication, database, legal document delivery)
- Apple StoreKit (in-app purchases)
- [Add any AI provider, analytics, moderation, CDN, payment processor if used]

Regional Availability:
[Confirm either: “The app functions consistently across all regions.” OR list region-specific differences.]

Regulated Industry Documentation:
[If applicable, provide license/certificate number, issuing authority, and scope. If not applicable, write “Not applicable.”]

Additional Review Notes:
- Legal documents are available both in-app and via public URLs.
- If any test limitation exists, describe it clearly here.

---

## Authoring Guide (Do Not Paste Directly to Review Notes)

- App Purpose: Clearly state target users, the problem solved, and the core value.
- Main Feature Access Instructions: Provide a reproducible reviewer path and keep all entry levels explicit.
- Demo Credentials: Keep credentials valid long-term; provide separate accounts for each role.
- Screen Recording: Record on a physical device from cold launch, covering login, deletion, purchase, and permission prompts.
- External Services: List all services beyond Supabase and StoreKit (for example AI, risk control, or content moderation).
- Regional Availability: If there are no differences, explicitly state "all regions consistent".
- Regulated Industry Documentation: For heavily regulated scenarios such as healthcare or finance, include required licenses.

## Project Variables To Complete

- `[demo_email]`
- `[demo_password]`
- `TERMS_OF_USE_URL` (project configuration)
- `PRIVACY_POLICY_URL` (project configuration)
- Regional-difference statement and regulated-industry qualifications (if applicable)
