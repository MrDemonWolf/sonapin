# UI/UX Review: SonaPin Navbar

**Reviewed:** 2026-09-24 · **Input:** SonaPin website and docs, ConPaws local repository, WolfWave live website · **Method:** NN/g heuristic evaluation and mobile navigation review

## Executive summary

- The prior phone layout hid most primary links, leaving users without a clear route to features or support.
- The updated header keeps concise links on larger screens and provides a labeled, native Menu disclosure on phones.
- Docs pages retain a visible current-page cue, and the menu closes after a destination is selected.
- The design follows the reference sites' direct navigation and restrained branded header rather than copying their full layouts.

**Findings:** 🟥 0 catastrophic · 🟧 0 major · 🟨 1 minor (resolved) · ⬜ 0 cosmetic

## Findings

### 🟨 Severity 2 — Minor (resolved)

#### 1. Mobile users could not discover most primary destinations

- **What:** At phone widths the old CSS hid the Features, How it works, and Support links. Only App guide remained visible, so users could miss key product and help content.
- **Where:** SonaPin sticky header at widths of 600px and below.
- **Guideline:** Navigation should remain discoverable on mobile. If links move behind a menu, the menu control should be visible, clearly labeled, and easy to tap. Consistent navigation and a clear current-location cue help people orient themselves.
- **Evidence:** NN/g recommends visible navigation or a clearly labeled, salient menu control on mobile ([mobile navigation](https://www.nngroup.com/articles/find-navigation-mobile-even-hamburger/)); it also identifies inconsistent navigation and unclear current location as information-architecture problems ([IA mistakes](https://www.nngroup.com/articles/top-10-ia-mistakes/)). This was a code inspection, not a moderated usability study.
- **Fix:**
  - [x] Keep the short primary-link row on desktop.
  - [x] Use a visible “Menu” disclosure on phones, with 48px navigation rows.
  - [x] Mark the active docs page and close the menu when a link is chosen.
  - [x] Verify the mobile interaction and narrow-screen layout with Playwright.

## Unverified (needs a different input to check)

- Whether first-time users recognize and use the mobile Menu control in real tasks; no user study or analytics data was available.
- Screen-reader behavior across browsers and assistive technologies; automated tests check semantics and interaction but do not replace hands-on assistive-technology testing.

## What's working well

- The badge and SonaPin name create a clear home link.
- Desktop navigation remains visible and concise, following WolfWave's direct links to product sections and docs.
- ConPaws uses a compact, consistent branded header across its main pages; SonaPin applies that same restraint while adding the destinations its docs need.
- The theme control remains separate from page navigation and keeps its existing accessible name.

## Quick wins

- [x] Remove the hidden-link-only phone behavior and make every primary destination reachable from the header.
- [x] Keep the iOS availability notice informational in the desktop header; store actions remain disabled in the hero until release.
- [x] Add an end-to-end check for opening the menu, navigating to an anchor, closing it, and showing the active docs link.
