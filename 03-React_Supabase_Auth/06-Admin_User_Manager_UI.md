## 🚀 Part 6 – Admin User Manager UI (Admin-Only Page)

### 🎯 Learning Goals

By the end of this part, students will:

✅ Create an **Admin-only page** called `UserManager.tsx`
✅ Fetch all users from Supabase (only works for admins because of RLS)
✅ Display users in a simple table
✅ Add “Create New User” button (placeholder for now)
✅ Add “Edit” button per user (placeholder for now)
✅ Know how to protect this page using **role-based access**, not just authentication
✅ Understand how RLS and frontend checks work together

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

✅ UI checks
✅ ProtectedRoute checks
✅ Database RLS checks (already built in Part 4)

---

### 🧠 What Makes This Page “Admin-Only”?

| Feature                                               | Exists Already? | Level          |
| ----------------------------------------------------- | --------------- | -------------- |
| ✅ Login required                                      | Done in Part 5  | App level      |
| ✅ Dashboard protected route                           | Done in Part 5  | App level      |
| ✅ RLS prevents non-admins from querying other users   | Done in Part 4  | Database level |
| 🔜 UI should **hide this page** from non-admins       | Part 6          | UI level       |
| 🔜 ProtectedRoute must also check `is_admin === true` | Part 6          | App level      |

So this part = **front-end access control + admin UI creation**.

---

## 🛠 Step 1 — Create `UserManager.tsx` page

📌 This page:

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

✅ Works only for admins
✅ Non-admins will fetch **zero rows** because of RLS
✅ Table layout is intentionally simple for beginners

---

## 🛠 Step 2 — Create `useUserProfile()` Hook

📌 This hook fetches the logged-in user’s profile from Supabase and returns
`{ loading, profile, isAdmin }`.

:memo: `src/hooks/useUserProfile.tsx`

```ts

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

### :brain: How this works

| Line                                  | Purpose                               |
| ------------------------------------- | ------------------------------------- |
| `supabase.auth.getUser()`             | Gets the logged-in Supabase Auth user |
| Query on `profiles` table             | Fetches first/last name + is_admin    |
| `isAdmin: profile?.is_admin === true` | Returns `true` only for admin users   |
| `null` when logged out                | Prevents errors when no user exists   |

---

## ✅ Global Profile Context

`useUserProfile()` creates a *new instance of profile state every time* it’s called.

Each component that calls this hook (Navbar, ProtectedRoute) runs its own independent copy of the hook, meaning they don’t share profile data.

We’ll creatie a **global `UserContext`** that loads the profile *once* and shares it across all components (`Navbar`, `ProtectedRoute`, `Dashboard`, etc.).



### 🧱 Step 3. Create `/src/context/UserContext.tsx`

```tsx

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

---

### 🧱 Step 4. Update `ProtectedRoute.tsx`

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

### 🧱 Step 5. Update `Navbar.tsx` to use same context

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
### 🧱 Step 6. Update `App.tsx` to Wrap Everything
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

[Back](05-Protected_Routes.md) -- [Next]()