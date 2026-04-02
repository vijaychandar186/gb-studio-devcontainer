# GB Studio — GitHub Codespaces Devcontainer

Run [GB Studio](https://www.gbstudio.dev/) entirely in the browser via GitHub Codespaces. No local install required — the full GB Studio GUI is streamed to your browser through a virtual desktop over noVNC.

---

## How it works

| Layer | Tool | Purpose |
|---|---|---|
| Container | Ubuntu 24.04 Noble | Base devcontainer image |
| Virtual display | Xvfb | Headless X11 display server |
| Window manager | Openbox | Minimal desktop environment |
| VNC server | x11vnc | Captures the virtual display |
| Browser client | noVNC + websockify | Streams VNC to the browser over WebSocket |
| App | GB Studio | Game Boy development IDE |

---

## Getting started

### 1. Open in Codespaces

Click **Code → Codespaces → Create codespace on main** from the GitHub repo page.

The `onCreateCommand` in `devcontainer.json` will automatically run `setup.sh`, which installs all dependencies and downloads the latest GB Studio `.deb` from GitHub releases.

### 2. Start the desktop

Once the codespace is ready, open the terminal and run:

```bash
bash start.sh
```

The script will print the exact URL to open, e.g.:

```
  Open: https://<codespace-name>-6080.app.github.dev/vnc_lite.html?autoconnect=1&password=password
```

### 3. Open GB Studio

Navigate to the printed URL in your browser. GB Studio will be running on the virtual desktop. The VNC password is `password`.

### 4. Save your project to the workspace

When creating a new project in GB Studio, set the save location to:

```
/workspaces/gb-studio-devcontainer/
```

The noVNC session runs inside the same container, so files saved there appear instantly in VS Code and are tracked by git. The CI pipeline will automatically detect your `.gbsproj` file.

---

## File reference

### `.devcontainer/devcontainer.json`

```jsonc
{
  "name": "GB Studio",
  "image": "mcr.microsoft.com/devcontainers/base:noble",
  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  },
  "forwardPorts": [6080],
  "portsAttributes": {
    "6080": {
      "label": "GB Studio (noVNC)",
      "onAutoForward": "openBrowser"
    }
  },
  "onCreateCommand": "bash .devcontainer/setup.sh",
  "remoteUser": "vscode"
}
```

Port `6080` is forwarded automatically and opens in the browser when the codespace starts.

---

### `.devcontainer/setup.sh`

Runs once at container creation. It:

1. Updates the apt index
2. Installs all runtime dependencies (Xvfb, x11vnc, noVNC, Openbox, GB Studio's Electron deps)
3. Fetches the latest `gb-studio-linux-debian.deb` from the [GB Studio GitHub releases](https://github.com/chrismaltby/gb-studio/releases) API
4. Installs it via `dpkg`

> **Ubuntu 24.04 note:** This image uses `libasound2t64` (not `libasound2`) due to the 64-bit `time_t` transition in Noble.

---

### `start.sh`

Run manually each time you want to launch GB Studio. It:

1. Kills any leftover processes from a previous run
2. Auto-detects the noVNC web root and correct entry-point HTML file
3. Starts Xvfb → Openbox → x11vnc → websockify/noVNC → GB Studio
4. Prints the full browser URL with auto-connect and password pre-filled

---

## Troubleshooting

**404 on the noVNC URL**

The script auto-detects the entry point (`vnc.html` or `vnc_lite.html`). Use the exact URL printed by `start.sh` rather than constructing it manually.

**Black screen in the browser**

Openbox or GB Studio may still be starting up. Wait 5–10 seconds and refresh. You can also check GB Studio's own log:

```bash
tail -f /tmp/gb-studio.log
```

**Port 6080 not forwarding**

In VS Code's Ports panel (or the Codespaces UI), confirm port `6080` is listed and set to **Public** or **Private** visibility as needed.

**Restarting after the session goes idle**

Codespaces may suspend the virtual processes. Simply re-run `start.sh` to bring everything back up — it cleans up stale locks automatically.

---

## CI/CD pipeline

This repo includes a GitHub Actions pipeline for headless GB Studio builds, adapted from [gb-studio-ci-example](https://github.com/Pomdap/gb-studio-ci-example) by [Pomdap](https://github.com/Pomdap) (CC0 1.0 — see `LICENSE`).

Builds run inside a Docker image built from the `Dockerfile` in this repo (based on [gb-studio-ci](https://github.com/Pomdap/gb-studio-ci) by Pomdap), pushed to GitHub Container Registry (`ghcr.io`). This means builds always use the exact GB Studio version your project was created with, with no dependency on external Docker Hub images.

### Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `build-ci-image.yml` | Push to `Dockerfile`, or manual | Builds the GB Studio CLI Docker image and pushes it to `ghcr.io` |
| `ci-main-branch.yml` | Push / PR to `main` | Builds all targets, uploads as artifacts |
| `ci-github-release.yml` | `v*` tag push | Builds all targets, creates a GitHub Release |
| `ci-itchio-release.yml` | `v*` tag push | Builds all targets, deploys to itch.io |

Targets: `rom` (`.gb`/`.gbc`), `pocket`, `web`. Edit `TARGET_LIST` in the workflow to change which targets are built.

### First-time setup

No manual setup required. `ci-main-branch.yml` automatically builds the CI Docker image as part of the pipeline before building your targets — so the first push will just work.

### Configuration

For the itch.io workflow, set the following in your GitHub repo (**Settings → Secrets and variables**):

| Name | Type | Description |
|---|---|---|
| `ITCH_IO_USERNAME` | Variable | Your itch.io username |
| `ITCH_IO_GAME` | Variable | Your itch.io game slug |
| `ITCH_IO_API_KEY` | Secret | Your itch.io API key ([generate here](https://itch.io/user/settings/api-keys)) |

> If you don't publish to itch.io, delete `ci-itchio-release.yml` — the other workflows need no configuration.

### Deploying to itch.io

Push a version tag to trigger the itch.io release workflow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The workflow will build all targets and deploy them to your itch.io game page. The tag name is used as the version shown on itch.io.

---

## Acknowledgements

- [GB Studio](https://github.com/chrismaltby/gb-studio) by Chris Maltby — MIT licensed
- [noVNC](https://github.com/novnc/noVNC) — browser-based VNC client
- [GitHub Codespaces](https://github.com/features/codespaces)
- [gb-studio-ci-example](https://github.com/Pomdap/gb-studio-ci-example) by Pomdap — CI/CD pipeline workflows, CC0 1.0
- [gb-studio-ci](https://github.com/Pomdap/gb-studio-ci) by Pomdap — GB Studio CLI Docker image, CC0 1.0