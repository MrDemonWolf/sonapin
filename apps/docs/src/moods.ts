const moods = [
  { key: "bright", label: "Bright" },
  { key: "playful", label: "Playful" },
  { key: "cozy", label: "Cozy" },
  { key: "hyped", label: "Hyped" },
] as const;

const badge = document.querySelector<HTMLButtonElement>("#mood-badge");
const label = document.querySelector<HTMLElement>("#mood-label");

if (badge && label) {
  let index = 0;
  badge.addEventListener("click", () => {
    index = (index + 1) % moods.length;
    const mood = moods[index];
    badge.dataset.mood = mood.key;
    label.textContent = mood.label;
    badge.setAttribute("aria-label", `Cyan paw badge, ${mood.label} mood. Tap to react.`);
  });
}
