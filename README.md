# Agentic Workstation Ubuntu

[![CI](https://github.com/TAKAMAgents/agentic-workstation-ubuntu/actions/workflows/ci.yml/badge.svg)](https://github.com/TAKAMAgents/agentic-workstation-ubuntu/actions/workflows/ci.yml)
[![Security](https://github.com/TAKAMAgents/agentic-workstation-ubuntu/actions/workflows/security.yml/badge.svg)](https://github.com/TAKAMAgents/agentic-workstation-ubuntu/actions/workflows/security.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Ubuntu](https://img.shields.io/badge/ubuntu-22.04%20%7C%2024.04-orange.svg)](tests)

Build repeatable Ubuntu machines for agentic software development.

This repository turns a fresh Ubuntu VM into a usable AI engineering workstation, runner, or server base with one entrypoint, explicit profiles, generated plans, install manifests, and health checks.

```text
fresh Ubuntu -> profile install -> workspace hydration -> manifest -> doctor
```

The DX goal is the same bar developers expect from strong platform products: copy-pasteable starts, predictable failure modes, inspectable plans, and clear recovery. Think Stripe-quality developer ergonomics as an inspiration point, not an affiliation.

## Start Here

Install the default `coding-agent` workstation:

```bash
git clone https://github.com/TAKAMAgents/agentic-workstation-ubuntu.git
cd agentic-workstation-ubuntu
./install-agentic-tools.sh
./scripts/doctor.sh --profile coding-agent
```

Install on a fresh machine that does not have Git yet:

```bash
curl -fsSL https://raw.githubusercontent.com/TAKAMAgents/agentic-workstation-ubuntu/main/scripts/bootstrap.sh | bash
```

Install a smaller profile:

```bash
curl -fsSL https://raw.githubusercontent.com/TAKAMAgents/agentic-workstation-ubuntu/main/scripts/bootstrap.sh \
  | bash -s -- --profile minimal
```

Inspect before changing the machine:

```bash
./install-agentic-tools.sh --profile coding-agent --plan
./install-agentic-tools.sh --profile coding-agent --json-plan
./install-agentic-tools.sh --profile coding-agent --dry-run
```

## When To Use This

Use this repo when you need:

- A fresh AI coding VM in minutes.
- A repeatable base image for future VMs.
- A headless agent runner with workspace hydration.
- A disposable security or supply-chain review box.
- An OpenClaw server host with Docker, OpenTelemetry, Neon, and Hetzner S3 helpers.
- A typed planner and validation path for CI, reviews, and image pipelines.

Do not use it as:

- A secrets manager.
- A personal dotfiles framework.
- A Kubernetes, Docker, Terraform, or cloud mega-bootstrapper by default.
- A replacement for devcontainers, Nix, or Packer. It is designed to sit beside them.

## System Requirements

Supported target:

- Ubuntu 22.04 or 24.04 on `amd64`.
- Root shell or a user with `sudo`.
- Network access to apt, npm, PyPI/uv, Go modules, Cargo, and vendor release endpoints.

Bootstrap requirement:

- Either `git`, or `curl`/`wget` plus `tar`.

Non-Ubuntu hosts can still use read-only planning through the Rust CLI and Nix flake. The mutating Bash installer intentionally supports Ubuntu only.

## Choose A Profile

| Need | Profile |
| --- | --- |
| Small reusable VM | `minimal` |
| Snapshot source image | `base-image` |
| Default AI development workstation | `coding-agent` |
| Larger human-operated development machine | `human-dev` |
| Lean autonomous runner | `agent-runner` |
| Full software-factory environment | `factory` |
| Security and supply-chain analysis | `security` |
| Ollama or local model runtime | `local-llm` |
| OpenClaw server host | `openclaw-server` |

Install a named profile:

```bash
./install-agentic-tools.sh --profile agent-runner
./install-agentic-tools.sh --profile factory
./install-agentic-tools.sh --profile openclaw-server
```

Resume after an interrupted run:

```bash
./install-agentic-tools.sh --profile factory --resume
```

Run or skip a specific module:

```bash
./install-agentic-tools.sh --only agents
./install-agentic-tools.sh --skip browser
```

## Reproducible Paths

There are three supported ways to reproduce a machine.

| Path | Best for | Command |
| --- | --- | --- |
| Bash installer | Real Ubuntu workstation setup | `./install-agentic-tools.sh --profile coding-agent` |
| Cloud-init | Unattended VM first boot | `./scripts/render-cloud-init.sh ...` |
| Nix flake | Repository CLI, checks, and dev shell | `nix run .#check` |

The Bash installer owns privileged system mutation: apt packages, shell configuration, service files, manifests, optional workspace hydration, and health checks.

The Rust CLI is read-only:

```bash
cargo run -- plan --profile coding-agent --json
cargo run -- verify-lockfile
```

The Nix flake builds the CLI and validation environment:

```bash
nix --extra-experimental-features 'nix-command flakes' build
nix --extra-experimental-features 'nix-command flakes' run .#check
nix --extra-experimental-features 'nix-command flakes' run .#e2e
nix --extra-experimental-features 'nix-command flakes' flake check
```

Bootstrap the Nix path on a fresh Ubuntu host:

```bash
curl -fsSL https://raw.githubusercontent.com/TAKAMAgents/agentic-workstation-ubuntu/main/scripts/bootstrap-nix.sh | bash
```

See [docs/nix.md](docs/nix.md) for flake apps, named dev shells, and the Nix e2e smoke workflow.

## Workspace Hydration

Clone a Git workspace during install:

```bash
WORKSPACE_REPO=git@github.com:hghalebi/project.git \
WORKSPACE_REF=main \
WORKSPACE_TARGET=/workspace/project \
./install-agentic-tools.sh --profile agent-runner
```

Copy an existing local workspace:

```bash
WORKSPACE_SOURCE=/path/to/workspace \
WORKSPACE_TARGET=/workspace/project \
./install-agentic-tools.sh --profile coding-agent
```

Hydration checks out the requested branch, tag, or ref. It pulls only when the checked-out ref has an upstream branch, so tag and commit-based runner builds do not fail because there is no branch to pull.

## VM Factory Flow

Build a reusable base image:

```bash
./install-agentic-tools.sh --profile base-image --resume
./scripts/prepare-snapshot.sh
```

Create a provider snapshot from that VM. Future VMs start from the snapshot and run only the profile-specific layer:

```bash
./install-agentic-tools.sh --profile agent-runner --resume
```

Render cloud-init for unattended first boot:

```bash
./scripts/render-cloud-init.sh \
  --user ubuntu \
  --ssh-key ~/.ssh/id_ed25519.pub \
  --profile agent-runner \
  --repo https://github.com/TAKAMAgents/agentic-workstation-ubuntu.git \
  --ref v0.1.1 \
  > cloud-init.agent-runner.yaml
```

Prefer a tag or commit SHA for `--ref`. `main` is convenient, but not reproducible.

Create a Hetzner VM and let cloud-init run the profile install:

```bash
HCLOUD_TOKEN=... ./scripts/agent-vm-new.sh --name repo-fix --profile agent-runner
```

Render and inspect the Hetzner command without `hcloud` installed:

```bash
./scripts/agent-vm-new.sh --dry-run --name repo-fix --ref v0.1.1
```

See [docs/vm-lifecycle.md](docs/vm-lifecycle.md) and [docs/hetzner-dx.md](docs/hetzner-dx.md).

## What Gets Installed

The default workstation layer includes:

| Area | Examples |
| --- | --- |
| Core shell | `git`, `gh`, `curl`, `wget`, `jq`, `rg`, `fd`, `fzf`, `tmux`, `zellij`, `direnv` |
| Build/runtime | compilers, `python3`, `pipx`, `node`, `npm`, `go`, Rust, `uv`, Nix |
| Code quality | `shellcheck`, `shfmt`, `bats`, `pre-commit` |
| Data and services | `sqlite3`, `psql`, `redis-cli`, `dig`, `nc` |
| Debugging | `lsof`, `strace`, `ltrace`, `hyperfine`, `ncdu`, `duf` |
| Version managers | `mise`, `aqua` |
| Git/YAML | `delta`, `yq`, `git-lfs` |
| Secret tooling | 1Password CLI `op` |
| Agent/model CLIs | `codex`, `claude`, `gemini`, `copilot`, `opencode`, `openclaw`, `openhands`, `aider`, `llm` |
| Cloud/database | `gcloud`, `hcloud`, `neonctl`, `clasp`, `gws`, `hc` |
| Browser/MCP | `playwright`, `@modelcontextprotocol/inspector` |

Optional layers add:

| Layer | Adds |
| --- | --- |
| `factory` | `task`, `just`, `pandoc`, `ffmpeg`, ImageMagick, Tesseract, `httpie`, `deepagents`, `dvc`, `hf` |
| `security` | `semgrep`, `snyk`, `gitleaks`, `syft`, `grype`, `cosign`, `trivy`, `hadolint` |
| `local-llm` | Ollama when `INCLUDE_LOCAL_MODEL_RUNTIME=1` |
| `openclaw-server` | `ufw`, `fail2ban`, `nginx`, Docker Engine, Rust server tools, OpenTelemetry, Neon, Hetzner S3 helpers, 1Password SSH helper |

See [docs/profiles.md](docs/profiles.md) for profile-level details.

## Configuration Controls

By default, the installer:

- Adds a marked PATH and `mise` activation block to `.profile` and `.bashrc`.
- Adds the same block to `.zshrc` when `.zshrc` already exists.
- Configures Git to use `delta` when no value is already set.
- Installs local pre-commit hooks when `.pre-commit-config.yaml` exists.

Disable local shell, Git, and hook configuration:

```bash
SKIP_AUTO_CONFIG=1 ./install-agentic-tools.sh
```

Skip Playwright browser binaries:

```bash
SKIP_BROWSER_TOOLS=1 ./install-agentic-tools.sh
```

Install factory tools:

```bash
INCLUDE_FACTORY_TOOLS=1 ./install-agentic-tools.sh
```

Install factory tools plus local model runtime:

```bash
INCLUDE_FACTORY_TOOLS=1 INCLUDE_LOCAL_MODEL_RUNTIME=1 ./install-agentic-tools.sh
```

## Health, Manifests, And Auth

Run health checks:

```bash
./scripts/doctor.sh --profile coding-agent
./scripts/doctor.sh --profile coding-agent --json
./scripts/doctor.sh --profile openclaw-server
```

Every install writes:

```text
/var/lib/agentic-workstation/manifest.json
```

The manifest records the selected profile, install time, host, OS, lockfile hash, and key tool versions.

Compare machines:

```bash
./scripts/diff-manifest.sh expected.json /var/lib/agentic-workstation/manifest.json
```

Check auth state without collecting secrets:

```bash
./scripts/auth-status.sh
./scripts/auth-status.sh --json
```

The installer does not automate login. Run only the auth commands for services you use:

```bash
gh auth login
copilot auth login
codex --login
claude auth login
gemini auth login
op account add
gcloud auth login --no-launch-browser
gcloud auth application-default login --no-launch-browser
hcloud context create default
neonctl auth
clasp login --no-localhost
gws auth setup
gws auth login
hc auth login
openclaw onboard --install-daemon
llm keys set openai
hf auth login
```

## Safety Model

- Installer runs are designed to be rerunnable.
- Auth flows stay out of the installer.
- Secrets are not collected, written, or printed.
- Remote shell installers are documented exceptions and audited.
- Tool versions are pinned where the installer controls package versions.
- Docker is installed by `openclaw-server`, not by default workstation profiles.
- Kubernetes, Terraform/OpenTofu, AWS CLI v2, and Azure CLI are documented but not installed by default.

Security and supply-chain references:

- [agentic-tools.lock.yaml](agentic-tools.lock.yaml): pinned versions and remote installer exceptions.
- [docs/remote-installers.md](docs/remote-installers.md): remote installer policy.
- [docs/threat-model.md](docs/threat-model.md): threat model and mitigations.
- [SECURITY.md](SECURITY.md): vulnerability reporting.

## Validate Changes

Run the local validation set:

```bash
bash -n install-agentic-tools.sh scripts/*.sh cloud/*.sh
shellcheck install-agentic-tools.sh scripts/*.sh cloud/*.sh
shfmt -i 2 -ci -d install-agentic-tools.sh scripts/*.sh cloud/*.sh
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all-targets --all-features
./scripts/verify-lockfile.sh
bats tests/unit
```

Run the Nix validation path:

```bash
nix --extra-experimental-features 'nix-command flakes' run .#check
nix --extra-experimental-features 'nix-command flakes' run .#e2e
```

Run Docker static smoke tests:

```bash
docker build -f tests/Dockerfile.ubuntu-24.04 .
docker build -f tests/Dockerfile.ubuntu-22.04 .
```

Opt into a full minimal install test inside Docker:

```bash
docker build --build-arg RUN_INSTALL=1 --build-arg PROFILE=minimal -f tests/Dockerfile.ubuntu-24.04 .
```

## Documentation

| Doc | Use it for |
| --- | --- |
| [commands.md](commands.md) | Install commands and source links |
| [docs/commands.md](docs/commands.md) | Short operator command list |
| [docs/profiles.md](docs/profiles.md) | Profile behavior |
| [docs/nix.md](docs/nix.md) | Nix bootstrap, apps, shells, and e2e workflow |
| [docs/vm-lifecycle.md](docs/vm-lifecycle.md) | Snapshots, cloud-init, and workspace hydration |
| [docs/hetzner-dx.md](docs/hetzner-dx.md) | Dev-team design notes for future Hetzner DX |
| [docs/auth.md](docs/auth.md) | Auth commands and status checks |
| [docs/architecture.md](docs/architecture.md) | Factory architecture |
| [docs/threat-model.md](docs/threat-model.md) | Security model |
| [docs/remote-installers.md](docs/remote-installers.md) | Remote installer audit policy |
| [docs/status.md](docs/status.md) | Reliability targets |
| [docs/agent-runner.md](docs/agent-runner.md) | Optional headless runner service |
| [docs/release.md](docs/release.md) | Release Please pipeline |
| [ROADMAP.md](ROADMAP.md) | Planned opt-in configuration |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Contribution workflow |
| [CHANGELOG.md](CHANGELOG.md) | Release history |

## License

MIT. See [LICENSE](LICENSE).
