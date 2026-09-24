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
    : theme === "dark" ? `${alt} Captured in light appearance; no dark capture is available for this screen.` : alt;

  const name = selected.textContent?.trim() ?? "Selected screen";
  screenCaption.textContent = darkImage
    ? `Actual dark-mode capture · ${name} · No QR code is configured in this simulator.`
    : theme === "dark"
      ? `Actual light-mode capture · ${name} · No dark capture is available for this screen.`
      : `Actual SonaPin screen · ${name}`;
}

function applyTheme() {
  root.dataset.theme = theme;
  const metaThemeColor = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
  if (metaThemeColor) metaThemeColor.content = theme === "light" ? "#f4f7fc" : "#091533";

  for (const button of document.querySelectorAll<HTMLButtonElement>(".theme-toggle")) {
    const nextTheme = theme === "light" ? "dark" : "light";
    button.setAttribute("aria-label", `Switch to ${nextTheme} appearance`);
    button.textContent = nextTheme === "light" ? "☼ Light" : "☾ Dark";
  }
  showSelectedScreen();
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
  });
}

for (const button of document.querySelectorAll<HTMLButtonElement>(".screen-picker button")) {
  button.addEventListener("click", () => {
    for (const option of document.querySelectorAll<HTMLButtonElement>(".screen-picker button")) {
      option.setAttribute("aria-pressed", String(option === button));
    }
    showSelectedScreen();
  });
}
