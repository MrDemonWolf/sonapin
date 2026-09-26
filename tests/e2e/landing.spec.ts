import { expect, test } from "@playwright/test";

test("shows TestFlight release status and a working source link", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { level: 1 })).toContainText("Your sona");
  await expect(page.getByRole("link", { name: /Explore the badge/i })).toHaveAttribute("href", "#features");
  await expect(page.getByRole("button", { name: /TestFlight release active/i })).toHaveCount(2);
  for (const button of await page.getByRole("button", { name: /TestFlight release active/i }).all()) {
    await expect(button).toBeDisabled();
  }
  await expect(page.getByRole("link", { name: /View source on GitHub/i }).first()).toHaveAttribute(
    "href",
    "https://github.com/MrDemonWolf/sonapin",
  );
});

test("manually switches between genuine app screens and ends on the badge", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");

  await expect(page.getByRole("img", { name: /SonaPin full-screen badge/i })).toBeVisible();
  const screenshot = page.locator("#app-screen");
  await expect(screenshot).toHaveAttribute("src", /screenshots\/badge-capture\.png$/);
  expect(await screenshot.evaluate((element) => element.clientWidth / element.clientHeight)).toBeLessThan(0.5);

  const chooseAvatar = page.getByRole("button", { name: "Choose avatar" });
  const addDetails = page.getByRole("button", { name: "Add details" });
  const seeBadge = page.getByRole("button", { name: "See your badge" });
  await expect(seeBadge).toHaveAttribute("aria-pressed", "true");
  await chooseAvatar.click();
  await expect(screenshot).toHaveAttribute("src", /screenshots\/avatar\.png$/);
  await expect(screenshot).toHaveAttribute("alt", /SonaPin avatar screen/);
  await addDetails.click();
  await expect(screenshot).toHaveAttribute("src", /screenshots\/details\.jpg$/);
  await seeBadge.click();
  await expect(screenshot).toHaveAttribute("src", /screenshots\/badge-capture\.png$/);
  await expect(seeBadge).toHaveAttribute("aria-pressed", "true");

  await page.getByRole("button", { name: "Switch to dark appearance" }).first().click();
  await chooseAvatar.click();
  await expect(screenshot).toHaveAttribute("src", /screenshots\/avatar-dark\.png$/);
  await addDetails.click();
  await expect(screenshot).toHaveAttribute("src", /screenshots\/details-dark\.png$/);
  await seeBadge.click();
  await expect(screenshot).toHaveAttribute("src", /screenshots\/badge-capture-dark\.png$/);
  await expect(screenshot).toHaveAttribute("alt", /full-screen badge in dark appearance/i);
});

test("automatically rotates through app screens and can be paused", async ({ page }) => {
  await page.clock.install();
  await page.emulateMedia({ colorScheme: "light", reducedMotion: "no-preference" });
  await page.goto("/");

  const screenshot = page.locator("#app-screen");
  const rotationToggle = page.getByRole("button", { name: "Pause screen rotation" });
  await expect(rotationToggle).not.toHaveAttribute("aria-pressed");
  await page.clock.fastForward(6000);
  await expect(screenshot).toHaveAttribute("src", /screenshots\/avatar\.png$/);

  await rotationToggle.click();
  await expect(page.getByRole("button", { name: "Play screen rotation" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Play screen rotation" })).not.toHaveAttribute("aria-pressed");
  await page.clock.fastForward(12000);
  await expect(screenshot).toHaveAttribute("src", /screenshots\/avatar\.png$/);

  await page.emulateMedia({ colorScheme: "light", reducedMotion: "reduce" });
  await page.goto("/");
  await expect(page.getByRole("button", { name: "Play screen rotation" })).toBeVisible();
  await page.clock.fastForward(12000);
  await expect(page.locator("#app-screen")).toHaveAttribute("src", /screenshots\/badge-capture\.png$/);
});

test("keeps rotation paused after focus leaves until Play and respects hover and visibility", async ({ page }) => {
  await page.clock.install();
  await page.emulateMedia({ reducedMotion: "no-preference" });
  await page.goto("/");

  const screenshot = page.locator("#app-screen");
  const chooser = page.locator(".screen-chooser");
  const chooseAvatar = page.getByRole("button", { name: "Choose avatar" });
  await chooser.hover();
  await chooseAvatar.focus();
  await chooseAvatar.evaluate((element) => (element as HTMLElement).blur());

  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", { configurable: true, value: true });
    document.dispatchEvent(new Event("visibilitychange"));
    Object.defineProperty(document, "hidden", { configurable: true, value: false });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await page.clock.fastForward(12000);
  await expect(screenshot).toHaveAttribute("src", /screenshots\/badge-capture\.png$/);
  await expect(page.getByRole("button", { name: "Play screen rotation" })).toBeVisible();

  await page.getByRole("button", { name: "Play screen rotation" }).click();
  await expect(page.getByRole("button", { name: "Pause screen rotation" })).toBeVisible();
  await page.clock.fastForward(12000);
  await expect(screenshot).toHaveAttribute("src", /screenshots\/badge-capture\.png$/);

  await page.mouse.move(0, 0);
  await page.clock.fastForward(6000);
  await expect(screenshot).toHaveAttribute("src", /screenshots\/avatar\.png$/);

  await page.emulateMedia({ reducedMotion: "reduce" });
  await expect(page.getByRole("button", { name: "Play screen rotation" })).toBeVisible();
  await page.clock.fastForward(6000);
  await expect(screenshot).toHaveAttribute("src", /screenshots\/avatar\.png$/);
});

test("defaults to the OS theme and persists a theme choice across docs pages", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");

  const root = page.locator("html");
  await expect(root).toHaveAttribute("data-theme", "light");
  await page.getByRole("button", { name: "Switch to dark appearance" }).click();
  await expect(root).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("#app-screen")).toHaveAttribute("src", /screenshots\/badge-capture-dark\.png$/);
  await expect(page.locator("#screen-caption")).toContainText("Actual dark-mode capture · See your badge");
  await page.reload();
  await expect(root).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("#app-screen")).toHaveAttribute("src", /screenshots\/badge-capture-dark\.png$/);

  await page.goto("/support/");
  await expect(root).toHaveAttribute("data-theme", "dark");
  await expect(page.getByRole("button", { name: "Switch to light appearance" })).toBeVisible();
  await expect(page.getByRole("button", { name: "Switch to light appearance" })).toHaveText("☀");
  await page.goto("/guide/");
  await expect(page.getByRole("heading", { name: "From first tap to your badge." })).toBeVisible();
  await expect(page.getByRole("link", { name: "Set up your badge" })).toHaveAttribute("href", "#badge");
});

test("keeps support and privacy pages reachable", async ({ page }) => {
  await page.goto("/support/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();

  await page.goto("/privacy/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
});

test("mobile menu exposes navigation and closes after a link is chosen", async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/");

  const menu = page.locator(".mobile-menu");
  await menu.locator("summary").click();
  await expect(menu.getByRole("link", { name: "Support" })).toBeVisible();
  const featuresLink = menu.locator('a[href="#features"]');
  await expect(featuresLink).toBeVisible();
  await featuresLink.click();
  await expect(menu).not.toHaveAttribute("open");
  await expect(page).toHaveURL(/#features$/);

  await page.goto("/guide/");
  await menu.locator("summary").click();
  await expect(menu.getByRole("link", { name: "Docs" })).toBeVisible();
});

test("docs hub links to the guide and complete support and policy pages", async ({ page }) => {
  await page.goto("/docs/");
  await expect(page.getByRole("heading", { level: 1 })).toContainText("Everything you need");
  await page.getByRole("link", { name: /Read the app guide/i }).click();
  await expect(page).toHaveURL(/\/guide\/$/);
  await expect(page.locator(".guide-shot img")).toHaveCount(3);

  await page.goto("/privacy/");
  await expect(page.locator(".policy-toc a")).toHaveCount(12);
  await page.locator(".policy-toc summary").click();
  await page.locator('.policy-toc a[href="#contact"]').click();
  await expect(page).toHaveURL(/#contact$/);
  await expect(page.locator("#contact")).toBeInViewport();

  await page.goto("/terms/");
  await expect(page.locator(".policy-toc a")).toHaveCount(15);
});

test("keeps the page usable on a narrow phone", async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/");

  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  await expect(page.locator(".hero-copy .store-button")).toBeVisible();
  await expect(page.getByRole("img", { name: /SonaPin full-screen badge/i })).toBeVisible();
  const overflow = await page.evaluate(() => ({
    width: document.documentElement.scrollWidth,
    elements: [...document.querySelectorAll("*")]
      .filter((element) => element.getBoundingClientRect().right > innerWidth + 1)
      .map((element) => element.className || element.tagName)
      .slice(0, 8),
  }));
  expect(overflow.width, JSON.stringify(overflow.elements)).toBeLessThanOrEqual(375);
});

test("keeps every public page responsive and key controls easy to tap", async ({ page }) => {
  const routes = ["/", "/docs/", "/guide/", "/support/", "/privacy/", "/terms/", "/acknowledgments/"];

  for (const width of [320, 360, 375, 414, 600, 760, 761, 768, 900]) {
    await page.setViewportSize({ width, height: 812 });
    for (const route of routes) {
      await page.goto(route);
      const overflow = await page.evaluate(() => ({
        viewport: innerWidth,
        document: document.documentElement.scrollWidth,
        overflowingElements: [...document.querySelectorAll("body *")]
          .filter((element) => element.getBoundingClientRect().right > innerWidth + 1)
          .map((element) => element.className || element.tagName)
          .slice(0, 5),
      }));
      expect(overflow.document, `${route} at ${width}px: ${JSON.stringify(overflow.overflowingElements)}`)
        .toBeLessThanOrEqual(width);
      if (route === "/acknowledgments/" && width <= 600) {
        await expect(page.getByText("Scroll horizontally to see all columns.")).toBeVisible();
      }
    }

    await page.goto("/");
    const headerSelector = width <= 760 ? ".theme-toggle, .mobile-menu summary" : ".theme-toggle";
    const headerTargets = await page.locator(headerSelector).evaluateAll((elements) =>
      elements.map((element) => element.getBoundingClientRect().height),
    );
    expect(headerTargets.every((height) => height >= 44), `${width}px header targets: ${headerTargets}`).toBeTruthy();
    await expect(page.locator(".hero .actions .button").first()).toHaveCSS("min-height", "48px");

    await page.goto("/guide/");
    const guideTargets = await page.locator(".guide-toc a").evaluateAll((elements) =>
      elements.map((element) => element.getBoundingClientRect().height),
    );
    expect(guideTargets.every((height) => height >= 44), `${width}px guide targets: ${guideTargets}`).toBeTruthy();

    for (const route of ["/privacy/", "/terms/"]) {
      await page.goto(route);
      await page.locator(".policy-toc summary").click();
      const sectionTargets = await page.locator(".policy-toc nav a").evaluateAll((elements) =>
        elements.map((element) => element.getBoundingClientRect().height),
      );
      expect(sectionTargets.every((height) => height >= 44), `${route} at ${width}px targets: ${sectionTargets}`)
        .toBeTruthy();
    }
  }
});
