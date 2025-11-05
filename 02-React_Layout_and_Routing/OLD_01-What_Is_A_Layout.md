## :books: What is a Layout in React?

A **layout** in React is like a **template** or **frame** that wraps around your pages or **components**.

Most websites share common elements such as:

* a **navbar** at the top,
* a **footer** at the bottom

Instead of rewriting those parts on every page, we create **one layout component** that holds them — and then each page’s unique content appears *inside* that layout.

---

## :thinking: What is a ***Shared*** Layout?

A **shared layout** means that **multiple pages use the same layout component**.
When users navigate between pages, React keeps the layout visible and only changes the page’s main content.

It’s ***“shared”*** because the layout elements (like the **Navbar** or **Footer**) are shared between all pages.

---

## Visual Diagram

Below is how a shared layout looks conceptually:

![Basic Layout](assets/Basic_Layout.png)


```
--------------------------------
|        Navbar (shared)        |
--------------------------------
|    Page Content (changes)     |
--------------------------------
|        Footer (shared)        |
--------------------------------
```

When a user clicks a link to go from *Home* to *About*,
the **Navbar** and **Footer** stay on the screen,
and only the **Page Content** in the middle changes.

---

## :computer: Simple Example (with React Router)

Here’s a simple version using **React Router v6**.



### :one: `Layout.tsx`

```tsx
import { Outlet, Link } from "react-router-dom";

export default function Layout() {
  return (
    <div>
      <nav>
        <Link to="/">Home</Link> | <Link to="/about">About</Link>
      </nav>

      <hr />

      {/* The child page will be shown here */}
      <Outlet />

      <footer>
        <p>© 2025 My Website</p>
      </footer>
    </div>
  );
}
```

<details>
<summary>Show Line-by-Line Explanation For Layout.tsx</summary>

### :brain: Explanation

**Line 1:**

```tsx
import { Outlet, Link } from "react-router-dom";
```

We import two things from React Router:

* **`Link`**: creates navigation links that change pages without refreshing.
* **`Outlet`**: a placeholder where each child page’s content will appear.

---

**Line 3:**

```tsx
export default function Layout() {
```

This defines a React component called **Layout**.
We export it so other files (like `App.tsx`) can use it.

---

**Lines 4–18:**

```tsx
return (
  <div>
    ...
  </div>
);
```

Everything between `<div>` and `</div>` is what the Layout will display on screen.

---

**Lines 5–8:**

```tsx
<nav>
  <Link to="/">Home</Link> | <Link to="/about">About</Link>
</nav>
```

This creates a **navigation bar** with two links:

* one to the **Home** page (`"/"`)
* one to the **About** page (`"/about"`)

The `|` symbol is just a visual separator.

---

**Line 10:**

```tsx
<hr />
```

A horizontal line separating the navbar from the main content.

---

**Line 12:**

```tsx
<Outlet />
```

This is the **most important part**.
The `<Outlet />` is where React Router will load the current page’s content (for example, `Home` or `About`).
It acts like a *“window”* inside the layout that displays different pages.

---

**Lines 14–17:**

```tsx
<footer>
  <p>© 2025 My Website</p>
</footer>
```

This creates a footer that stays the same across all pages.

---

</details>

### Summary of `Layout.tsx`:

The Layout component defines the **common structure** of the app —
it includes the **navbar**, **page content area (Outlet)**, and **footer**.

---

### :two: `App.tsx`

```tsx
import { BrowserRouter, Routes, Route } from "react-router-dom";
import Layout from "./Layout";
import Home from "./Home";
import About from "./About";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Layout />}>
          {/* These share the same Layout */}
          <Route index element={<Home />} />
          <Route path="about" element={<About />} />
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
```

<details>
<summary>Show Line-by-Line Explanation For App.tsx</summary>

### :brain: Explanation

**Line 1:**

```tsx
import { BrowserRouter, Routes, Route } from "react-router-dom";
```

These are the main components used for routing:

* **BrowserRouter**: wraps the whole app and enables routing.
* **Routes**: groups all your page routes.
* **Route**: defines a single route (a path and its component).

---

**Lines 2–4:**

```tsx
import Layout from "./Layout";
import Home from "./Home";
import About from "./About";
```

We import the components we’ll use:

* the **Layout** (our shared layout)
* two pages: **Home** and **About**

---

**Lines 6–24:**

```tsx
export default function App() {
  return (
    ...
  );
}
```

Defines and exports the main App component that holds all routes.

---

**Line 8:**

```tsx
<BrowserRouter>
```

Wraps everything in React Router’s context, so navigation works properly.

---

**Lines 9–23:**

```tsx
<Routes>
  ...
</Routes>
```

Holds all our route definitions (which pages exist and where they go).

---

**Lines 10–17:**

```tsx
<Route path="/" element={<Layout />}>
  <Route index element={<Home />} />
  <Route path="about" element={<About />} />
</Route>
```

This defines a **parent route** with the path `/` that uses our **Layout** component.

Inside it are **child routes**:

* The first child (`index`) is the **Home** page.
* The second child (`about`) is the **About** page.

When a user visits `/about`, React will:

1. Render the **Layout** (navbar + footer)
2. Insert the **About** page into the `<Outlet />` area.

</details>

---

### 🖼️ How It Works Visually

When you visit `/` (Home page):

```
--------------------------------
| Home | About (Navbar)         |
--------------------------------
|   Home Page Content (Outlet)  |
--------------------------------
|   © 2025 My Website (Footer)  |
--------------------------------
```

When you click **About**, only the middle section changes:

```
--------------------------------
| Home | About (Navbar)         |
--------------------------------
|  About Page Content (Outlet)  |
--------------------------------
|   © 2025 My Website (Footer)  |
--------------------------------
```

:white_check_mark: The **Navbar** and **Footer** remain in place — only the page content updates.

---

## :bulb: Why Shared Layouts Are Useful

1. **Avoid duplication** – You don’t need to copy your navbar/footer for every page.
2. **Faster navigation** – React only changes the part inside `<Outlet />`.
3. **Cleaner structure** – Keeps your code modular and easier to maintain.
4. **Consistent design** – Shared components ensure a unified look across pages.

---

## :brain: In Short

| Concept           | Meaning                                                  |
| ----------------- | -------------------------------------------------------- |
| **Layout**        | A reusable frame that contains common page elements      |
| **Shared Layout** | The same layout used by multiple pages                   |
| **`<Outlet />`**  | A placeholder where page content loads inside the layout |

---
