# Supabase + Google Sign-In Setup for Orphia

How to create Orphia's Supabase project and connect it to Google Sign-In.
Do Parts 1–4 in the browser. When you finish, send the values listed in
**Part 5** and the iOS code will be wired up.

> **How Orphia signs in (the "native" flow):** the app shows Google's own
> sign-in sheet using Google's iOS SDK. Google gives the app an ID token,
> and the app passes that token to Supabase with `signInWithIdToken`.
> Users never see a browser redirect. This flow needs **two** Google OAuth
> clients: an **iOS** client (used by the app) and a **Web** client
> (used by Supabase).

---

## Decision: is Google sign-in enough?

**For the Congressional App Challenge demo: yes.** Google-only works fine.

Before you finalize, weigh two things:

1. **App Store rule 4.8.** If Orphia ever goes on the App Store with Google as
   its only login, Apple will reject it. Apple requires a privacy-focused
   login option alongside Google, and Sign in with Apple counts. The
   competition doesn't require App Store submission, so this matters only
   if you publish later.
2. **Your users.** Many older adults have an Apple ID on their iPhone but no
   Google account, or don't remember their Google password. Sign in with
   Apple is one tap with Face ID and needs no password.

**Recommendation:** start with Google only (this guide). Plan to add Sign in
with Apple before any App Store release. Supabase supports both, so adding
Apple later is a separate, small task that doesn't require rework.

Google sign-in **replaces** the current first-name + PIN screens
(`LoginView`, and the PIN step of sign-up). The birth-year and genre steps
stay. They run once, right after a user's first Google sign-in.

---

## Part 1 — Create the Supabase project

1. Go to <https://supabase.com/dashboard> and sign in. Signing in with
   GitHub works well, since you plan to set up a GitHub repo anyway.
2. Click **New project**.
   - **Organization:** your personal org. Create one if asked; the free plan
     is fine.
   - **Project name:** `orphia`
   - **Database password:** click **Generate a password** and save it in a
     password manager. The app never uses it, and **don't send it to Claude.**
   - **Region:** the one closest to you, e.g. *East US (North Virginia)* or
     *West US (Oregon)*.
   - **Plan:** Free.
3. Click **Create new project** and wait about 2 minutes for setup to finish.
4. Open **Project Settings → General** and copy the **Project ID**, also
   called the reference ID. It looks like `abcdefghijklmnopqrst`. Your
   project URL is `https://<project-id>.supabase.co`, and Part 2 uses it.

> Free projects **pause after about a week with no activity.** Open the
> dashboard or app before demos and judging.

---

## Part 2 — Create a Google Cloud project and OAuth clients

### 2a. Create the project

1. Go to <https://console.cloud.google.com/> and sign in with the Google
   account that will own the app.
2. Open the project picker at the top, click **New Project**, and name it
   `Orphia`. Click **Create**, then select it.

### 2b. Set up the consent screen ("Google Auth Platform")

1. In the left menu (or search bar), open **Google Auth Platform**, then click
   **Get started**.
2. **App information:** App name `Orphia`; User support email = your email.
3. **Audience:** choose **External**.
4. **Contact information:** your email.
5. Agree to the policy and click **Create**.
6. Open **Data Access → Add or remove scopes** and check:
   `openid`, `.../auth/userinfo.email`, `.../auth/userinfo.profile`.
   Click **Update**, then **Save**. These are basic scopes, so Google doesn't
   need to review them.
7. Open **Audience**:
   - While the app is in **Testing** mode, only accounts listed under
     **Test users** can sign in. Add your Google account and any teammates
     now.
   - Before judges or real residents use the app, click **Publish app**
     to move it to *In production*. With only the basic scopes above, Google
     doesn't need to verify it.

### 2c. Create the **Web** OAuth client (for Supabase)

1. Go to **Google Auth Platform → Clients → Create client**.
2. **Application type:** *Web application*. **Name:** `Orphia Supabase`.
3. Under **Authorized redirect URIs**, click **Add URI** and enter:
   ```
   https://<project-id>.supabase.co/auth/v1/callback
   ```
   (use your Project ID from Part 1, step 4).
4. Click **Create**. Copy the **Client ID** and **Client secret**. The secret
   goes **only** into the Supabase dashboard in Part 3. Don't send it to
   Claude, and never put it in the app.

### 2d. Create the **iOS** OAuth client (for the app)

1. **Clients → Create client** again.
2. **Application type:** *iOS*. **Name:** `Orphia iOS`.
3. **Bundle ID:** `com.orphia.app`. This must match `project.yml` exactly.
4. Leave App Store ID and Team ID blank for now.
5. Click **Create**. Copy:
   - **Client ID**, e.g. `1234567890-abc123.apps.googleusercontent.com`
   - **iOS URL scheme**, e.g. `com.googleusercontent.apps.1234567890-abc123`

---

## Part 3 — Turn on Google in Supabase

1. In the Supabase dashboard, open **Authentication → Sign In / Providers**.
2. Click **Google** and switch **Enable Sign in with Google** on.
3. **Client IDs:** paste the **Web client ID first**, then a comma, then the
   **iOS client ID**, with no spaces:
   ```
   <web-client-id>.apps.googleusercontent.com,<ios-client-id>.apps.googleusercontent.com
   ```
4. **Client Secret (for OAuth):** paste the **Web** client secret from 2c.
5. Turn **Skip nonce checks** **on**. This is needed for native iOS Google
   sign-in, because Google's iOS SDK doesn't let the app pass Supabase a
   nonce of its own.
6. Click **Save**.
7. Optional, if you're going Google-only: in the same provider list, open
   **Email** and turn it off so nobody can create email/password accounts.

---

## Part 4 — Create the `profiles` table

Orphia needs to store each user's name, birth year, and genres. In Supabase,
open **SQL Editor → New query**, paste the SQL below, and click **Run**:

```sql
-- One row per user, keyed to the Supabase auth user.
create table public.profiles (
  id          uuid primary key references auth.users (id) on delete cascade,
  first_name  text,
  birth_year  int  check (birth_year between 1900 and 2100),
  genres      text[] not null default '{}' check (cardinality(genres) <= 4),
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

-- Row Level Security: each user can only see and change their own row.
alter table public.profiles enable row level security;

create policy "Users can read their own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can create their own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "Users can update their own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);
```

Check that it worked: **Table Editor** should list `profiles` with an
"RLS enabled" badge.

(Voice-memo storage is set up separately in **Part 6**.)

---

## Part 5 — What to send to Claude

| # | Value | Where to find it | Safe to share? |
|---|-------|------------------|----------------|
| 1 | **Supabase Project URL** (`https://<id>.supabase.co`) | Project Settings → Data API (or API Keys) | Yes |
| 2 | **Supabase publishable key** (`sb_publishable_…`), or the legacy **anon** key (`eyJ…`) | Project Settings → API Keys | Yes, it's meant to be in the app |
| 3 | **Google iOS client ID** (`….apps.googleusercontent.com`) | Google Auth Platform → Clients → Orphia iOS | Yes |
| 4 | **Google iOS URL scheme** (`com.googleusercontent.apps.…`) | Same page as #3 | Yes |
| 5 | **Google Web client ID** | Google Auth Platform → Clients → Orphia Supabase | Yes |

**Never send:** the database password, the Supabase **secret** /
`service_role` key, or the Google **client secret**. The app doesn't need
them, and anyone who has them can bypass your security rules.

Please also confirm these product choices:

- Google only for now, with Sign in with Apple deferred? (Recommended.)
- Should the first name come from the Google account automatically, with an
  option to edit it, instead of asking the user to type it?

### What happens with the values (for reference)

- Values 1–3 and 5 go in `OrphiaApp/Config/Secrets.xcconfig`. That file is
  already gitignored, so it's never committed. A committed
  `Secrets.example.xcconfig` shows teammates which values to fill in.
- Value 4 becomes a URL scheme in `project.yml`, so Google can return to
  the app after sign-in.
- New Swift packages: `supabase-swift` (Supabase) and `GoogleSignIn-iOS`
  (Google's native sign-in).
- Code changes: a Google sign-in button replaces the name + PIN screens.
  New users go on to the birth-year and genre steps, which save to
  `profiles`. Returning users go straight to Home. The session stays signed
  in between launches, and the profile menu gets a **Sign out** option.

---

## Part 6 — Voice-memo storage (`memories` table + private `memos` bucket)

Each recording is saved on the phone first, so it plays right away. Then
it's uploaded in the background: the audio file goes to a **private**
Storage bucket, and a row describing it goes in the `memories` table. If
the upload fails (for example, no Wi-Fi), the app tries again the next time
My Memories opens or the resident signs in.

In Supabase, open **SQL Editor → New query**, paste this, and click **Run**:

```sql
-- One row per saved voice memo.
create table public.memories (
  id            uuid primary key,
  user_id       uuid not null default auth.uid() references auth.users (id) on delete cascade,
  song_id       text not null,            -- YouTube video id from the song catalog
  audio_path    text not null,            -- path inside the "memos" bucket
  duration_sec  int,
  transcript    text,
  created_at    timestamptz not null default now()
);

create index memories_user_created_idx on public.memories (user_id, created_at desc);

-- Row Level Security: each resident can only see and change their own memories.
-- (Sharing with family later = adding another select policy, not a redesign.)
alter table public.memories enable row level security;

create policy "Users can read their own memories"
  on public.memories for select
  using (auth.uid() = user_id);

create policy "Users can add their own memories"
  on public.memories for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own memories"
  on public.memories for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Users can delete their own memories"
  on public.memories for delete
  using (auth.uid() = user_id);

-- Private bucket for the audio files (10 MB cap per file; memos are ~0.5 MB).
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('memos', 'memos', false, 10485760, array['audio/mp4', 'audio/m4a', 'audio/x-m4a']);

-- Files live at memos/<user id>/<memory id>.m4a. Each resident can only
-- touch files inside their own folder.
create policy "Users can read their own memo files"
  on storage.objects for select to authenticated
  using (bucket_id = 'memos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can upload their own memo files"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'memos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can replace their own memo files"
  on storage.objects for update to authenticated
  using (bucket_id = 'memos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "Users can delete their own memo files"
  on storage.objects for delete to authenticated
  using (bucket_id = 'memos' and (storage.foldername(name))[1] = auth.uid()::text);
```

Check that it worked:
- **Table Editor** lists `memories` with an "RLS enabled" badge.
- **Storage** lists a `memos` bucket marked **Private**.
- After you record a memory in the app, **Storage → memos** has a folder
  named with your user id, holding an `.m4a` file, and **Table Editor →
  memories** has a matching row.

