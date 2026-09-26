const root = document.documentElement;
const themeKey = "sonapin-theme";
let storedTheme: string | null = null;
try {
  storedTheme = localStorage.getItem(themeKey);
} catch {
  // System preference still works when browser storage is unavailable.
}
let theme: "light" | "dark" = storedTheme === "light" || storedTheme === "dark"
  ? storedTheme
  : matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
const appScreen = document.querySelector<HTMLImageElement>("#app-screen");
const screenCaption = document.querySelector<HTMLElement>("#screen-caption");
const screenButtons = [...document.querySelectorAll<HTMLButtonElement>(".screen-picker [data-image]")];
const rotationToggle = document.querySelector<HTMLButtonElement>("#screen-rotation-toggle");
const reducedMotion = matchMedia("(prefers-reduced-motion: reduce)");
let rotationPaused = reducedMotion.matches;
let chooserHovered = false;
let pointerPausedState: boolean | undefined;
let rotationTimer: number | undefined;

function showSelectedScreen() {
  if (!appScreen || !screenCaption) return;
  const selected = document.querySelector<HTMLButtonElement>('.screen-picker button[aria-pressed="true"]');
  const image = selected?.dataset.image;
  const alt = selected?.dataset.alt;
  if (!selected || !image || !alt) return;

  const darkImage = theme === "dark" ? selected.dataset.imageDark : undefined;
  appScreen.src = darkImage ?? image;
  appScreen.alt = darkImage
    ? selected.dataset.altDark ?? alt
    : alt;

  const name = selected.textContent?.trim() ?? "Selected screen";
  screenCaption.textContent = darkImage
    ? `Actual dark-mode capture · ${name}`
    : `Actual light-mode capture · ${name}`;
}

function applyTheme() {
  root.dataset.theme = theme;
  const metaThemeColor = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
  if (metaThemeColor) metaThemeColor.content = theme === "light" ? "#f4f7fc" : "#091533";

  for (const button of document.querySelectorAll<HTMLButtonElement>(".theme-toggle")) {
    const nextTheme = theme === "light" ? "dark" : "light";
    button.setAttribute("aria-label", `Switch to ${nextTheme} appearance`);
    button.title = `Switch to ${nextTheme} appearance`;
    button.textContent = nextTheme === "light" ? "☀" : "☾";
  }
  showSelectedScreen();
}

function stopRotation() {
  if (rotationTimer !== undefined) window.clearInterval(rotationTimer);
  rotationTimer = undefined;
}

function advanceScreen() {
  const current = screenButtons.findIndex((button) => button.getAttribute("aria-pressed") === "true");
  screenButtons[(current + 1) % screenButtons.length]?.click();
}

function startRotation(force = false) {
  stopRotation();
  if (!rotationPaused && (force || !chooserHovered) && !document.hidden && screenButtons.length > 1) {
    rotationTimer = window.setInterval(advanceScreen, 6000);
  }
}

function updateRotation(force = false) {
  stopRotation();
  if (!rotationToggle) return;

  rotationToggle.textContent = rotationPaused ? "▶" : "⏸";
  rotationToggle.setAttribute("aria-label", `${rotationPaused ? "Play" : "Pause"} screen rotation`);
  startRotation(force);
}

applyTheme();

for (const button of document.querySelectorAll<HTMLButtonElement>(".theme-toggle")) {
  button.addEventListener("click", () => {
    theme = theme === "light" ? "dark" : "light";
    try {
      localStorage.setItem(themeKey, theme);
    } catch {
      // The current page still changes theme when browser storage is unavailable.
    }
    applyTheme();
    button.title = `Switch to ${theme === "light" ? "dark" : "light"} appearance`;
  });
}

document.addEventListener("click", (event) => {
  if (!(event.target instanceof Element)) return;
  event.target.closest(".mobile-menu__panel a")?.closest("details")?.removeAttribute("open");
});

for (const button of screenButtons) {
  button.addEventListener("click", () => {
    for (const option of document.querySelectorAll<HTMLButtonElement>(".screen-picker button")) {
      option.setAttribute("aria-pressed", String(option === button));
    }
    showSelectedScreen();
    if (rotationTimer !== undefined) startRotation();
  });
}

rotationToggle?.addEventListener("pointerdown", () => {
  pointerPausedState = rotationPaused;
});
rotationToggle?.addEventListener("click", (event) => {
  const wasPaused = event.detail > 0 ? pointerPausedState ?? rotationPaused : rotationPaused;
  rotationPaused = !wasPaused;
  pointerPausedState = undefined;
  updateRotation(!rotationPaused);
});

const screenChooser = document.querySelector<HTMLElement>(".screen-chooser");
screenChooser?.addEventListener("pointerenter", () => {
  chooserHovered = true;
  stopRotation();
});
screenChooser?.addEventListener("pointerleave", () => {
  chooserHovered = false;
  if (!screenChooser.contains(document.activeElement)) startRotation();
});
screenChooser?.addEventListener("focusin", () => {
  rotationPaused = true;
  updateRotation();
});
document.addEventListener("visibilitychange", () => {
  if (document.hidden) {
    stopRotation();
  } else {
    updateRotation();
  }
});
reducedMotion.addEventListener("change", (event) => {
  if (event.matches) {
    rotationPaused = true;
    updateRotation();
  }
});

updateRotation();
