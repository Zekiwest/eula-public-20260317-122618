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

## 中文填写指引（不要直接粘贴到审核）

- App Purpose：写清楚“给谁用、解决什么问题、核心价值”。
- Main Feature Access Instructions：按审核员可复现路径写，不要省略入口层级。
- Demo Credentials：必须长期有效；多角色账号要分别给。
- Screen Recording：必须真机录制，且从冷启动开始，覆盖登录/删号/付费/权限弹窗。
- External Services：把 Supabase、StoreKit 之外的服务也补全（如 AI、风控、内容审核）。
- Regional Availability：若无差异，明确写“all regions consistent”。
- Regulated Industry Documentation：涉及医疗/金融等强监管场景必须附资质。

## 本项目建议你补齐的变量

- `[demo_email]`
- `[demo_password]`
- `TERMS_OF_USE_URL`（工程配置）
- `PRIVACY_POLICY_URL`（工程配置）
- 区域差异声明与（如有）行业资质信息
