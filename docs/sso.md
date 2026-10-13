# FinTrack single sign-on

FinTrack can sign users in with OpenID Connect. The API is the confidential OAuth client. It uses the authorization code flow with PKCE, checks the identity token on the server, and then issues the same FinTrack JWT the mobile app already stores.

Email and password registration and login stay available. SSO buttons appear only for providers that are configured. Existing users, transactions, budgets, and settings stay on the same account.

## What the app does

1. The app asks `GET /api/auth/sso/providers` which providers are enabled. Secrets are never included.
2. `POST /api/auth/sso/start` creates a one-time challenge (state, nonce, and PKCE verifier) and returns the provider's authorization URL.
3. The phone opens that URL in a secure browser tab.
4. The provider redirects to `GET /api/auth/sso/callback` on the API.
5. The API checks state, exchanges the code with the PKCE verifier and client secret, and validates the ID token (signature, issuer, audience, expiration, nonce, and authorized party when present).
6. The API redirects to `fintrack://sso/callback` with a short-lived exchange code. The app sends that code and the original state to `POST /api/auth/sso/exchange` and receives a FinTrack JWT.
7. Profile lists linked methods. A signed-in user can connect or disconnect a provider. Disconnect is refused when it would leave the account with no way to sign in.

The authorization code, ID token, access token, refresh token, and client secret are not stored and are not written to logs. FinTrack does not request a refresh token. The FinTrack JWT lifetime is still `JWT_EXPIRATION_MINUTES`.

## Account linking

People are recognized by the provider's issuer and subject (`iss` + `sub`), not by email.

- A returning linked user signs in to the same FinTrack account. Their transactions and settings are unchanged.
- A verified email that already belongs to a FinTrack account is not merged automatically. The app asks for that account's password before it links the provider.
- An unverified email is never used to create or take over an account. The user can sign in with the existing method and connect the provider from Profile, which proves both the FinTrack session and the provider login.
- A brand-new verified identity creates an account only when `SSO_ALLOW_REGISTRATION` is true (the default, matching open registration). New SSO accounts receive the same default categories as email registration and have no password until one is set in Profile.
- Google requires the provider's `email_verified` claim.
- Microsoft with a specific tenant ID trusts that directory's email. Microsoft with `common`, `organizations`, or `consumers` requires `email_verified` or `xms_edov`.
- Another OpenID Connect provider requires `email_verified`.

## Environment variables

Leave a provider disabled, or leave its client id or secret empty, and its button is hidden. Do not commit real secrets. `.env` is gitignored. `appsettings.json` only contains empty placeholders.

| Variable | Purpose |
| --- | --- |
| `SSO_GOOGLE_ENABLED` | `true` or `false`. Google is hidden unless this is true and both Google credentials are set. |
| `GOOGLE_CLIENT_ID` | Google OAuth client id. |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret. Server only. |
| `SSO_MICROSOFT_ENABLED` | `true` or `false`. |
| `MICROSOFT_CLIENT_ID` | Entra application (client) id. |
| `MICROSOFT_CLIENT_SECRET` | Entra client secret. Server only. |
| `MICROSOFT_TENANT_ID` | Directory tenant id, or `common`, `organizations`, or `consumers`. Default `common`. |
| `SSO_OIDC_ENABLED` | `true` or `false` for an extra enterprise provider. |
| `OIDC_CLIENT_ID` | That provider's client id. |
| `OIDC_CLIENT_SECRET` | That provider's client secret. Server only. |
| `OIDC_ISSUER_URI` | Issuer URL, for example `https://login.example.com`. The API loads `{issuer}/.well-known/openid-configuration`. |
| `OIDC_DISPLAY_NAME` | Button label for the extra provider. Default `Single sign-on`. |
| `OIDC_REDIRECT_URI` | API callback, for example `https://api.example.com/api/auth/sso/callback`. Also accepted as `SSO_REDIRECT_URI`. |
| `SSO_APP_CALLBACK_URI` | Where the API sends the phone after success. Default `fintrack://sso/callback`. |
| `SSO_POST_LOGOUT_REDIRECT_URI` | Optional provider logout return. Default `fintrack://sso/logout`. |
| `SSO_ALLOW_REGISTRATION` | `true` allows a first-time SSO user to create an account. `false` only allows users who already exist or who connect a provider from Profile. |

The same values can be set with ASP.NET Core configuration, for example `Sso__Google__ClientId` and `Sso__Google__Enabled`. Environment variables above override those when they are non-empty.

Local development reads `backend/src/FinTrack.Api/appsettings.Development.json`, which sets the redirect URI to `http://localhost:8080/api/auth/sso/callback`. Providers stay off until you enable them.

Production must set `ASPNETCORE_ENVIRONMENT=Production` and an `https://` redirect URI. An `http://` redirect is accepted only for loopback while the API is running in Development. If production configuration is incomplete, SSO stays hidden and email login continues to work.

## Google

1. Open [Google Cloud Console](https://console.cloud.google.com/) and create or select a project.
2. Configure the OAuth consent screen. Add the scopes `openid`, `email`, and `profile` (these are the default identity scopes; FinTrack does not request anything else).
3. Create an OAuth client of type **Web application**. The API holds the client secret, so this is a web client even though the user is in the mobile app.
4. Add this authorized redirect URI, exactly:
   - Local: `http://localhost:8080/api/auth/sso/callback`
   - Production: `https://fintrack-production-3807.up.railway.app/api/auth/sso/callback`
5. Copy the client id and client secret into the environment. Do not put them in the Flutter app or in a committed file.
6. Set `SSO_GOOGLE_ENABLED=true`, `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and `OIDC_REDIRECT_URI`.
7. Restart the API. The log line `SSO providers ready` should include `google`, and the login screen should show **Continue with Google**.

Google's discovery document usually has no end-session endpoint. Signing out of FinTrack clears the FinTrack JWT. It does not always end the Google browser session.

On an Android emulator the app calls `http://10.0.2.2:8080/api`. That address does not exist on a physical phone, so the Google button stays hidden there until the phone can reach the same API.

Connect the phone with USB debugging and run this once per connection:

```bash
adb reverse tcp:8080 tcp:8080
```

Then run the app again. A physical phone uses `http://127.0.0.1:8080/api`, and the reverse makes both that address and the Google redirect `http://localhost:8080/api/auth/sso/callback` reach the API on your computer. The same `adb reverse` command is also required on the emulator, because the sign-in browser opens `localhost`, not `10.0.2.2`.

Over Wi-Fi, pass the computer's address for API calls:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8080/api
```

Google still redirects the browser to `localhost`. Keep `adb reverse` active, or the button can appear and the sign-in still fails when the browser cannot return to the API.

## Microsoft Entra ID

1. Open [Microsoft Entra admin center](https://entra.microsoft.com/) → **App registrations** → **New registration**.
2. Choose who can sign in:
   - This directory only: copy the tenant id into `MICROSOFT_TENANT_ID`.
   - Any work or school account: set `MICROSOFT_TENANT_ID=organizations`.
   - Work, school, and personal accounts: set `MICROSOFT_TENANT_ID=common`.
   - Personal Microsoft accounts only: set `MICROSOFT_TENANT_ID=consumers`.
3. Add a **Web** redirect URI:
   - Local: `http://localhost:8080/api/auth/sso/callback`
   - Production: `https://<your-api-host>/api/auth/sso/callback`
4. Under **Certificates & secrets**, create a client secret. Store it as `MICROSOFT_CLIENT_SECRET`. Store the application id as `MICROSOFT_CLIENT_ID`.
5. Under **Authentication**, set the front-channel logout URL to `fintrack://sso/logout` if you want Entra to return to the app after logout. Also add the API logout URL only if you terminate sessions on a website.
6. Under **Token configuration**, add the optional ID token claims `email` and, when you use `common` or `organizations`, `xms_edov` if you need FinTrack to treat the email as verified. A specific tenant id does not need that extra claim because the directory itself asserts the address.
7. API permissions need only Microsoft Graph `openid`, `profile`, and `email`. Do not grant broader Graph access.
8. Set `SSO_MICROSOFT_ENABLED=true` and restart the API.

For `common` and `organizations`, the token issuer is the user's own tenant (`https://login.microsoftonline.com/{tid}/v2.0`). FinTrack checks that tenant id and the token signature. It does not trust the `common` URL as the token issuer.

## Another OpenID Connect provider

Use this for an issuer that is already in your company, such as Keycloak, Auth0, Okta, or another Entra tenant you want to show under a custom name.

1. Register a confidential client at that provider.
2. Allow the same redirect URI you use for `OIDC_REDIRECT_URI`.
3. Allow the post-logout redirect `fintrack://sso/logout` if the provider has an end-session endpoint.
4. Grant only `openid`, `profile`, and `email`.
5. Set `SSO_OIDC_ENABLED=true`, `OIDC_CLIENT_ID`, `OIDC_CLIENT_SECRET`, `OIDC_ISSUER_URI`, and optionally `OIDC_DISPLAY_NAME`.
6. The issuer must publish `https://<issuer>/.well-known/openid-configuration`. The ID token must be signed and include `email_verified=true` before FinTrack will create an account from it.

## HTTPS, cookies, CORS, and proxies

- Production redirect and issuer URLs must be HTTPS. The mobile callback uses the `fintrack://` scheme, which the app registers on Android and iOS.
- FinTrack does not put the session in a cookie. The phone keeps the JWT in secure storage, which is the existing session strategy. OAuth `state` is stored on the server, so the callback does not depend on a browser cookie.
- The API CORS policy is unchanged. The provider redirects the browser to the API; the app then calls the API with Dio. You do not need to add the identity provider to CORS.
- Behind a reverse proxy, forward `X-Forwarded-For` and `X-Forwarded-Proto`, and configure the proxy to overwrite any values the client sent. The public redirect URI is configured explicitly. It is not taken from the request host, which avoids open redirects.
- Rate limiting allows 30 auth requests per minute per IP address, including login, registration, and SSO.

## Deploying without breaking current users

1. Apply the `AddSsoIdentities` migration. The API applies migrations on startup. It adds `external_logins` and `sso_challenges` and does not rewrite existing user rows.
2. Deploy with SSO flags set to `false` first. Email login behaves as before.
3. Register the production redirect URI with the provider, then set the credentials and the enabled flag.
4. Users who already have a password keep it. The first time they use a provider with the same verified email, FinTrack asks for that password and then links the provider. It does not create a second account and does not move their financial data.
5. Turning a provider off hides its button. Already linked users can still sign in with email and password, or with another linked provider.

## Local check without credentials

With the defaults, `GET http://localhost:8080/api/auth/sso/providers` returns `[]`, and the login screen shows only email and password. After credentials are set and the API is restarted, the response lists the enabled providers and the matching buttons appear.
