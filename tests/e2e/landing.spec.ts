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

test("cycles the badge mood when tapped", async ({ page }) => {
  await page.goto("/");

  const badge = page.getByRole("button", { name: /SonaPin badge/i });
  await expect(badge.locator(".digital-badge__camera")).toBeVisible();
  expect(await badge.evaluate((element) => element.clientWidth / element.clientHeight)).toBeLessThan(0.55);
  await expect(page.getByText("Bright", { exact: true })).toBeVisible();
  await badge.click();
  await expect(page.getByText("Playful", { exact: true })).toBeVisible();
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
  await expect(page.getByRole("button", { name: /Get iOS app/i }).first()).toBeVisible();
  await expect(page.getByRole("button", { name: /SonaPin badge/i })).toBeVisible();
  const overflow = await page.evaluate(() => ({
    width: document.documentElement.scrollWidth,
    elements: [...document.querySelectorAll("*")]
      .filter((element) => element.getBoundingClientRect().right > innerWidth + 1)
      .map((element) => element.className || element.tagName)
      .slice(0, 8),
  }));
  expect(overflow.width, JSON.stringify(overflow.elements)).toBeLessThanOrEqual(375);
});
