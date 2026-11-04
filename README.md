# SiType

A Sinhala input method for macOS, written in Swift with InputMethodKit.

It has two layouts:

- **SiType - Phonetic**: type Sinhala using English letters (Singlish), e.g. `ammaa` → අම්මා.
- **SiType - Wijesekara**: the standard SLS 1134 Wijesekara typewriter layout.

## Features

- Phonetic typing with live composition: the Sinhala text you're building is underlined until it's complete.
- Wijesekara layout for touch typists.
- **Inline English with `?`** (both layouts): start a word with `?`, and that word stays in English until you press space.
  `?` only does this at the start of a word, so a question mark at the end of a word (`kohomadha?`) works as usual.

  | You type                      | You get                       |
  | ----------------------------- | ----------------------------- |
  | `mama ?hello yanawaa`         | මම hello යනවා                 |
  | `?user@mail.com hari`         | user@mail.com හරි             |
  | `kohomadha?`                  | කොහොමද?                       |
  | `?` + space                   | `? ` (a normal question mark) |
  | `??`                          | `?`                           |
  | `?` then Backspace            | cancels                       |

  English mode also ends on Return or Tab.

## Requirements

macOS 11 (Big Sur) or later. Homebrew releases are universal (Apple Silicon and Intel).

## Installation

### Option 1: Homebrew (recommended)

```bash
brew install --cask mdev64/tap/si-type
```

Then [enable it](#enable-sitype).

To update or remove:

```bash
brew upgrade --cask si-type
```

```bash
brew uninstall --cask si-type
```

### Option 2: Download a release

1. Download `SiType-vX.Y.Z.dmg` (or `SiType-vX.Y.Z.zip`) from the [Releases page](https://github.com/mdev64/si-type/releases) and open it.
2. Move `SiType.app` into `~/Library/Input Methods/` (in Finder: Go → Go to Folder… → `~/Library/Input Methods`).
3. The app is not notarized, so clear the download quarantine and register it:

   ```bash
   xattr -dr com.apple.quarantine ~/Library/Input\ Methods/SiType.app
   ```

   ```bash
   ~/Library/Input\ Methods/SiType.app/Contents/MacOS/SiType --register
   ```

4. [Enable it](#enable-sitype).

### Option 3: Build from source

Needs the Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/mdev64/si-type.git
```

```bash
cd si-type && ./install.sh
```

`install.sh` builds the app for your Mac's architecture, copies it to `~/Library/Input Methods/` and registers it. Run `./uninstall.sh` to remove it.

### Enable SiType

1. Open **System Settings → Keyboard → Input Sources → Edit…**
2. Click **+**, choose **Sinhala**, then add **SiType - Phonetic** and/or **SiType - Wijesekara**.
3. Switch input sources from the menu bar, or with Control-Space / the Globe (🌐) key.

If SiType doesn't show up in the list, log out and back in.

## Phonetic cheat sheet

| Vowels | | Consonants | | Consonants | |
|---|---|---|---|---|---|
| `a` අ | `aa` ආ | `k` ක් | `g` ග් | `th` ත් | `dh` ද් |
| `A` ඇ | `Aa` ඈ | `ch` ච් | `j` ජ් | `t` ට් | `d` ඩ් |
| `i` ඉ | `ii` ඊ | `n` න් | `N` ණ් | `p` ප් | `b` බ් |
| `u` උ | `uu` ඌ | `m` ම් | `y` ය් | `r` ර් | `l` ල් |
| `e` එ | `ee` ඒ | `v`/`w` ව් | `s` ස් | `sh` ශ් | `Sh` ෂ් |
| `o` ඔ | `oo` ඕ | `h` හ් | `L` ළ් | `f` ෆ් | `x` ං |

Add a vowel after a consonant to get the vowel sign: `ka` ක, `kaa` කා, `ki` කි, `ku` කු, `ke` කෙ, `ko` කො.
Combinations: `kra` ක්‍ර (rakaransaya), `kya` ක්‍ය (yansaya), `zg` ඟ, `zd` ඬ, `zdh` ඳ, `zk` ඤ.
For the full mapping, see [`Resources/phonetic.strings`](Resources/phonetic.strings).
