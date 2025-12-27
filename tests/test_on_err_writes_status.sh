#!/bin/sh
# tests/test_on_err_writes_status.sh
# Verify that on_err writes tmp/last_failed.status when a script fails

set -eu
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
rm -f "$REPO_ROOT/tmp/last_failed.status" || true
mkdir -p "$REPO_ROOT/tmp" "$REPO_ROOT/logs"

# Create a small script that triggers on_err via EXIT trap
unit_tmp_dir="$(mktemp -d)"
cat > "$unit_tmp_dir/fail_script.sh" <<'SH'
#!/bin/sh
# fail_script.sh
. "$(cd "$(dirname "$0")/.." && pwd)/scripts/lib/error.sh"
# Install trap that will call on_err on exit
trap 'on_err' EXIT
# Simulate failure
false
SH
chmod +x "$unit_tmp_dir/fail_script.sh"

# Run it (it should exit non-zero but we capture exit)
if "$unit_tmp_dir/fail_script.sh" >/dev/null 2>&1; then
  echo "FAIL: test script unexpectedly succeeded"; exit 1
fi

# Check marker file
if [ -f "$REPO_ROOT/tmp/last_failed.status" ]; then
  echo "PASS: tmp/last_failed.status was written"
  # Clean up marker for idempotency
  rm -f "$REPO_ROOT/tmp/last_failed.status"
else
  echo "FAIL: tmp/last_failed.status missing"; exit 1
fi
rm -rf "$unit_tmp_dir"
exit 0