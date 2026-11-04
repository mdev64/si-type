// Mirrors the composition logic in Sources/InputController.swift, applied to a
// whole string at once: keep extending the key sequence while it is still in the
// keymap, otherwise commit the current value and start a new sequence.
// "?" at the start of a word starts inline-English mode in both layouts;
// "??" or "? " types a plain question mark.
const TRIGGER = "?";

function transliterate(input, keymap) {
  const lookup = (key) => keymap[key];
  const strip = (value) => value.replace(/#/g, "");
  let out = "";
  let buffer = "";
  let english = "off"; // "off" | "armed" | "active"
  let atWordStart = true;

  const flush = () => {
    if (buffer) {
      out += strip(lookup(buffer) ?? buffer);
      buffer = "";
    }
  };

  const compose = (ch) => {
    const extended = buffer + ch;
    if (buffer && lookup(extended) !== undefined) {
      buffer = extended;
      return;
    }
    flush();
    const entry = lookup(ch);
    if (entry === undefined) {
      out += ch;
    } else if (entry.endsWith("#")) {
      out += strip(entry);
    } else {
      buffer = ch;
    }
  };

  for (const ch of input) {
    const isWhitespace = /\s/.test(ch);
    const wasWordStart = atWordStart;
    atWordStart = isWhitespace;

    if (english === "active") {
      if (isWhitespace) english = "off";
      out += ch;
      continue;
    }
    if (english === "armed") {
      english = "off";
      if (isWhitespace) { compose(TRIGGER); compose(ch); continue; }
      if (ch === TRIGGER) { compose(TRIGGER); continue; }
      english = "active";
      out += ch;
      continue;
    }
    // "?" starts English only at the start of a word; elsewhere it is a question mark.
    if (ch === TRIGGER && wasWordStart) {
      flush();
      english = "armed";
      continue;
    }
    compose(ch);
  }

  if (english === "armed") compose(TRIGGER);
  flush();
  return out;
}

// Live demo
const keymaps = window.KEYMAPS || { phonetic: {}, wijesekara: {} };
const input = document.getElementById("demo-input");
const output = document.getElementById("demo-output");
const hint = document.getElementById("layout-hint");
const examples = document.getElementById("demo-examples");
const keyboard = document.getElementById("keyboard");

const layouts = {
  phonetic: {
    text: "mama ?SiType bhaawithaa karanawaa",
    placeholder: "Type Singlish, e.g. ammaa",
    hint: "Type Sinhala with English letters. Start a word with ? to keep it in English.",
    examples: ["aayuboowan", "ammaa", "shrii laxkaawa", "mama ?hello yanawaa", "sthuthiyi"],
  },
  wijesekara: {
    text: "uu isxy, ,shkjd",
    placeholder: "Type on a US keyboard, e.g. wuaud",
    hint: "Keys are typed by position on a US keyboard. Use the keyboard below if you don't know the layout yet. Start a word with ? to keep it in English.",
    examples: ["wuaud", "wdhqfndajka", "Y`S ,xldj", "ia;q;shs", "uu ?SiType ,shkjd"],
  },
};

let layout = "phonetic";
const drafts = { phonetic: layouts.phonetic.text, wijesekara: layouts.wijesekara.text };

function render() {
  output.textContent = transliterate(input.value, keymaps[layout]);
}

function setLayout(name) {
  drafts[layout] = input.value;
  layout = name;
  const config = layouts[name];
  input.value = drafts[name];
  input.placeholder = config.placeholder;
  hint.textContent = config.hint;
  keyboard.hidden = name !== "wijesekara";

  examples.replaceChildren(...config.examples.map((text) => {
    const chip = document.createElement("button");
    chip.className = "chip";
    chip.innerHTML = '<span class="chip-keys"></span><span class="chip-out si"></span>';
    chip.querySelector(".chip-keys").textContent = text;
    chip.querySelector(".chip-out").textContent = transliterate(text, keymaps[name]);
    chip.addEventListener("click", () => {
      input.value = text;
      render();
      input.focus();
    });
    return chip;
  }));

  document.querySelectorAll(".layout-switch .tab").forEach((tab) => {
    const active = tab.dataset.layout === name;
    tab.classList.toggle("active", active);
    tab.setAttribute("aria-selected", String(active));
  });
  render();
}

input.addEventListener("input", render);
document.querySelectorAll(".layout-switch .tab").forEach((tab) => {
  tab.addEventListener("click", () => setLayout(tab.dataset.layout));
});

// On-screen Wijesekara keyboard: each key shows its Sinhala output, Shift shows the upper row.
const keyRows = [
  "qwertyuiop[]\\",
  "asdfghjkl;'",
  "zxcvbnm,./",
];
const shifted = { "[": "{", "]": "}", "\\": "|", ";": ":", "'": "\"", ",": "<", ".": ">", "/": "?" };
let shift = false;

// Shows a keymap value on a keycap: drops the commit marker and zero-width
// characters, and puts vowel signs on a dotted circle so they are visible.
function keyLabel(key) {
  const value = keymaps.wijesekara[key];
  if (value === undefined) return "";
  const clean = value.replace(/[#​‍]/g, "");
  return /^\p{M}/u.test(clean) ? "◌" + clean : clean;
}

function typeKey(text) {
  const start = input.selectionStart ?? input.value.length;
  const end = input.selectionEnd ?? input.value.length;
  input.setRangeText(text, start, end, "end");
  render();
}

function buildKeyboard() {
  const rows = keyRows.map((row) => {
    const rowEl = document.createElement("div");
    rowEl.className = "kb-row";
    for (const base of row) {
      const upper = shifted[base] ?? base.toUpperCase();
      const button = document.createElement("button");
      button.className = "kb-key";
      button.type = "button";
      button.dataset.base = base;
      button.dataset.upper = upper;
      button.innerHTML = '<span class="kb-si si"></span><span class="kb-latin"></span>';
      rowEl.appendChild(button);
    }
    return rowEl;
  });

  const bottom = document.createElement("div");
  bottom.className = "kb-row";
  bottom.innerHTML =
    '<button type="button" class="kb-key kb-wide" data-action="shift" aria-pressed="false">Shift</button>' +
    '<button type="button" class="kb-key kb-space" data-action="space">Space</button>' +
    '<button type="button" class="kb-key kb-wide" data-action="backspace" aria-label="Backspace">⌫</button>';
  keyboard.replaceChildren(...rows, bottom);

  // Keep focus in the textarea so the caret position is kept.
  keyboard.addEventListener("mousedown", (event) => event.preventDefault());
  keyboard.addEventListener("click", (event) => {
    const key = event.target.closest(".kb-key");
    if (!key) return;
    const action = key.dataset.action;
    if (action === "shift") {
      shift = !shift;
      updateKeyboard();
      return;
    }
    if (action === "space") typeKey(" ");
    else if (action === "backspace") {
      const start = input.selectionStart;
      const end = input.selectionEnd;
      if (start !== end) input.setRangeText("", start, end, "end");
      else if (start > 0) input.setRangeText("", start - 1, start, "end");
      render();
    } else {
      typeKey(shift ? key.dataset.upper : key.dataset.base);
      if (shift) {
        shift = false;
        updateKeyboard();
      }
    }
  });
  updateKeyboard();
}

function updateKeyboard() {
  keyboard.classList.toggle("shifted", shift);
  keyboard.querySelector('[data-action="shift"]').setAttribute("aria-pressed", String(shift));
  keyboard.querySelectorAll(".kb-key[data-base]").forEach((key) => {
    const char = shift ? key.dataset.upper : key.dataset.base;
    const label = keyLabel(char);
    key.querySelector(".kb-si").textContent = label;
    key.querySelector(".kb-latin").textContent = char;
    key.setAttribute("aria-label", label ? `${char}: ${label}` : char);
  });
}

buildKeyboard();
setLayout("phonetic");

// Copy buttons
document.querySelectorAll(".copy").forEach((button) => {
  button.addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText(button.dataset.copy);
      button.textContent = "Copied";
    } catch {
      button.textContent = "Press ⌘C";
    }
    setTimeout(() => { button.textContent = "Copy"; }, 1500);
  });
});

// Install tabs
const tabs = document.querySelectorAll("#install .tab");
tabs.forEach((tab) => {
  tab.addEventListener("click", () => {
    tabs.forEach((t) => {
      const active = t === tab;
      t.classList.toggle("active", active);
      t.setAttribute("aria-selected", String(active));
      document.getElementById("tab-" + t.dataset.tab).classList.toggle("active", active);
    });
  });
});

// Cheat sheet, rendered from the keymap so it always matches the app.
const cheatsheet = {
  vowels: ["a", "aa", "A", "Aa", "i", "ii", "u", "uu", "e", "ee", "ai", "o", "oo", "au", "x", "H"],
  consonants: [
    "k", "K", "g", "G", "ch", "chh", "j", "J", "t", "T", "d", "D", "N",
    "th", "thh", "dh", "dhh", "n", "p", "P", "b", "bh", "m", "B",
    "y", "r", "l", "v", "w", "sh", "Sh", "s", "h", "L", "f",
  ],
  combos: ["kra", "kya", "zg", "zd", "zdh", "zk", "zh", "shrii"],
};

for (const [id, keys] of Object.entries(cheatsheet)) {
  const container = document.getElementById(id);
  for (const key of keys) {
    const value = transliterate(key, keymaps.phonetic);
    if (!value || value === key) continue;
    const cell = document.createElement("div");
    cell.className = "key";
    cell.innerHTML = '<span class="si"></span><code></code>';
    cell.querySelector(".si").textContent = value;
    cell.querySelector("code").textContent = key;
    container.appendChild(cell);
  }
}
