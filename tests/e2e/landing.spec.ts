import { expect, test } from "@playwright/test";

test("shows a pre-release landing page with disabled store actions", async ({ page }) => {
  await page.goto("/");

  await expect(page.getByRole("heading", { level: 1 })).toContainText("Your fursona");
  const storeButtons = page.getByRole("button", { name: /Coming soon/i });
  await expect(storeButtons).toHaveCount(2);
  await expect(storeButtons.nth(0)).toBeDisabled();
  await expect(storeButtons.nth(1)).toBeDisabled();
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
