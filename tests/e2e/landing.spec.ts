import { expect, test } from "@playwright/test";

test("shows an honest iOS placeholder and a working source link", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { level: 1 })).toContainText("Your sona");
  await expect(page.getByText("Coming soon to the App Store")).toBeVisible();
  await expect(page.getByRole("button", { name: /Get iOS app/i })).toHaveCount(3);
  for (const button of await page.getByRole("button", { name: /Get iOS app/i }).all()) {
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

  await expect(page.getByRole("img", { name: /SonaPin badge screen/i })).toBeVisible();
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
});

test("defaults to the OS theme and persists a theme choice across docs pages", async ({ page }) => {
  await page.emulateMedia({ colorScheme: "light" });
  await page.goto("/");

  const root = page.locator("html");
  await expect(root).toHaveAttribute("data-theme", "light");
  await page.getByRole("button", { name: "Switch to dark appearance" }).click();
  await expect(root).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("#app-screen")).toHaveAttribute("src", /screenshots\/badge-capture-dark\.png$/);
  await expect(page.locator("#screen-caption")).toContainText("No QR code is configured in this simulator");
  await page.reload();
  await expect(root).toHaveAttribute("data-theme", "dark");
  await expect(page.locator("#app-screen")).toHaveAttribute("src", /screenshots\/badge-capture-dark\.png$/);

  await page.goto("/support/");
  await expect(root).toHaveAttribute("data-theme", "dark");
  await expect(page.getByRole("button", { name: "Switch to light appearance" })).toBeVisible();
});

test("keeps support and privacy pages reachable", async ({ page }) => {
  await page.goto("/support/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();

  await page.goto("/privacy/");
  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
});

test("keeps the page usable on a narrow phone", async ({ page }) => {
  await page.setViewportSize({ width: 375, height: 812 });
  await page.goto("/");

  await expect(page.getByRole("heading", { level: 1 })).toBeVisible();
  await expect(page.locator(".hero-copy .store-button")).toBeVisible();
  await expect(page.getByRole("img", { name: /SonaPin badge screen/i })).toBeVisible();
  const overflow = await page.evaluate(() => ({
    width: document.documentElement.scrollWidth,
    elements: [...document.querySelectorAll("*")]
      .filter((element) => element.getBoundingClientRect().right > innerWidth + 1)
      .map((element) => element.className || element.tagName)
      .slice(0, 8),
  }));
  expect(overflow.width, JSON.stringify(overflow.elements)).toBeLessThanOrEqual(375);
});
