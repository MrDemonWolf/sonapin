# UI/UX Review: SonaPin Landing Page and Documentation

**Reviewed:** 2026-09-24 · **Input:** SonaPin landing page, app guide, support, privacy, terms, and acknowledgments · **Method:** NN/g heuristic review, responsive browser inspection, and E2E checks

## Executive summary

- The previous hero led with a disabled App Store action and sent interested visitors to GitHub instead of showing a clear next step.
- The website had a setup guide but no documentation index, and the guide explained visual app flows without showing the app screens.
- Long privacy and terms pages had no in-page navigation.
- The homepage now has an active “Explore the badge” route and a docs hub. The guide includes actual app screenshots; policy pages have compact section links.
- The visual system uses quiet editorial typography, restrained navy/cyan, simple card surfaces, and fewer decorative gradients. Product and legal facts remain unchanged.

**Findings:** 🟥 0 catastrophic · 🟧 0 major · 🟨 3 minor (resolved) · ⬜ 0 cosmetic

## Findings

### 🟨 Severity 2 — Minor (resolved)

#### 1. The main hero action was unavailable before launch

- **What:** The primary hero button was disabled, while the enabled secondary action sent visitors to the source repository. That left first-time visitors without a useful product-exploration path.
- **Where:** Landing-page hero, before the first scroll.
- **Guideline:** The next step should be visible and match the visitor’s likely goal; visual hierarchy should make the useful action easy to find.
- **Evidence:** NN/g’s visual-hierarchy guidance explains how size, contrast, and grouping guide attention ([Visual Hierarchy in UX](https://www.nngroup.com/articles/visual-hierarchy-ux-definition/)). The review was based on the implemented page, not a user study.
- **Fix:**
  - [x] Add an active “Explore the badge” anchor to product features.
  - [x] Keep the unavailable iOS action visible but disabled and explicitly labeled “Coming soon.”
  - [x] Link directly to the docs hub from the hero.

#### 2. Product help was fragmented and the guide lacked visual examples

- **What:** Visitors had to find separate support, policy, and guide links without a documentation index. The text-only setup guide described avatar selection, profile editing, and badge mode without showing those app screens.
- **Where:** Landing-page navigation and footer; `/guide/`.
- **Guideline:** Make help easy to find and use scannable labels, visual hierarchy, and examples that support recognition rather than requiring readers to remember descriptions.
- **Evidence:** NN/g’s usability heuristics cover recognition rather than recall and accessible help/documentation ([10 Usability Heuristics](https://www.nngroup.com/articles/ten-usability-heuristics/)). NN/g also recommends scannable web content because readers tend to scan rather than read every line ([How Users Read on the Web](https://www.nngroup.com/articles/how-users-read-on-the-web/)).
- **Fix:**
  - [x] Add a docs hub linking the guide, troubleshooting, privacy policy, terms, and acknowledgments.
  - [x] Add actual app screenshots with descriptive alt text and short captions to the guide.
  - [x] Make Docs discoverable from the primary navigation and page footers.

#### 3. Long policy pages required too much scrolling to reach a section

- **What:** The privacy policy has 12 numbered sections and the terms have 15. Readers previously had to scroll through each page to locate a specific topic.
- **Where:** `/privacy/` and `/terms/`.
- **Guideline:** Chunk long content with descriptive headings and provide direct paths to relevant sections.
- **Evidence:** NN/g finds that scannable headings and concise navigation help people find information on the web ([How Users Read on the Web](https://www.nngroup.com/articles/how-users-read-on-the-web/); [Scrolling and Attention](https://www.nngroup.com/articles/scrolling-and-attention/)).
- **Fix:**
  - [x] Add collapsed, native section jump lists with descriptive labels; the legal wording is unchanged.
  - [x] Keep anchor targets clear of the sticky header when reached.
  - [x] Add E2E checks for policy-link counts and direct navigation.

## Unverified (needs a different input to check)

- Whether convention attendees understand the app’s value and the “Explore the badge” label without prompting; no moderated first-time-user study was available.
- Real VoiceOver behavior and color perception across supported iOS/macOS/browser combinations; automated browser checks do not replace assistive-technology testing.
- Whether every screenshot and screen label will remain current as the iOS app changes before release.

## What’s working well

- The landing page states the product’s purpose early and keeps the App Store status honest.
- Real app screens now demonstrate the avatar, profile, and badge experience instead of using a decorative mock interface.
- The site keeps a visible Docs route, a separate theme control, keyboard focus styles, reduced-motion handling, and the existing dark/light screenshot pairing.
- On the 375 × 812 phone viewport, the page has one H1, 16px body text with 1.6 line height, a 44px Menu control, and no horizontal overflow. The main CTA is visible before the device preview.
- The information architecture uses the direct product navigation and concise value proposition seen on [ConPaws](https://conpaws.com/) and [WolfWave](https://mrdemonwolf.github.io/wolfwave/) as references, without copying either site’s full layout.

## Quick wins

- [x] Replace the disabled-only hero flow with an active feature link while keeping the future store action disabled.
- [x] Add a dedicated docs index and link it from the homepage, navigation, and supporting pages.
- [x] Add screenshots and captions to the setup guide.
- [x] Add jump navigation to the long legal pages without changing their wording.
- [x] Run the responsive and docs-flow E2E suite after updating its landing-page assertions.
