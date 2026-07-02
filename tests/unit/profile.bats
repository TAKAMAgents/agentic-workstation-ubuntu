#!/usr/bin/env bats

setup() {
  export STATE_DIR="${BATS_TEST_TMPDIR}/state"
  export MANIFEST_PATH="${STATE_DIR}/manifest.json"
}

@test "json plan is valid for coding-agent" {
  run bash -c 'bash ./install-agentic-tools.sh --profile coding-agent --json-plan | jq -e ".profile == \"coding-agent\""'
  [ "$status" -eq 0 ]
}

@test "openclaw-server profile enables server modules and dotfiles" {
  run bash -c 'bash ./install-agentic-tools.sh --profile openclaw-server --json-plan | jq -e ".profile == \"openclaw-server\" and (.modules[] | select(.name == \"docker\" and .enabled == true)) and (.modules[] | select(.name == \"opentelemetry\" and .enabled == true)) and (.modules[] | select(.name == \"dotfiles\" and .enabled == true))"'
  [ "$status" -eq 0 ]
}

@test "unknown profile fails" {
  run bash ./install-agentic-tools.sh --profile nope --dry-run
  [ "$status" -ne 0 ]
}

@test "bootstrap help works without network" {
  run bash ./scripts/bootstrap.sh --help
  [ "$status" -eq 0 ]
}

@test "bootstrap can run installer from a local archive without git clone" {
  archive_dir="${BATS_TEST_TMPDIR}/archive-source"
  archive_file="${BATS_TEST_TMPDIR}/agentic-workstation.tar.gz"
  target_dir="${BATS_TEST_TMPDIR}/bootstrap-target"

  mkdir -p "$archive_dir"
  cp -R install-agentic-tools.sh profiles agentic-tools.lock.yaml "$archive_dir/"
  tar -C "$archive_dir" -czf "$archive_file" .

  run bash ./scripts/bootstrap.sh \
    --archive-url "file://${archive_file}" \
    --dir "$target_dir" \
    --profile minimal \
    -- --json-plan

  [ "$status" -eq 0 ]
  [[ "$output" == *'"profile": "minimal"'* ]]
  [ -x "${target_dir}/install-agentic-tools.sh" ]
}

@test "agent vm help works without network" {
  run bash ./scripts/agent-vm-new.sh --help
  [ "$status" -eq 0 ]
}

@test "cloud-init renderer can inject workspace hydration" {
  run bash -c 'bash ./scripts/render-cloud-init.sh --ssh-key-value "ssh-ed25519 AAAATEST test@example" --ref v0.1.0 --workspace-repo git@github.com:org/project.git --workspace-ref main --workspace-target /workspace/project | grep -Eq "export WORKSPACE_REPO=.*git@github.com:org/project.git"'
  [ "$status" -eq 0 ]
  run bash -c 'bash ./scripts/render-cloud-init.sh --ssh-key-value "ssh-ed25519 AAAATEST test@example" --ref v0.1.0 --workspace-repo git@github.com:org/project.git --workspace-ref main --workspace-target /workspace/project | grep -Eq "export WORKSPACE_REF=.*main"'
  [ "$status" -eq 0 ]
  run bash -c 'bash ./scripts/render-cloud-init.sh --ssh-key-value "ssh-ed25519 AAAATEST test@example" --ref v0.1.0 --workspace-repo git@github.com:org/project.git --workspace-ref main --workspace-target /workspace/project | grep -Eq "export WORKSPACE_TARGET=.*/workspace/project"'
  [ "$status" -eq 0 ]
}

@test "only filter enables requested module and filters others" {
  run bash -c 'bash ./install-agentic-tools.sh --profile coding-agent --only agents --json-plan | jq -e ".modules[] | select(.name == \"agents\" and .enabled == true)"'
  [ "$status" -eq 0 ]
  run bash -c 'bash ./install-agentic-tools.sh --profile coding-agent --only agents --json-plan | jq -e ".modules[] | select(.name == \"base\" and .reason == \"only-filter\")"'
  [ "$status" -eq 0 ]
}

@test "skip filter disables requested module" {
  run bash -c 'bash ./install-agentic-tools.sh --profile coding-agent --skip agents --json-plan | jq -e ".modules[] | select(.name == \"agents\" and .enabled == false and .reason == \"skip-filter\")"'
  [ "$status" -eq 0 ]
}

@test "resume marker is reflected in plan" {
  mkdir -p "${STATE_DIR}/installed"
  touch "${STATE_DIR}/installed/base"
  run bash -c 'bash ./install-agentic-tools.sh --profile coding-agent --resume --json-plan | jq -e ".modules[] | select(.name == \"base\" and .reason == \"resume-marker\")"'
  [ "$status" -eq 0 ]
}

@test "doctor json is valid" {
  run bash -c 'bash ./scripts/doctor.sh --profile minimal --json | jq -e ".profile == \"minimal\""'
  [ "$status" -ne 2 ]
}
