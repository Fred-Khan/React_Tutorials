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
import { useEffect, useState } from "react";
import { supabase } from "../supabaseClient";

type Profile = {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  is_admin: boolean;
};

export default function UserManager() {
  const [users, setUsers] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchUsers = async () => {
      const { data, error } = await supabase
        .from("profiles")
        .select("*")
        .order("last_name", { ascending: true });

      if (error) {
        console.error("Error loading users:", error);
      } else {
        setUsers(data as Profile[]);
      }

      setLoading(false);
    };

    fetchUsers();
  }, []);

  if (loading) return <p>Loading users...</p>;

  return (
    <section>
      <h1>User Management</h1>
      <p>Only visible to admin users.</p>

      <button style={{ marginBottom: "1rem" }}>
        ➕ Create New User
      </button>

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
          {users.map((user) => (
            <tr key={user.id}>
              <td>{user.first_name} {user.last_name}</td>
              <td>{user.email}</td>
              <td>{user.is_admin ? "✅ Yes" : "❌ No"}</td>
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
import { useEffect, useState } from "react";
import { supabase } from "../supabaseClient";

export type UserProfile = {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  is_admin: boolean;
};

export function useUserProfile() {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Fetch profile when component mounts or user logs in
    async function loadProfile() {
      const {
        data: { user },
      } = await supabase.auth.getUser();

      if (!user) {
        setProfile(null);
        setLoading(false);
        return;
      }

      // Fetch matching profile row
      const { data, error } = await supabase
        .from("profiles")
        .select("*")
        .eq("id", user.id)
        .single();

      if (!error && data) {
        setProfile(data as UserProfile);
        // Helpful for debugging - shows live profile object in console
        console.log("Loaded profile:", data);
      } else {
        console.error("Error loading profile:", error?.message);
      }

      setLoading(false);
    }

    loadProfile();
  }, []);

  // If user updates their profile later, they can re-run loadProfile() manually.

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
// src/context/UserContext.tsx
import { createContext, useContext, useEffect, useState } from "react";
import { supabase } from "../supabaseClient";
import type { UserProfile } from "../hooks/useUserProfile";

type UserContextType = {
  profile: UserProfile | null;
  loading: boolean;
  refreshProfile: () => Promise<void>;
};

const UserContext = createContext<UserContextType>({
  profile: null,
  loading: true,
  refreshProfile: async () => {},
});

export function UserProvider({ children }: { children: React.ReactNode }) {
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [loading, setLoading] = useState(true);

  async function loadProfile() {
    setLoading(true);
    const {
      data: { user },
    } = await supabase.auth.getUser();

    if (!user) {
      setProfile(null);
      setLoading(false);
      return;
    }

    const { data, error } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", user.id)
      .single();

    if (!error && data) {
      setProfile(data as UserProfile);
    } else {
      console.error("Error loading profile:", error?.message);
    }

    setLoading(false);
  }

  useEffect(() => {
    loadProfile();

    // Re-run when auth state changes
    const { data: listener } = supabase.auth.onAuthStateChange(() => {
      loadProfile();
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  return (
    <UserContext.Provider value={{ profile, loading, refreshProfile: loadProfile }}>
      {children}
    </UserContext.Provider>
  );
}

export function useUser() {
  return useContext(UserContext);
}
```

---

### 🧱 Step 4. Update `ProtectedRoute.tsx`

Now it can use the **shared** user context (no separate fetch needed):

```tsx
import React from "react";
import { Navigate } from "react-router-dom";
import { useUser } from "../context/UserContext";

type ProtectedRouteProps = {
  children: React.ReactElement;
  adminOnly?: boolean;
};

export default function ProtectedRoute({ children, adminOnly = false }: ProtectedRouteProps) {
  const { profile, loading } = useUser();

  if (loading) {
    return <p style={{ textAlign: "center", padding: "2rem" }}>Loading...</p>;
  }

  // Not logged in
  if (!profile) {
    return <Navigate to="/login" replace />;
  }

  // Admin-only route, but user is not admin
  if (adminOnly && !profile.is_admin) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}
```

---

### 🧱 Step 5. Update `Navbar.tsx` to use same context

```tsx
import { NavLink, useNavigate } from "react-router-dom";
import { supabase } from "../supabaseClient";
import { useUser } from "../context/UserContext";

export default function Navbar() {
  const { profile } = useUser();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await supabase.auth.signOut();
    navigate("/login");
  };

  const isLoggedIn = !!profile;

  return (
    <nav className="navbar">
      <div className="container">
        <NavLink to="/" className="logo">MyWebsite</NavLink>

        <ul className="nav-links">
          <li><NavLink to="/">Home</NavLink></li>
          <li><NavLink to="/about">About</NavLink></li>

          {isLoggedIn && <li><NavLink to="/dashboard">Dashboard</NavLink></li>}

          {isLoggedIn && profile?.is_admin && (
            <li><NavLink to="/admin/users">User Manager</NavLink></li>
          )}

          {!isLoggedIn && <li><NavLink to="/login">Login</NavLink></li>}

          {isLoggedIn && (
            <li><button className="logout-btn" onClick={handleLogout}>Logout</button></li>
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
import { BrowserRouter, Routes, Route } from "react-router-dom";
import './App.css'
import Layout from "./components/Layout";
import Home from "./pages/Home";
import About from "./pages/About";
import Login from "./pages/Login";
import ProtectedRoute from "./components/ProtectedRoute";
import Dashboard from "./pages/Dashboard";
import UserManager from "./pages/UserManager";
import { UserProvider } from "./context/UserContext";

export default function App() {
  return (
    <BrowserRouter>
      <UserProvider>
        <Layout>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/about" element={<About />} />
            <Route path="/login" element={<Login />} />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Dashboard />
                </ProtectedRoute>
              }
            />
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