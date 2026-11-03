#!/usr/bin/env bash
# Runs inside a sandbox. Offline checks always; pass "online" to add module fetch and vulnerability scan.
set -euo pipefail

[[ "$(id -u)" == 1000 && "$(id -un)" == agent ]] || { echo "FAIL: not the agent user"; exit 1; }
[[ "$(go env GOTOOLCHAIN)" == local ]] || { echo "FAIL: GOTOOLCHAIN is not local"; exit 1; }

go version
gopls version
golangci-lint --version
staticcheck -version
govulncheck -version
dlv version

work="$(mktemp -d)"
trap 'rm -rf "${work}"' EXIT
cd "${work}"
go mod init example.com/verify
cat > main.go <<'GO'
package main

import "fmt"

func add(a, b int) int { return a + b }

func main() { fmt.Println(add(2, 3)) }
GO
cat > main_test.go <<'GO'
package main

import "testing"

func TestAdd(t *testing.T) {
	if got := add(2, 3); got != 5 {
		t.Fatalf("add(2, 3) = %d, want 5", got)
	}
}
GO

(
  export GOPROXY=off GOSUMDB=off
  [[ "$(go run .)" == 5 ]]
  go test ./...
  golangci-lint run ./...
  staticcheck ./...
  gopls check main.go
)
echo "OFFLINE PASSED"

[[ "${1:-}" == online ]] || exit 0

cat > dep.go <<'GO'
package main

import _ "golang.org/x/sync/errgroup"
GO
go mod tidy
go test ./...
govulncheck ./...
echo "ONLINE PASSED"
