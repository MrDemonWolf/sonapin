import { expect, test } from "@playwright/test";

test("shows a released product page with a working source link", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { level: 1 })).toContainText("Your sona");
  await expect(page.getByText("SonaPin 1.0 · Open source release")).toBeVisible();
  await expect(page.getByRole("link", { name: /Get SonaPin/i }).first()).toHaveAttribute(
    "href",
    "https://github.com/MrDemonWolf/sonapin",
  );
  await expect(page.getByRole("button", { name: /Coming soon/i })).toHaveCount(0);
});

test("cycles the badge mood when tapped", async ({ page }) => {
  await page.goto("/");

  const badge = page.getByRole("button", { name: /Cyan paw badge/i });
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
  await expect(page.getByRole("link", { name: /Get SonaPin/i }).first()).toBeVisible();
  await expect(page.getByRole("button", { name: /Cyan paw badge/i })).toBeVisible();
  const overflow = await page.evaluate(() => ({
    width: document.documentElement.scrollWidth,
    elements: [...document.querySelectorAll("*")]
      .filter((element) => element.getBoundingClientRect().right > innerWidth + 1)
      .map((element) => element.className || element.tagName)
      .slice(0, 8),
  }));
  expect(overflow.width, JSON.stringify(overflow.elements)).toBeLessThanOrEqual(375);
});
