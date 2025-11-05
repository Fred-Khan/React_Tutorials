
## 🔐 Part 5 – Protected Routes + Supabase Row Level Security (RLS)

### 🎯 Learning Goals

✅ Understand what **Protected Routes** are in React
✅ Prevent access to pages unless the user is logged in
✅ Create a `<ProtectedRoute>` wrapper component
✅ Apply it to the `/dashboard` (logged-in users only)
✅ Apply a **second protection layer** for future admin-only pages
✅ Enable **Row Level Security (RLS)** in Supabase
✅ Write policies so **only admins can manage user profiles**

---

## 🧠 What Are Protected Routes?

A **Protected Route**:

* ✅ Lets the user in *only if authenticated*
* ❌ Redirects the user if they try to visit the page manually
* ✅ Works even if the user modifies the URL
* ✅ Is required because hiding links is **NOT** security

Example of unsafe behaviour (current state):

```
User is logged out → types http://localhost:5173/dashboard → page loads anyway ❌
```

What we want:

```
User is logged out → types http://localhost:5173/dashboard → redirected ➜ http://localhost:5173/login ✅
```

✅ Protected Routes = **front-end access security**
✅ Combined with Supabase RLS from [Part 4 – React + Supabase Authentication](./04-Login_Using_Supabase_Auth.md) = **full-stack protection**

---

## 🛠 Step 1 — Create `ProtectedRoute.tsx` in `components` folder

📌 This component **wraps any route** and checks Supabase session before allowing access. It acts like a security guard. When you try to visit a protected page, it checks with Supabase to see if you’re logged in.

* If you are, it lets you in.
* If you’re not, it sends you to the login page.
* While it’s checking, it shows nothing briefly.

```tsx
// src/components/ProtectedRoute.tsx

// This component prevents users from accessing certain pages unless they are logged in.
import { Navigate } from "react-router-dom"; // This lets us redirect users to another page (e.g., login page)
import { useEffect, useState } from "react";
import type { PropsWithChildren } from "react"; // type-only import
import { supabase } from "../supabaseClient";


export default function ProtectedRoute({ children }: PropsWithChildren) {
  // Tracks whether the user is logged in
  const [isAuthenticated, setIsAuthenticated] = useState<boolean | null>(null);

  useEffect(() => {
    // Check if a valid session exists (e.g., user already logged in)
    supabase.auth.getSession().then(({ data: { session } }) => {
      setIsAuthenticated(!!session); // true if logged in, false if logged out
    });

    // Listen for future login/logout events (reactive updates)
    const { data: listener } = supabase.auth.onAuthStateChange(
      (_event, session) => {
        setIsAuthenticated(!!session);
      }
    );

    // Cleanup the listener when component unmounts
    return () => listener.subscription.unsubscribe();
  }, []);

  // While checking auth state, don't show anything (prevents flicker)
  if (isAuthenticated === null) {
    return null; // or return a loading spinner if you want
  }

  // If NOT logged in, redirect to Login page
  if (!isAuthenticated) {
    return <Navigate to="/" replace />;
    // OPTIONAL: Change "/"  to "/login" if you prefer sending users back to Login Page
    // return <Navigate to="/login" replace />;
  }

  // If logged in, allow page to render normally
  return <>{children}</>;
}

```

---

### 🧠 Breakdown

| Code                       | What It Means                                            |
| -------------------------- | -------------------------------------------------------- |
| `getSession()`             | Checks if Supabase has an active login token             |
| `isAuthenticated === null` | App is still loading → prevents “flash of private page”  |
| `<Navigate to="/login" />` | Redirects user away when not logged in                   |
| `children`                 | Whatever page you're trying to protect (Dashboard, etc.) |

---

## 🛠 Step 2 — Apply Protected Route in `App.tsx`

```tsx
import ProtectedRoute from "./components/ProtectedRoute";
import Dashboard from "./pages/Dashboard"; // already created earlier

// Inside <Routes> ...
          <Route path="/dashboard" element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
```

✅ Now, `/dashboard` can *only* be viewed if logged in
✅ Page refresh still works because Supabase session persists
✅ Typing the URL manually won’t bypass protection

---

## ✅ Optional Variant
If you want to *choose redirect behaviour*, swap this:

```tsx
return <Navigate to="/" replace />; // redirect to home page
```

with:

```tsx
return <Navigate to="/login" replace />; // redirect to login page
```


---

## 🧪 Testing Checklist

| Test                                        | Expected Result                  |
| ------------------------------------------- | -------------------------------- |
| Logged out user clicks Dashboard            | Redirected to Login ✅            |
| Logged out user types `/dashboard` manually | Redirected ✅                     |
| Logged in user refreshes `/dashboard`       | Page loads ✅                     |
| Logout and then refresh while on dashboard  | Redirects ✅                      |
| Login again                                 | Dashboard link becomes visible ✅ |

---
## :bricks: Security Note

In **Part 4 – React + Supabase Authentication for Beginners**, we configured **RLS** as soon as we created the table. This action secured our backend database.

In this exercise we secured our front-end with React's **Protected Routes**. We should now have a properly secure application at this point.

📌 When creating a new full stack application always secure in this order **database protection → front-end protection**.

---

## :fast_forward: What’s Next (Part 6 Preview)

In Part 6 we will be Building the **Admin User Manager UI**

✔️ Show all users (admin only)
✔️ Add new users
✔️ Update existing users
✔️ Demonstrate Supabase CRUD queries
✔️ Optional: Modal form for Create/Edit user

---

[Back](04.5-React_Login_State.md) -- [Next](06-Admin_User_Manager_UI.md)
