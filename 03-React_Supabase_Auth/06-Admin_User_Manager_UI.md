## :closed_lock_with_key: Part 6 – Admin User Manager UI (Admin-Only Page)

### :dart: Learning Goals

By the end of this part, students will:

:white_check_mark: Create an **Admin-only page** called `UserManager.tsx` <br/>
:white_check_mark: Fetch all users from Supabase (only works for admins because of RLS) <br/>
:white_check_mark: Display users in a simple table <br/>
:white_check_mark: Add “Create New User” button (placeholder for now) <br/>
:white_check_mark: Add “Edit” button per user (placeholder for now) <br/>
:white_check_mark: Know how to protect this page using **role-based access**, not just authentication <br/>
:white_check_mark: Understand how RLS and frontend checks work together <br/>

---

## :thinking: Why Do We Need Admin-Only UI?

So far, we have **login protection**, but **every logged-in user can still reach every route**.

We want:

| Action                            | Normal User      | Admin     |
| --------------------------------- | ---------------- | --------- |
| View dashboard                    | ✅ Allowed        | ✅ Allowed |
| View own profile                  | ✅ Allowed        | ✅ Allowed |
| View "User Manager" page          | ❌ Blocked        | ✅ Allowed |
| See “User Manager” link in Navbar | ❌ Hidden         | ✅ Visible |
| Query all users from database     | ❌ Blocked by RLS | ✅ Allowed |

So this part adds **role-based access** on top of authentication.

:white_check_mark: UI checks <br/>
:white_check_mark: ProtectedRoute checks <br/>
:white_check_mark: Database RLS checks (already built in Part 4)

---

### :brain: What Makes This Page “Admin-Only”?

| Feature                                               | Exists Already? | Level          |
| ----------------------------------------------------- | --------------- | -------------- |
| ✅ Login required                                      | Done in Part 5  | App level      |
| ✅ Dashboard protected route                           | Done in Part 5  | App level      |
| ✅ RLS prevents non-admins from querying other users   | Done in Part 4  | Database level |
| 🔜 UI should **hide this page** from non-admins       | Part 6          | UI level       |
| 🔜 ProtectedRoute must also check `is_admin === true` | Part 6          | App level      |

Therefor, this part = **front-end access control + admin UI creation**.

---

## :hammer_and_wrench: 1. Create `UserManager.tsx` page

:pushpin: This page:

* Loads all rows from `profiles` table (admins only)
* Shows them in a table
* Will eventually allow CRUD actions

```tsx
// src/pages/UserManager.tsx

// Import React hooks: useEffect (run code when component loads) and useState (store data in memory)
import { useEffect, useState } from "react";
// Import the Supabase client (used to talk to your database)
import { supabase } from "../supabaseClient";

// Define the shape of a "Profile" object so TypeScript knows what fields exist
type Profile = {
  id: string;          // unique identifier for the user
  first_name: string;  // user's first name
  last_name: string;   // user's last name
  email: string;       // user's email address
  is_admin: boolean;   // whether the user is an admin or not
};

// This is the main React component for managing users
export default function UserManager() {
  // State variable to hold the list of users (starts as an empty array)
  const [users, setUsers] = useState<Profile[]>([]);
  // State variable to track whether data is still loading (starts as true)
  const [loading, setLoading] = useState(true);

  // useEffect runs once when the component first loads (because of the empty [] dependency array)
  useEffect(() => {
    // Define an async function to fetch users from the database
    const fetchUsers = async () => {
      // Ask Supabase for all rows from the "profiles" table, ordered by last_name
      const { data, error } = await supabase
        .from("profiles")
        .select("*")
        .order("last_name", { ascending: true });

      // If there was an error, log it to the console
      if (error) {
        console.error("Error loading users:", error);
      } else {
        // Otherwise, save the data into our "users" state
        setUsers(data as Profile[]);
      }

      // Mark loading as finished
      setLoading(false);
    };

    // Call the function to actually fetch the users
    fetchUsers();
  }, []); // Empty array means this runs only once when the component mounts

  // While loading is true, show a simple message instead of the table
  if (loading) return <p>Loading users...</p>;

  // Once loading is done, render the user management interface
  return (
    <section>
      <h1>User Management</h1>
      <p>Only visible to admin users.</p>

      {/* Button to create a new user (not yet wired up) */}
      <button style={{ marginBottom: "1rem" }}>
        ➕ Create New User
      </button>

      {/* Table to display all users */}
      <table border={1} cellPadding={8}>
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Admin?</th>
            <th>Actions</th>
          </tr>
        </thead>

        <tbody>
          {/* Loop through each user and render a table row */}
          {users.map((user) => (
            <tr key={user.id}>
              {/* Show first + last name */}
              <td>{user.first_name} {user.last_name}</td>
              {/* Show email */}
              <td>{user.email}</td>
              {/* Show whether they are admin (✅ Yes / ❌ No) */}
              <td>{user.is_admin ? "✅ Yes" : "❌ No"}</td>
              {/* Placeholder Edit button */}
              <td>
                <button>Edit</button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

```

:white_check_mark: Works only for admins <br/>
:white_check_mark: Non-admins will fetch **zero rows** because of RLS <br/>
:white_check_mark: Table layout is intentionally kept simple for this exercise.

---

## :hook: 2. Create `useUserProfile()` Hook.

### :thinking: What is a Hook?

Imagine you’re fishing.
You throw your fishing line into the water, and the **hook** is what lets you "catch" something useful: a fish. 

In React, **hooks** are like fishing hooks:  
- You "throw" them into your component, and they "catch" special React features (like state, lifecycle events, or custom logic).  
- Instead of fish, they catch **data** or **behavior** that your component needs.  

**For example:**  
- `useState` is a hook that catches **memory** (it lets your component remember values between renders).  
- `useEffect` is a hook that catches **side effects** (like fetching data when the component loads).  
- A **custom hook** (like `useUserProfile`) is us crafting our own fishing tool to catch exactly the kind of data we want — in this case, a user’s profile.

:fishing_pole_and_fish:  This hook fetches the logged-in user’s profile from Supabase and returns `{ loading, profile, isAdmin }`.

:memo: `src/hooks/useUserProfile.tsx`

```ts
// src/hooks/useUserProfile.tsx

// Import React hooks: useEffect (run code when component loads) and useState (store data in memory)
import { useEffect, useState } from "react";
// Import the Supabase client (used to talk to your database and authentication system)
import { supabase } from "../supabaseClient";

// Define the shape of a "UserProfile" object so TypeScript knows what fields exist
export type UserProfile = {
  id: string;          // unique identifier for the user
  first_name: string;  // user's first name
  last_name: string;   // user's last name
  email: string;       // user's email address
  is_admin: boolean;   // whether the user is an admin or not
};

// This is a custom React hook that loads the current user's profile from Supabase
export function useUserProfile() {
  // State variable to hold the user's profile (starts as null because we don't know yet)
  const [profile, setProfile] = useState<UserProfile | null>(null);
  // State variable to track whether we are still loading data (starts as true)
  const [loading, setLoading] = useState(true);

  // useEffect runs once when the component first loads (because of the empty [] dependency array)
  useEffect(() => {
    // Define an async function to fetch the profile
    async function loadProfile() {
      // Ask Supabase who the currently logged-in user is
      const {
        data: { user },
      } = await supabase.auth.getUser();

      // If no user is logged in, clear profile and stop loading
      if (!user) {
        setProfile(null);
        setLoading(false);
        return; // exit early
      }

      // If a user exists, fetch their matching row from the "profiles" table
      const { data, error } = await supabase
        .from("profiles")     // look in the "profiles" table
        .select("*")          // select all columns
        .eq("id", user.id)    // only rows where "id" matches the logged-in user's id
        .single();            // expect exactly one row back

      // If no error and we got data, save it into state
      if (!error && data) {
        setProfile(data as UserProfile);
        // Helpful for debugging: print the profile object in the browser console
        console.log("Loaded profile:", data);
      } else {
        // If there was an error, log it to the console
        console.error("Error loading profile:", error?.message);
      }

      // Mark loading as finished
      setLoading(false);
    }

    // Call the function to actually load the profile
    loadProfile();
  }, []); // Empty array means this runs only once when the component mounts

  // Note: If the user updates their profile later, you could re-run loadProfile() manually.

  // Return an object with:
  // - profile: the user's profile data (or null if not logged in)
  // - loading: whether we're still fetching data
  // - isAdmin: a shortcut boolean to check if the user is an admin
  return { profile, loading, isAdmin: profile?.is_admin === true };
}

```
### :jigsaw: What useUserProfile.tsx code does

This file defines a **custom React hook** called `useUserProfile`. Its job is to fetch the currently logged-in user’s profile from Supabase and make it easy for any component to use that data.

<details>
<summary> Show detailed explanation for useUserProfile.tsx</summary>

### Step-by-Step Breakdown

1. **Imports**  
   - `useState` → lets you store values (like the profile and loading state).  
   - `useEffect` → runs code when the component first loads.  
   - `supabase` → your database + authentication client.

2. **UserProfile Type**  
   - A TypeScript definition that says: "A user profile has an `id`, `first_name`, `last_name`, `email`, and `is_admin`."  
   - This ensures TypeScript can warn you if you try to use a field that doesn’t exist.

3. **State Setup**  
   ```ts
   const [profile, setProfile] = useState<UserProfile | null>(null);
   const [loading, setLoading] = useState(true);
   ```
   - `profile` starts as `null` (we don’t know the user yet).  
   - `loading` starts as `true` (we’re still fetching data).

4. **useEffect (runs once on mount)**  
   - Defines an async function `loadProfile()` that:  
     - Checks if a user is logged in (`supabase.auth.getUser()`).  
     - If no user → clears profile and stops loading.  
     - If a user exists → queries the `profiles` table for their row.  
     - Saves the result into `profile` state.  
     - Logs errors if something goes wrong.  
     - Marks `loading` as `false` when finished.

   - Calls `loadProfile()` immediately.

5. **Return Value**  
   ```ts
   return { profile, loading, isAdmin: profile?.is_admin === true };
   ```
   - Any component that uses this hook will receive:  
     - `profile`: the user’s data (or `null` if not logged in).  
     - `loading`: whether the data is still being fetched.  
     - `isAdmin`: a shortcut boolean to check if the user is an admin.

---

#### :gear: How It Works in Practice

When a component calls `useUserProfile()`:
- At first, `loading` is `true` and `profile` is `null`.  
- The hook fetches the logged-in user’s profile from Supabase.  
- Once done, it updates `profile` and sets `loading` to `false`.  
- The component can then show either:
  - A loading spinner while `loading` is true.  
  - The user’s profile once it’s loaded.  
  - A "not logged in" message if `profile` is null.  

</details>

### :brain: Summary

| Line                                  | Purpose                               |
| ------------------------------------- | ------------------------------------- |
| `supabase.auth.getUser()`             | Gets the logged-in Supabase Auth user |
| Query on `profiles` table             | Fetches first/last name + is_admin    |
| `isAdmin: profile?.is_admin === true` | Returns `true` only for admin users   |
| `null` when logged out                | Prevents errors when no user exists   |

:white_check_mark: **Analogy Recap:** Hooks are like fishing hooks, they let you "catch" React features or custom logic. <br/>
:white_check_mark: **Code Recap:** `useUserProfile` is a custom hook that catches the logged-in user’s profile from Supabase and makes it easy for components to use. <br/>

---

## :globe_with_meridians: 3. Create `useUser()` Global Profile Context.

### :thinking: What is a Global Profile Context?
Imagine you’re in a big office building with many rooms.  
- Each room has people working (these are your React components).  
- Everyone needs to know **who the current user is** (their name, email, admin status).  

If every room had to go downstairs to the reception desk to ask “Who’s logged in?” it would be slow and repetitive.  

Instead, the building installs a **digital notice board in the lobby** that always shows the current user’s profile.  
- Any room can just glance at the board to know who’s logged in.  
- If the user changes (logs in/out), the board updates automatically.  
- This board is the **Global Profile Context**.  

So:  
- **Context** = the notice board.  
- **Provider** = the system that keeps the board updated.  
- **useContext** = the act of looking at the board from your room.  


### :information_source: Reminder of what the hook we created does:

- `useUserProfile()` hook creates a *new instance of profile state every time* it’s called.

- Each component that calls this hook (Navbar, ProtectedRoute) runs its own independent copy of the hook, meaning they don’t share profile data.

We’ll create a **global `UserContext.tsx`** that loads the profile **once** and shares it across all components (`Navbar`, `ProtectedRoute`, `Dashboard`, etc.).

:memo: `src/context/UserContext.tsx`

```tsx
// src/context/UserContext.tsx

// Import React tools:
// - createContext: lets us make a "global" data store
// - useContext: lets components read from that store
// - useEffect: run code when component loads or when something changes
// - useState: store data in memory
import { createContext, useContext, useEffect, useState } from "react";
// Import Supabase client (used for authentication and database queries)
import { supabase } from "../supabaseClient";
// Import the UserProfile type definition so TypeScript knows the shape of profile data
import type { UserProfile } from "../hooks/useUserProfile";

// Define the shape of the data our context will provide
type UserContextType = {
  profile: UserProfile | null;       // the logged-in user's profile (or null if not logged in)
  loading: boolean;                  // whether we are still fetching data
  refreshProfile: () => Promise<void>; // function to reload the profile manually
};

// Create the actual context object with default values
// These defaults are used only if a component tries to read the context
// without being wrapped in <UserProvider>
const UserContext = createContext<UserContextType>({
  profile: null,
  loading: true,
  refreshProfile: async () => {}, // empty function placeholder
});

// This component wraps around children and provides user data to them
export function UserProvider({ children }: { children: React.ReactNode }) {
  // State variables to hold the profile and loading status
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  // Function to load the current user's profile from Supabase
  async function loadProfile() {
    setLoading(true); // show loading while fetching

    // Ask Supabase who the current logged-in user is
    const {
      data: { user },
    } = await supabase.auth.getUser();

    // If no user is logged in, clear profile and stop loading
    if (!user) {
      setProfile(null);
      setLoading(false);
      return;
    }

    // If a user exists, fetch their profile row from the "profiles" table
    const { data, error } = await supabase
      .from("profiles")     // look in "profiles" table
      .select("*")          // select all columns
      .eq("id", user.id)    // only the row where id matches the logged-in user
      .single();            // expect exactly one row

    // If successful, save the profile into state
    if (!error && data) {
      setProfile(data as UserProfile);
    } else {
      // Otherwise log the error for debugging
      console.error("Error loading profile:", error?.message);
    }

    setLoading(false); // done loading
  }

  // useEffect runs once when the provider mounts
  useEffect(() => {
    // Load profile immediately
    loadProfile();

    // Also listen for authentication state changes (login/logout)
    // Whenever auth changes, reload the profile
    const { data: listener } = supabase.auth.onAuthStateChange(() => {
      loadProfile();
    });

    // Cleanup: unsubscribe from the listener when component unmounts
    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  // Provide the profile, loading state, and refresh function to all children
  return (
    <UserContext.Provider value={{ profile, loading, refreshProfile: loadProfile }}>
      {children}
    </UserContext.Provider>
  );
}

// Custom hook to easily access the UserContext in other components
export function useUser() {
  return useContext(UserContext);
}

```

### :jigsaw: What UserContext.tsx code does:

This file creates a **Global Profile Context** in React that stores the logged‑in user’s profile and makes it available to all components without each one having to fetch it separately.

<details>
<summary> Show detailed explanation for useUserProfile.tsx</summary>

### Step‑by‑Step Walkthrough

1. **Imports**  
   - `createContext` → makes the "notice board."  
   - `useContext` → lets components read from the board.  
   - `useEffect` → runs code when the provider loads or when auth changes.  
   - `useState` → stores profile and loading state.  
   - `supabase` → talks to your database/auth system.  
   - `UserProfile` type → ensures TypeScript knows the shape of the profile.

2. **Define Context Type**  
   ```ts
   type UserContextType = {
     profile: UserProfile | null;
     loading: boolean;
     refreshProfile: () => Promise<void>;
   };
   ```
   - This says: "Our context will provide three things: the profile, whether it’s loading, and a function to refresh the profile."

3. **Create Context with Defaults**  
   ```ts
   const UserContext = createContext<UserContextType>({
     profile: null,
     loading: true,
     refreshProfile: async () => {},
   });
   ```
   - This sets up the notice board with placeholder values.  
   - If a component tries to read the context without being wrapped in the provider, it sees these defaults.

4. **UserProvider Component**  
   - Wraps around your app.  
   - Manages the real profile state and keeps the board updated.  

   Inside it:  
   - `profile` and `loading` states are created.  
   - `loadProfile()` fetches the current user from Supabase:  
     - If no user → clears profile.  
     - If user exists → queries the `profiles` table for their row.  
     - Updates state accordingly.  

   - `useEffect` runs once when the provider mounts:  
     - Calls `loadProfile()` immediately.  
     - Subscribes to Supabase auth changes (login/logout).  
     - Reloads profile whenever auth changes.  
     - Cleans up the subscription when the provider unmounts.

   - Finally, it provides `{ profile, loading, refreshProfile: loadProfile }` to all children via `UserContext.Provider`.

5. **useUser Hook**  
   ```ts
   export function useUser() {
     return useContext(UserContext);
   }
   ```
   - This is a shortcut so components don’t have to call `useContext(UserContext)` directly.  
   - Any component can just do:  
     ```ts
     const { profile, loading, refreshProfile } = useUser();
     ```

---

#### ⚙️ How It Works in Practice

- We wrap our app in `<UserProvider>`.  
- Any component inside can call `useUser()` to instantly know:  
  - Who the current user is (`profile`).  
  - Whether data is still loading (`loading`).  
  - How to manually refresh the profile (`refreshProfile`).  
- If the user logs in or out, Supabase notifies the provider, and the context updates automatically so all components see the change without extra work.

</details>

### :brain: Summary

:white_check_mark: **Analogy Recap:** Global Profile Context is like a lobby notice board showing the current user for the whole building. <br/>
:white_check_mark: **Code Recap:** `UserProvider` keeps that board updated with Supabase data, and `useUser()` lets any component read from it easily. <br/>


---

### :hammer_and_wrench: 4. Update `ProtectedRoute.tsx`

Now it can use the **shared** user context (no separate fetch needed):

```tsx

// This component prevents users from accessing certain pages unless they are logged in.
// It can also restrict access to certain pages only for admin users.

import React from "react"; 
// Import React (needed for JSX, though in newer versions it's optional)

import { Navigate } from "react-router-dom"; 
// Navigate lets us redirect users to another page (e.g., login or dashboard)

import { useUser } from "../context/UserContext"; 
// Custom hook that gives us the current user's profile and loading state
// Instead of checking Supabase directly here, we rely on context to manage auth state

// Define the props that this component accepts
type ProtectedRouteProps = {
  children: React.ReactElement; // The page/component we want to protect
  adminOnly?: boolean; // Optional flag: if true, only admin users can access
};

// Main component definition
export default function ProtectedRoute({ children, adminOnly = false }: ProtectedRouteProps) {
  // Get the current user profile and loading state from context
  const { profile, loading } = useUser();

  // While checking if the user is logged in, show a loading message
  // This prevents flickering or showing protected content before we know the auth state
  if (loading) {
    return <p style={{ textAlign: "center", padding: "2rem" }}>Loading...</p>;
  }

  // If the user is NOT logged in, redirect them to the login page
  if (!profile) {
    return <Navigate to="/login" replace />;
    // "replace" means we don't keep the current page in browser history
    // so the user can't click "back" and return to the protected page
  }

  // If this route is admin-only, but the user is not an admin, redirect them
  if (adminOnly && !profile.is_admin) {
    return <Navigate to="/dashboard" replace />;
    // This ensures non-admin users can't access admin-only pages
  }

  // If the user is logged in (and admin if required), show the protected page
  return children;
}

```

---

### :hammer_and_wrench: 5. Update `Navbar.tsx` to use same context

```tsx

// Import navigation tools from react-router-dom
// NavLink = clickable navigation links
// useNavigate = lets us redirect users programmatically
import { NavLink, useNavigate } from "react-router-dom";

// Import supabase client (handles authentication like login/logout)
import { supabase } from "../supabaseClient";

// Import custom UserContext hook
// useUser = gives us access to the current user's profile info (shared globally)
import { useUser } from "../context/UserContext";

// Define the Navbar component
export default function Navbar() {
  // Get the user's profile from context
  // profile = object with user info (like name, role, is_admin)
  const { profile } = useUser();

  // Create a navigate function to redirect users
  const navigate = useNavigate();

  // Function to log out the user
  const handleLogout = async () => {
    // Ask supabase to sign out (end session)
    await supabase.auth.signOut();
    // Redirect user to login page after logout
    navigate("/login");
  };

  // Check if user is logged in
  // !!profile = true if profile exists, false if null/undefined
  const isLoggedIn = !!profile;

  // JSX returned by the component (what shows on screen)
  return (
    <nav className="navbar"> {/* Navigation bar wrapper */}
      <div className="container"> {/* Centers content */}
        
        {/* Logo that links to home page */}
        <NavLink to="/" className="logo">MyWebsite</NavLink>

        {/* Navigation links list */}
        <ul className="nav-links">
          
          {/* Always show Home and About links */}
          <li><NavLink to="/">Home</NavLink></li>
          <li><NavLink to="/about">About</NavLink></li>

          {/* If user IS logged in → show Dashboard link */}
          {isLoggedIn && <li><NavLink to="/dashboard">Dashboard</NavLink></li>}

          {/* If user IS logged in AND is an admin → show User Manager link */}
          {isLoggedIn && profile?.is_admin && (
            <li><NavLink to="/admin/users">User Manager</NavLink></li>
          )}

          {/* If user is NOT logged in → show Login link */}
          {!isLoggedIn && <li><NavLink to="/login">Login</NavLink></li>}

          {/* If user IS logged in → show Logout button */}
          {isLoggedIn && (
            <li>
              {/* Logout button calls handleLogout when clicked */}
              <button className="logout-btn" onClick={handleLogout}>
                Logout
              </button>
            </li>
          )}
        </ul>
      </div>
    </nav>
  );
}

```

---
### :hammer_and_wrench: 6. Update `App.tsx` to Wrap Everything
The UserProvider wraps our app in App.tsx and then useUser() context is available globally. That’s the final piece to make it all work.

Lets wrap our entire app inside `UserProvider`.

```tsx

// Import tools from React Router:
// - BrowserRouter: wraps the whole app to enable routing
// - Routes: container for all route definitions
// - Route: defines a single route (URL path → component)
import { BrowserRouter, Routes, Route } from "react-router-dom";

// Import global CSS styles for the app
import './App.css'

// Import the Layout component (shared page structure like header/footer)
import Layout from "./components/Layout";

// Import individual page components
import Home from "./pages/Home";         // Home page
import About from "./pages/About";       // About page
import Login from "./pages/Login";       // Login page

// Import ProtectedRoute (wrapper that checks if user is logged in or admin)
import ProtectedRoute from "./components/ProtectedRoute";

// Import Dashboard page (only accessible when logged in)
import Dashboard from "./pages/Dashboard";

// Import UserManager page (only accessible to admin users)
import UserManager from "./pages/UserManager";

// Import UserProvider (context provider that shares user info across the app)
import { UserProvider } from "./context/UserContext";

// Main App component — this is the root of your React application
export default function App() {
  return (
    // BrowserRouter enables navigation between pages using URLs
    <BrowserRouter>
      {/* UserProvider makes user data (profile, loading state, etc.)
          available to all components inside it */}
      <UserProvider>
        {/* Layout wraps all pages with common UI (like header, footer, sidebar) */}
        <Layout>
          {/* Routes contains all the different paths (URLs) in the app */}
          <Routes>
            {/* Public routes (anyone can access) */}
            <Route path="/" element={<Home />} />       {/* Home page at "/" */}
            <Route path="/about" element={<About />} /> {/* About page at "/about" */}
            <Route path="/login" element={<Login />} /> {/* Login page at "/login" */}

            {/* Protected route — only logged-in users can see Dashboard */}
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />

            {/* Admin-only protected route — only admin users can see UserManager */}
            <Route
              path="/admin/users"
              element={
                <ProtectedRoute adminOnly>
                  <UserManager />
                </ProtectedRoute>
              }
            />
          </Routes>
        </Layout>
      </UserProvider>
    </BrowserRouter>
  );
}

```

---

## :test_tube: 7. Test Checklist

| Action                                  | Expected Result                             |
| --------------------------------------- | ------------------------------------------- |
| Login as normal user                    | Navbar does **not** show “User Manager”     |
| Login as admin                          | Navbar **does** show “User Manager”         |
| Normal user types `/admin/users` in URL | Redirected to `/dashboard`                  |
| Admin visits `/admin/users`             | ✅ Page loads with table                     |
| Logged-out user tries `/admin/users`    | Redirects to `/login`                       |
| Admin refreshes `/admin/users`          | Still works (session persists)              |
| Admin logs out                          | Navbar instantly updates, redirect to login |

---

[Back](./05-Protected_Routes.md) -- [Next](./07-Admin_CRUD.md)