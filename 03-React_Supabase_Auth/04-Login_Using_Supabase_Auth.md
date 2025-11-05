
# :closed_lock_with_key: Part 4 – React + Supabase Authentication

---

### :dart: Learning Goals

:white_check_mark: Connect a React app to a Supabase backend using `.env` variables
:white_check_mark: Log in users securely using `supabase.auth.signInWithPassword()`
:white_check_mark: Create and protect a `profiles` table in Supabase
:white_check_mark: Use **Row Level Security (RLS)** to restrict access based on user roles
:white_check_mark: Redirect logged-in users to a dashboard page
:white_check_mark: Prepare for **Part 5** where we’ll create *protected routes* and *user sessions*

---

## :jigsaw: Why Use Supabase for Authentication?

Supabase provides:

* :lock: Secure password storage (hashed automatically)
* :email: Optional email confirmation
* :bricks: Built-in `auth.users` table for credentials
* 🪪 A flexible database for extra user info (`profiles`)
* :gear: Powerful **Row Level Security** to protect your data

We’ll use **Supabase Auth** for sign-in and a **`profiles` table** for user details.
This means no passwords are ever stored manually — Supabase handles it all safely.

---

## :toolbox: 1. Install Supabase and Set Up Environment Variables

Open a terminal inside your React project and install the Supabase client:

```bash
npm install @supabase/supabase-js
```

Then create a **`.env`** file in the **:exclamation: root :exclamation:** of your project folder and add placeholders.
We'll fill these with real values after creating the Supabase project:

```bash
VITE_SUPABASE_URL=https://your-project-url.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key-here
```

> :brain: **Tip:** Never commit `.env` to GitHub — add it to your `.gitignore`.
> Restart your app after editing `.env` to apply changes.

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

## :white_check_mark:  Best Practices for Using `.env` Files

- **Keep it out of version control**: Add `.env` to your `.gitignore` so it’s not pushed to GitHub or other repositories.
- **Use descriptive variable names**: Make it easy to understand what each variable does.
- **Load variables securely**: Use libraries like `dotenv` (Node.js), `python-dotenv` (Python), or built-in support in frameworks to load `.env` values.
- **Separate environments**: Use different `.env` files for development, testing, and production (e.g., `.env.dev`, `.env.prod`).
- **Avoid duplication**: Don’t hardcode the same values in your code — always reference the environment variable.

---

## :closed_lock_with_key: Security Tips

- **Never expose secrets**: Don’t log or print sensitive values from `.env` files.
- **Use secret managers in production**: Tools like AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault are safer than `.env` files for production secrets.
- **Restrict file access**: Limit read permissions to only necessary users or services.
- **Audit regularly**: Check for unused or outdated variables and remove them.

</details>

---

## :jigsaw: 2. Create `supabaseClient.ts`

Create a new file:
:page_facing_up: `src/supabaseClient.ts`

Enter the following code:

```tsx
// Import the `createClient` function from the Supabase JavaScript library.
import { createClient } from "@supabase/supabase-js"; // This function is used to initialise a connection to your Supabase backend instance.

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL; // Retrieve the Supabase project URL from environment variables.
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY; // Retrieve the Supabase anonymous public API key from environment variables.

// Create a single supabase client for the entire app
export const supabase = createClient(supabaseUrl!, supabaseAnonKey!); // The `!` after each variable tells TypeScript that you're sure these values are not `null` or `undefined`.

```

:white_check_mark: This file exports the connected Supabase client.
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

---

## :office_worker: 5. Create an Admin User

1. In **Authentication → Users → Add user**, click **Create new user**.

   * Email: `admin@admin.com`
   * Password: `password123`
   * Tick :white_check_mark: *Auto Confirm User*

2. Copy that user’s **UUID** (from the Users list).

3. In **SQL Editor**, insert the admin’s profile:

```sql
INSERT INTO profiles (id, first_name, last_name, email, is_admin)
VALUES ('your-copied-user-id', 'App', 'Admin', 'admin@admin.com', true);
```

:white_check_mark: Now you have one admin account for testing.

---

## :toolbox: 6. Enable Row Level Security (RLS) and Add Policies

### :brain: What is RLS?

Row Level Security means the database checks *who* is querying before returning data.
It’s the difference between “anyone can read this table” vs “only this user can read their row”.

Without RLS, every authenticated user could see everyone’s data.
With RLS, access is restricted row by row using policies.

#### 💡 Why RLS Matters

Even if users can't see a page in React, they can still:

❌ Use dev tools to call the API
❌ Send HTTP requests directly to Supabase
❌ Query data that should be restricted

> **RLS stops that — even if the user knows the database URL.**

---

### 🧠 RLS Rules We Need
| Table      | Who can access?            | Policy                                    |
| ---------- | -------------------------- | ----------------------------------------- |
| `profiles` | Logged-in users            | Can `SELECT` only *their own row*         |
| `profiles` | Admins (`is_admin = true`) | Can `SELECT`, `INSERT`, `UPDATE` all rows |
| `profiles` | Everyone else              | ❌ No access                               |

✅ This prevents normal users from seeing or editing other users’ info
✅ This allows our admin dashboard to work safely later

---

### :compass: Step-by-Step in Supabase Dashboard

1. Go to **Table Editor → profiles**
2. Click on **RLS disabled** button
3. Click **Enable RLS for this table**
4. Click **Enable RLS** in the "Confirm ..." dialogue

✅ This locks the table until policies are added
✅ Without policy, nobody can read or write anything (even admins)
✅ Now we add the policies

Click on **Add RLS policy** button

Then repeat the steps below to create the four policies.

---

### :bricks: Policy 1 – Users can read their own profile

* Click **Create policy** button
* Enter Policy Name as: ```Users can read their own profile```
* Click **SELECT** under **Policy Command**
* Enter ```auth.uid() = id``` into the generated SQL statement.

:information_source: Your full statement should look like below:
```SQL
create policy "Users can read their own profile"
on "public"."profiles"
as PERMISSIVE
for SELECT
to public
using (
auth.uid() = id
);
```
* Click **Save policy**

✅ Allows logged-in users to read THEIR OWN row only
✅ They cannot read other users’ data

---

### :bricks: Policy 2 – Users can update their own profile (except admin flag)

* Click **Create policy** button
* Enter Policy Name as: ```Users can update their own profile```
* Click **UPDATE** under **Policy Command**
* Enter ```auth.uid() = id```
* Enter ```auth.uid() = id AND is_admin = is_admin```

:information_source: Your full statement should look like below:
```sql
create policy "Users can update their own profile"
on "public"."profiles"
as PERMISSIVE
for UPDATE
to public
using (
auth.uid() = id
) with check (
auth.uid() = id AND is_admin = is_admin
);
```
* Click **Save policy**

➡ Lets normal users update their own name/email,
but prevents them from changing `is_admin`.

---

### :bricks: Policy 3 – Admins can read, insert and update all profiles

* Click **Create policy** button
* Enter Policy Name as: ```Admins can read and write all profiles```
* Click **ALL** under **Policy Command**
* Enter 
```sql
EXISTS (
    SELECT 1 FROM profiles AS p
    WHERE p.id = auth.uid() AND p.is_admin = true
  )
```
* Un-Tick ***Use check expression***

:information_source: Your full statement should look like below:
```sql
create policy "Admins can read and write all profiles"
on "public"."profiles"
as PERMISSIVE
for ALL
to public
using (
EXISTS (
    SELECT 1 FROM profiles AS p
    WHERE p.id = auth.uid() AND p.is_admin = true
  )
);

```
* Click **Save policy**

:white_check_mark: If the logged-in user’s own record has `is_admin = true`,
they can select, insert and update any row.

---

### :bricks: Policy 4 – Disable Delete (Recommended)

Do **not** create any DELETE policy.
When RLS is enabled, lack of a delete policy means deletes are automatically blocked. :white_check_mark:

---

### 🧠 Final Table Security Result

| User Type       | SELECT         | INSERT     | UPDATE     | DELETE     |
| --------------- | -------------- | ---------- | ---------- | ---------- |
| Normal user     | ✅ Own row only | ❌          | ✅ Own row only | ❌          |
| Admin user      | ✅ All rows     | ✅ All rows | ✅ All rows | ✅ All rows |
| Logged out user | ❌ Nothing      | ❌          | ❌          | ❌          |

✅ This protects the database even if frontend is bypassed
✅ Admin dashboard will work later because their RLS access allows it
✅ Normal users cannot impersonate or modify anyone else

---


## :key: 7. Update `Login.tsx` to Use Supabase Auth

Replace your existing `Login.tsx` with the following code:

```tsx
import { useState } from "react";
import { supabase } from "../supabaseClient";
import { useNavigate } from "react-router-dom";

export default function Login() {
  // React state for controlled inputs
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const navigate = useNavigate();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    // Try to log in using Supabase Auth
    const { data, error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      // Wrong email or password
      setError(error.message);
      return;
    }

    // Successful login → redirect to dashboard
    navigate("/dashboard");
  }

  return (
    <section className="login-container">
      <div className="login-card">
        <h2>Sign In</h2>

        <form onSubmit={handleSubmit} className="login-form">
          <label>
            Email
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="Enter your email"
              required
            />
          </label>

          <label>
            Password
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="Enter your password"
              required
            />
          </label>

          <button type="submit" className="btn-primary">
            Sign In
          </button>
        </form>

        {error && <p style={{ color: "red", marginTop: "1rem" }}>{error}</p>}

        <a href="#" className="forgot-link">Forgot your password?</a>
      </div>
    </section>
  );
}
```

:white_check_mark: Uses `supabase.auth.signInWithPassword()`
:white_check_mark: Redirects on success using `useNavigate()`
:white_check_mark: Displays red error text if login fails

---

## :compass: 8. Add the Dashboard Page

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

## :gear: 9. Update `App.tsx`

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

## :test_tube: 10. Test Checklist

| Test | Expected Result                                                       |
| ---- | --------------------------------------------------------------------- |
| 1    | App runs without errors                                               |
| 2    | Navigate to `/login`                                                  |
| 3    | Enter wrong email/password → red error appears                        |
| 4    | Enter `admin@admin.com` + `password123` → redirected to Dashboard     |
| 5    | Navbar + Footer remain visible                                        |
| 6    | Refresh dashboard page — stays logged in (Supabase remembers session) |
| 7    | Close browser and Navigate to `/dahsboard` — stays logged in!!!       |

:white_check_mark: You now have a Supabase authentication working front-end to back-end.

![Alert](./assets/Police_Flashing_Lights_5.gif)
However, the routes are still **:warning: not protected yet :warning:** as illustrated in **Test 7**. 
This shows the difference between **UI display logic** and **real access control**, which is essential for cybersecurity aware development.
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

✅ Detect when a user is logged in using Supabase Auth
✅ Show Login when logged out, but Logout + Dashboard when logged in
✅ Trigger Supabase’s signOut() function and redirect the user
✅ Understand what onAuthStateChange() does and why it matters
✅ Understand the difference between UI-based access and Protected Routes

---

[Back](../02-React_Layout_and_Routing/03-Create_A_Login_Form.md) -- [Next](04.5-React_Login_State.md)

<!--
In **Part 5 – Protected Routes and User Sessions**, you will:
:white_check_mark: Store and read the current user session in React
:white_check_mark: Redirect unauthenticated users away from `/dashboard`
:white_check_mark: Add a “Logout” button to clear the session
:white_check_mark: Use Supabase `auth.getUser()` to retrieve profile data
:white_check_mark: Display the user’s first and last name in the Dashboard
-->