
# :closed_lock_with_key: Part 4 – React + Supabase Authentication

---

### :dart: Learning Goals

:white_check_mark: Connect a React app to a Supabase backend using `.env` variables <br/>
:white_check_mark: Log in users securely using `supabase.auth.signInWithPassword()` <br/>
:white_check_mark: Create and protect a `profiles` table in Supabase <br/>
:white_check_mark: Use **Row Level Security (RLS)** to restrict access based on user roles <br/>
:white_check_mark: Redirect logged-in users to a dashboard page <br/>
:white_check_mark: Prepare for **Part 5** where we’ll create **protected routes** and **user sessions** <br/>

---

## :jigsaw: Why Use Supabase for Authentication?

Supabase provides:

* :lock: Secure password storage (hashed automatically)
* :email: Optional email confirmation
* :bricks: Built-in `auth.users` table for credentials
* 🪪 A flexible database for extra user info (`profiles`)
* :gear: Powerful **Row Level Security** to protect your data

We’ll use **Supabase `auth.users`**  for sign-in and a **`profiles` table** for user details.

![Basic Layout](./assets/ERD_Auth_Users_Profiles.png)

**:information_source: This means no passwords are ever stored manually — Supabase handles it all safely.**

---

## :toolbox: 1. Install Supabase and Set Up Environment Variables

Open a terminal inside your React project and install the Supabase client:

Open a **new terminal** in VS-Code: (Click on the plus button as shown in the screenshot below)

![Basic Layout](../02-React_Layout_and_Routing/assets/New_Terminal.png)


1. In your project folder, run:

```bash
npm install @supabase/supabase-js
```

2. When it has completed installing, you can close the terminal with:

```bash
exit
```


3. Create a **`.env`** file in the **:exclamation: root :exclamation:** of your project folder and add placeholders below:

```bash
# !!! DO NOT UPLOAD THIS FILE TO GITHUB !!!
VITE_SUPABASE_URL=https://your-project-url.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```
> We'll fill these with real values later; after creating the Supabase project.

:bulb: The directory tree below shows where to put your **`.env`** file
```
react-auth-demo/    ⬅️ Project Root Folder
├── node_modules/
├── public/
├── src/
├── .env            ⬅️ .env file location
├── .gitignore
├── index.html
```

:brain: **Tip:** <mark>Never commit **.env** to GitHub</mark>

4. Open the `.gitignore` file and add **`.env`** at the bottom of the file then save changes.

> You may need to restart your app after editing `.env` to apply changes.

<details>
    <summary>Show me more information about .env files</summary>

## :card_index_dividers: What Is a `.env` File?

A `.env` file (short for "environment") is a plain text file used to store **environment variables** which are key-value pairs that configure your application without hardcoding sensitive or changeable data.

### :test_tube: Common Use Cases
- API keys
- Database credentials
- Port numbers
- Debug flags

Example:
```
DATABASE_URL=postgres://user:password@localhost:5432/mydb
API_KEY=abc123xyz
DEBUG=true
```

---

### :white_check_mark:  Best Practices for Using `.env` Files

- **Keep it out of version control**: Add `.env` to your `.gitignore` so it’s not pushed to GitHub or other repositories.
- **Use descriptive variable names**: Make it easy to understand what each variable does.
- **Load variables securely**: Use libraries like `dotenv` (Node.js), `python-dotenv` (Python), or built-in support in frameworks to load `.env` values.
- **Separate environments**: Use different `.env` files for development, testing, and production (e.g., `.env.dev`, `.env.prod`).
- **Avoid duplication**: Don’t hardcode the same values in your code — always reference the environment variable.

---

### :closed_lock_with_key: Security Tips

- **Never expose secrets**: Don’t log or print sensitive values from `.env` files.
- **Use secret managers in production**: Tools like AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault are safer than `.env` files for production secrets.
- **Restrict file access**: Limit read permissions to only necessary users or services.
- **Audit regularly**: Check for unused or outdated variables and remove them.

</details>

---

## :jigsaw: 2. Create `supabaseClient.tsx`

1. Create a new file:

:page_facing_up: `src/supabaseClient.tsx`

Enter the following code:

```tsx
// Import the `createClient` function from the Supabase JavaScript library.
import { createClient } from "@supabase/supabase-js"; // This function is used to initialise a connection to your Supabase backend instance.

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL; // Retrieve the Supabase project URL from environment variables.
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY; // Retrieve the Supabase anonymous public API key from environment variables.

// Create a single supabase client for the entire app
export const supabase = createClient(supabaseUrl!, supabaseAnonKey!); // The `!` after each variable tells TypeScript that you're sure these values are not `null` or `undefined`.

```

:white_check_mark: This file exports the connected Supabase client. <br/>
:white_check_mark: You’ll import this client into any page that needs database or auth features.

---

## :cloud: 3. Create Your Supabase Project

1. Go to **[https://supabase.com](https://supabase.com)**
2. Click **Start your project** (free tier is fine).
3. Create a project (e.g. `react-auth-demo`)
4. Choose your region and set a strong database password.
5. Wait for Supabase to initialise (1–2 minutes).

Then retrieve your **URL** and **anon key**:

```
Dashboard → Settings → API → Project URL + anon public key
```

Paste them into your `.env` file and save.
Restart your React app afterwards (`Ctrl + C`, then `npm run dev`).

---

## :bricks: 4. Create the `profiles` Table

### :compass: In Supabase Dashboard:

1. Go to **Table Editor → New Table**
2. Name: `profiles`
3. Add the following columns:

| Name       | Type          | Default             | Notes          |
| ---------- | ------------- | ------------------- | -------------- |
| id         | `uuid`        | `gen_random_uuid()` | Primary key    |
| first_name | `text`        | —                   | Not null       |
| last_name  | `text`        | —                   | Not null       |
| email      | `text`        | —                   | Unique         |
| is_admin   | `boolean`     | `false`             | Default: false |
| updated_at | `timestamptz` | `now()`             | Auto timestamp |
| created_at | `timestamptz` | `now()`             | Auto timestamp |

> :warning: **Do not add a password column!** Supabase Auth already handles secure login credentials.



### :bulb: SQL Alternative

If you do not wish to use the GUI to create the table, you can paste this in **SQL Editor → New Query** instead:

```sql
CREATE TABLE profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text UNIQUE NOT NULL,
  is_admin boolean DEFAULT false,
  updated_at timestamptz DEFAULT now(),
  created_at timestamptz DEFAULT now()
);
```
:information_source: You should see **`Success. No rows returned`** if the command succeeds.

---

## :toolbox: 5. Enable Row Level Security (RLS) and Add Policies

### :brain: What is RLS?

Row Level Security means the database checks *who* is querying before returning data.
It’s the difference between “anyone can read this table” vs “only this user can read their row”.

Without RLS, every authenticated user could see everyone’s data.
With RLS, access is restricted row by row using policies.

#### :bulb: Why RLS Matters

Even if users can't see a page in React, they can still:

:x: Use dev tools to call the API <br/>
:x: Send HTTP requests directly to Supabase <br/>
:x: Query data that should be restricted

> **RLS stops that — even if the user knows the database URL.**

---

### :brain: RLS Rules We Need
| Table      | Who can access?            | Policy                                    |
| ---------- | -------------------------- | ----------------------------------------- |
| `profiles` | Logged-in users            | Can `SELECT` only *their own row*         |
| `profiles` | Admins (`is_admin = true`) | Can `SELECT`, `INSERT`, `UPDATE` all rows |
| `profiles` | Everyone else              | :x: No access                               |

:white_check_mark: This prevents normal users from seeing or editing other users’ info <br/>
:white_check_mark: This allows our admin dashboard to work safely later

---

### :compass: Step-by-Step in Supabase Dashboard

There are two ways you can do this. Via the [GUI](#method-1-using-the-gui) or by running an SQL command in [SQL Editor](#method-2-using-the-sql-editor). 

### Method 1: Using the GUI.

1. Go to **Table Editor → profiles**
2. Click on **RLS disabled** button
3. Click **Enable RLS for this table**
4. Click **Enable RLS** in the "Confirm ..." dialogue

:white_check_mark: This locks the table until policies are added <br/>
:white_check_mark: Without policy, nobody can read or write anything (even admins) <br/>
:white_check_mark: Now we add the policies

Click on **Add RLS policy** button

Then repeat the steps below to create the four policies.

---

### :bricks: Policy 1 – Allow users to view their own profile

Click **Create policy** button
* Policy Name as: ```Allow users to view their own profile```
* Table: `public.profiles`
* Policy Behavior: `Permissive`
* Click **SELECT** under **Policy Command**
* Target Roles: `Defaults to all(public) roles if none selected`
* Enter using: ```(auth.uid() = id)``` into the generated SQL statement.

:information_source: Your full statement should look like below:
```sql
create policy "Allow users to view their own profile"
on "public"."profiles"
as PERMISSIVE
for SELECT
to public
using (
  (auth.uid() = id)
);
```
Click **Save policy**

:white_check_mark: Allows logged-in users to **read** THEIR OWN row only <br/>
:white_check_mark: They cannot **read** other users’ data

---

### :bricks: Policy 2 – Allow users to update their own profile

Click **Create policy** button
* Enter Policy Name as: ```Allow users to update their own profile```
* Table: `public.profiles`
* Policy Behavior: `Permissive`
* Click **UPDATE** under **Policy Command**
* Target Roles: `Defaults to all(public) roles if none selected`
* Enter using:```(auth.uid() = id)```
* Enter with check: ```(auth.uid() = id)```

:information_source: Your full statement should look like below:
```sql
create policy "Allow users to update their own profile"
on "public"."profiles"
as PERMISSIVE
for UPDATE
to public
using (
  (auth.uid() = id)
) with check (
  (auth.uid() = id)
);
```
Click **Save policy**

:arrow_right: Lets users **update** THEIR OWN row only <br/>
:white_check_mark: They cannot **update** other users’ data

---

### :bricks: Policy 3 – Allow admins full access

Click **Create policy** button
* Enter Policy Name as: ```Allow admins full access```
* Table: `public.profiles`
* Policy Behavior: `Permissive`
* Click **ALL** under **Policy Command**
* Target Roles: `Defaults to all(public) roles if none selected`
* Enter using: ```(((auth.jwt() ->> 'is_admin'::text))::boolean = true)```
* Enter with check: ```(((auth.jwt() ->> 'is_admin'::text))::boolean = true)```


:information_source: Your full statement should look like below:
```sql
create policy "Allow admins full access"
on "public"."profiles"
as PERMISSIVE
for ALL
to public
using (
  (((auth.jwt() ->> 'is_admin'::text))::boolean = true)
) with check (
  (((auth.jwt() ->> 'is_admin'::text))::boolean = true)
);

```
Click **Save policy**

:white_check_mark: If the logged-in user’s own record has `is_admin = true`, they can select, insert and update any row. You may get a warning

---

### :bricks: Policy 4 – Disable Delete (Recommended)

Do **not** create any DELETE policy.
When RLS is enabled, lack of a delete policy means deletes are automatically blocked. :white_check_mark:

---

### Method 2: Using the SQL Editor
If you did not wish to click around the interface or have a problem with the resultant RLS Policies, you can copy and paste the SQL command below into SQL Editor to create the 3 policies at once. You may get a **"Destructive Query Warning"**. 
Click **Run this query**.

```sql

-- DROP existing policies (for safety)
DROP POLICY IF EXISTS "Allow users to view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow users to update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Allow admins full access" ON public.profiles;

-- Ensure RLS is enabled
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Policy #1: Users can view their own profile
CREATE POLICY "Allow users to view their own profile"
ON public.profiles
AS PERMISSIVE
FOR SELECT
TO public
USING (
  auth.uid() = id
);

-- Policy #2: Users can update their own profile (but only their row)
CREATE POLICY "Allow users to update their own profile"
ON public.profiles
AS PERMISSIVE
FOR UPDATE
TO public
USING (
  auth.uid() = id
)
WITH CHECK (
  auth.uid() = id
);

-- Policy #3: Admins full access (select, insert, update, delete) if their JWT has is_admin = true
CREATE POLICY "Allow admins full access"
ON public.profiles
AS PERMISSIVE
FOR ALL
TO public
USING (
  (auth.jwt() ->> 'is_admin')::boolean = true
)
WITH CHECK (
  (auth.jwt() ->> 'is_admin')::boolean = true
);


```
#### :white_check_mark: Explanation of each part

* `auth.uid() = id`: ensures the logged-in user’s UID matches the `id` column of the row in `profiles` table.
* `(auth.jwt() ->> 'is_admin')::boolean = true`: reads the `is_admin` claim from the user’s JWT token, casts it to boolean, and checks if it’s `true`.
* `FOR ALL`: covers `SELECT`, `INSERT`, `UPDATE`, `DELETE`.
* `WITH CHECK`: ensures that when rows are inserted/updated by an admin, the action is only permitted if `is_admin = true`.

---

### :brain: Final Table Security Result

| User Type       | SELECT         | INSERT     | UPDATE     | DELETE     |
| --------------- | -------------- | ---------- | ---------- | ---------- |
| Normal user     | :white_check_mark: Own row only | :x:          | :white_check_mark: Own row only | :x:          |
| Admin user      | :white_check_mark: All rows     | :white_check_mark: All rows | :white_check_mark: All rows | :white_check_mark: All rows |
| Logged out user | :x: Nothing      | :x:          | :x:          | :x:          |

:white_check_mark: This protects the database even if frontend is bypassed <br/>
:white_check_mark: Admin dashboard will work later because their RLS access allows it <br/>
:white_check_mark: Normal users cannot impersonate or modify anyone else

---

## :office_worker: 6. Create an Admin and a User Account
### a. Create an Admin Account

1. In **Authentication → Users → Add user**, click **Create new user**.

   * Email: `admin@domain.local`
   * Password: `password`
   * Tick :white_check_mark: *Auto Confirm User*

2. Copy that user’s **UID** (from the Users list).

3. In **SQL Editor**, insert the admin’s profile:

```sql
INSERT INTO profiles (id, first_name, last_name, email, is_admin)
VALUES ('your-copied-user-id', 'App', 'Admin', 'admin@domain.local', true);
```



### b. Create an User Account

1. In **Authentication → Users → Add user**, click **Create new user**.

   * Email: `user01@domain.local`
   * Password: `password`
   * Tick :white_check_mark: *Auto Confirm User*

2. Copy that user’s **UID** (from the Users list).

3. In **SQL Editor**, insert the user’s profile:

```sql
INSERT INTO profiles (id, first_name, last_name, email, is_admin)
VALUES ('your-copied-user-id', 'App', 'User01', 'user01@domain.local', false);
```

:white_check_mark: Now you have **one admin** and **one user** account for testing.

---

## 7. Create a Custom Access Token Hook Security Definer that adds is_admin

**Open Supabase → SQL Editor → New Query** and paste the function below. This function reads `public.profiles` for the logged-in user and adds an `is_admin` boolean into the token claims if their account has the `is_admin` column value set as 1 in the profiles table.

> Note: this code runs when a token is issued.
> Paste and run as a single query as **postgres role**.

```sql

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  claims jsonb := coalesce(event->'claims', '{}'::jsonb);
  user_id uuid := (event->>'user_id')::uuid;
  is_admin_value boolean := false;
begin
  -- Safely fetch the is_admin flag from profiles
  select p.is_admin into is_admin_value
  from public.profiles p
  where p.id = user_id;

  -- Insert or overwrite is_admin in JWT claims
  claims := jsonb_set(claims, '{is_admin}', to_jsonb(is_admin_value), true);

  -- Return event with modified claims
  return jsonb_set(event, '{claims}', claims);
end;
$$;

```

**What this does**

* Reads the logged-in user id (`event->'user'->>'id'`), looks up `profiles.is_admin`, and adds `"is_admin": true|false` into the issued token’s claims.
* Because the hook runs as part of token issuance, the DB can check `(auth.jwt() ->> 'is_admin')::boolean` in RLS without recursive queries. (See Supabase documentation on custom access token hook).

---

### :toolbox: Next: Make sure the hook can read the profiles table

Because this hook runs as the Supabase Auth service (not as a normal user account), you must grant it permission to read that table. We will grant select permission to postgress and the services role.

**SQL Editor → New Query** then paste and run the function below and run as **postgres role**:

```sql
grant select on public.profiles to postgres;
grant select on public.profiles to service_role;
```

Then restart your project from the **Dashboard** → **Project Settings** → **Project availability** → **Restart project**

---

## 8. Configure Supabase to call the Custom Access Token Hook Security Definer when issuing tokens

1. Open your Supabase project → left menu → **Authentication**.
2. Click on **Auth Hooks** 
3. Click **Add hooks** or **Add a new hook**
4. Select **Customize Access Token (JWT) Claims hook**
4. In that UI, under **Postgres function** select the function we created: `custom_access_token_hook`
5. Once selected you will see the statements box auto-populate with the following statements:

```sql
-- Grant access to function to supabase_auth_admin
grant execute on function public.custom_access_token_hook to supabase_auth_admin;

-- Grant access to schema to supabase_auth_admin
grant usage on schema public to supabase_auth_admin;

-- Revoke function permissions from authenticated, anon and public
revoke execute on function public.custom_access_token_hook from authenticated, anon, public;

```

7. click **Create hook**

---

<!--

Once the JWT claim is working, the RLS policies (using `(auth.jwt()->>'is_admin')::boolean`) will correctly to allow the admin to see all users:

```sql
-- 1️⃣ Allow users to view their own profile or all if admin
create policy "Allow users to read their own or all if admin"
on public.profiles for select
to authenticated
using (
  auth.uid() = id
  or coalesce((auth.jwt()->>'is_admin')::boolean, false)
);

-- 2️⃣ Allow users to update their own or all if admin
create policy "Allow users to update their own or all if admin"
on public.profiles for update
to authenticated
using (
  auth.uid() = id
  or coalesce((auth.jwt()->>'is_admin')::boolean, false)
);

-- 3️⃣ Allow admins to insert (non-admins cannot)
create policy "Allow admins to insert profiles"
on public.profiles for insert
to authenticated
with check (
  coalesce((auth.jwt()->>'is_admin')::boolean, false)
);
```

-->




## 9. :mag: Quick sanity check

To confirm everything is working end-to-end, in SQL Editor **impersonate admin@domain.local** and run these SQL tests:

```sql
-- Query 1:
-- Should show "is_admin": true for admin, false for user and NULL for everything else
select (auth.jwt()->>'is_admin')::boolean as is_admin;

-- Query 2:
-- Should return multiple rows for admin and postgres, none for anon and own row for user.
select id, email, is_admin from profiles;

-- If you wsh to generate the full Java Web Token output, run the following, then right click the returned row and choose View Cell Content.
select auth.jwt();

```

It is recommended to **impersonate user** and re-run the SQL tests to ensure there are no unintended results.

## :clipboard: Expected Test Results Table

| Role      | Query 1: `(auth.jwt()->>'is_admin')::boolean as is_admin` | Query 2: `select id, email, is_admin from profiles;` |
|-----------|-----------------------------------------------------------|------------------------------------------------------|
| **admin** | `true`                                                    | Multiple rows (all profiles visible)                 |
| **postgres** | `NULL` (no `is_admin` claim in JWT)                     | Multiple rows (all profiles visible)                 |
| **user**  | `false`                                                   | Own row only (restricted to their profile)           |
| **anon**  | `NULL`                                                    | No rows returned                                     |


---

## :key: 10. Update `Login.tsx` to Use Supabase Auth

Replace your existing `Login.tsx` with the following code:

```tsx
// Import the useState hook from React.
// useState lets this component store and update values (email, password, and error messages).
import { useState } from "react";

// Import the Supabase client we set up earlier.
// This gives us access to Supabase authentication functions.
import { supabase } from "../supabaseClient";

// Import useNavigate from React Router.
// This hook lets us programmatically redirect the user to another page after login.
import { useNavigate } from "react-router-dom";

export default function Login() {
  // Declare state variables for form fields.
  // "email" and "password" will always hold the latest text typed by the user.
  // setEmail and setPassword are functions used to update those values.
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  // New state variable for error messages.
  // If login fails, "error" will hold the error message string.
  // setError is used to update that value.
  const [error, setError] = useState<string | null>(null);

  // Create a navigate function using React Router.
  // We’ll use this to redirect the user to the dashboard after successful login.
  const navigate = useNavigate();

  // This function is triggered when the user presses the "Sign In" button
  // or submits the form by pressing Enter.
  async function handleSubmit(e: React.FormEvent) {
    // Prevent the browser from refreshing the page (default form behaviour).
    // In React apps, we ALWAYS prevent full page reload.
    e.preventDefault();

    // Clear any previous error message before trying again.
    setError(null);

    // Try to log in using Supabase Auth.
    // signInWithPassword takes the email and password from state.
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    // If Supabase returns an error (wrong email or password), update error state.
    if (error) {
      setError(error.message); // Show the error message in the UI.
      return; // Stop running the rest of the function.
    }

    // If login succeeds, Supabase gives us user data.
    // In case we need to debug, we log it to the console.
    console.log("Logged in user:", data.user);

    // Successful login → redirect to dashboard page.
    navigate("/dashboard");
  }

  return (
    // This section gives structure for layout/styling.
    // The CSS class "login-container" centres the login card on the page.
    <section className="login-container">
      <div className="login-card">
        <h2>Sign In</h2>

        {/* 
          The "onSubmit" attribute tells React what to do when the form is submitted.
          In this case, it calls our handleSubmit() function above.
        */}
        <form onSubmit={handleSubmit} className="login-form">
          
          {/* EMAIL FIELD */}
          <label>
            Email
            <input
              type="email"                 // built-in browser validation for email format
              value={email}                // controlled input (value stored in state)
              onChange={(e) => setEmail(e.target.value)} // updates state as user types
              placeholder="Enter your email"
              required                     // browser will not allow empty submission
            />
          </label>

          {/* PASSWORD FIELD */}
          <label>
            Password
            <input
              type="password"              // hides the text while typing
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
            />
          </label>

          {/* SUBMIT BUTTON */}
          <button type="submit" className="btn-primary">
            Sign In
          </button>
        </form>

        {/* ERROR MESSAGE */}
        {/* If "error" has a value, show it in red text below the form. */}
        {error && <p style={{ color: "red", marginTop: "1rem" }}>{error}</p>}

        {/* This link does nothing yet, but will connect later to Supabase reset-password */}
        <a href="#" className="forgot-link">Forgot your password?</a>
      </div>
    </section>
  );
}
```

:white_check_mark: Uses `supabase.auth.signInWithPassword()` <br/>
:white_check_mark: Redirects on success using `useNavigate()` <br/>
:white_check_mark: Displays red error text if login fails

---

## :compass: 11. Add the Dashboard Page

Create `src/pages/Dashboard.tsx`

```tsx
export default function Dashboard() {
  return (
    <section>
      <h1>Dashboard</h1>
      <p>You are logged in successfully!</p>
      <p>This page will later show user details and admin functions.</p>
    </section>
  );
}
```

:white_check_mark: Visible only after login (we’ll secure it in Part 5).

---

## :gear: 12. Update `App.tsx`

Add the new /dashboard route to your `App.tsx`:

```tsx
import { BrowserRouter, Routes, Route } from "react-router-dom";
import './App.css'
import Layout from "./components/Layout";
import Home from "./pages/Home";
import About from "./pages/About";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";

export default function App() {
  return (
    <BrowserRouter>
      <Layout>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/about" element={<About />} />
          <Route path="/login" element={<Login />} />
          <Route path="/dashboard" element={<Dashboard />} />
        </Routes>
      </Layout>
    </BrowserRouter>
  );
}
```

:white_check_mark: Layout still shared (Navbar + Footer visible)

---

## :test_tube: 13. Test Checklist

| Test | Expected Result                                                       |
| ---- | --------------------------------------------------------------------- |
| 1    | App runs without errors                                               |
| 2    | Navigate to `/login`                                                  |
| 3    | Enter wrong email/password → red error appears                        |
| 4    | Enter `admin@domain.local` + `password` → redirected to Dashboard     |
| 5    | Navbar + Footer remain visible                                        |
| 6    | Refresh dashboard page — stays logged in (Supabase remembers session) |
| 7    | Close and re-open browser. Navigate to `/dahsboard` > stays logged in!!!|

:white_check_mark: You now have a Supabase authentication working front-end to back-end.

![Alert](./assets/Police_Flashing_Lights_5.gif) <br/>
However, the routes are still **:warning: not protected yet :warning:** as illustrated in **Test 7**. <br/> 
This shows the difference between **UI display logic** and **real access control**, which is essential for cybersecurity aware development. <br/>
![Alert](./assets/Police_Flashing_Lights_5.gif)

---

## :brain: Troubleshooting

| Problem                                                           | Fix                                                       |
| ----------------------------------------------------------------- | --------------------------------------------------------- |
| `TypeError: Cannot read properties of undefined (reading 'auth')` | Check `.env` spelling and restart the app                 |
| `Invalid login credentials`                                       | Confirm the test user exists in Supabase Auth             |
| Form does nothing                                                 | Ensure you imported `useNavigate` from `react-router-dom` |
| Redirect fails silently                                           | Check browser console for `Mixed Content` (HTTP vs HTTPS) |

---

## :rocket: What You Learned in Part 4

| Concept                | Meaning                                              |
| ---------------------- | ---------------------------------------------------- |
| Supabase Client        | Connects your React app securely to the backend      |
| Environment Variables  | Hide sensitive API keys                              |
| Supabase Auth          | Handles login & password hashing                     |
| Profiles Table         | Stores user-specific details                         |
| Row Level Security     | Restricts access to each user’s own data             |
| Admin Privileges       | Controlled via `is_admin` field                      |
| Navigation After Login | Uses React Router’s `useNavigate()`                  |
| Next Step              | Implement protected routes + user session management |

---

## :fast_forward: What’s Next (Part 4.5 Preview)

In **Part 4.5 – Making the Navbar Aware of Login State + Adding Logout**, we will:

:heavy_check_mark: Detect when a user is logged in using Supabase Auth <br/>
:heavy_check_mark: Show Login when logged out, but Logout + Dashboard when logged in <br/>
:heavy_check_mark: Trigger Supabase’s signOut() function and redirect the user <br/>
:heavy_check_mark: Understand what onAuthStateChange() does and why it matters <br/>
:heavy_check_mark: Understand the difference between UI-based access and Protected Routes

---

[Back](../02-React_Layout_and_Routing/03-Create_A_Login_Form.md) -- [Next](./04.5-React_Login_State.md)

<!--
In **Part 5 – Protected Routes and User Sessions**, you will:
:white_check_mark: Store and read the current user session in React
:white_check_mark: Redirect unauthenticated users away from `/dashboard`
:white_check_mark: Add a “Logout” button to clear the session
:white_check_mark: Use Supabase `auth.getUser()` to retrieve profile data
:white_check_mark: Display the user’s first and last name in the Dashboard
-->