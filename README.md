# sbx-recipes

Docker Sandbox (`sbx`) template recipes: an agent's base image plus language tooling, multi-arch, published to `ghcr.io/romancone/sbx`.

| Recipe | Adds |
|---|---|
| `go` | `gopls`, `staticcheck`, `govulncheck`, `dlv`, `golangci-lint`, `GOTOOLCHAIN=local`, on the base's Go |

Images are tagged `<recipe>-<vendor>-v<N>`, with a moving `<recipe>-<vendor>` tag. `vendors` pins each base by digest; `<recipe>/versions` pins the tools.

## Use

Pin the digest of a release. `sbx` needs the registry in the reference.

```bash
sbx create -t ghcr.io/romancone/sbx:go-claude-code-v1@sha256:<digest> claude <workspace>
```

A Go job needs these hosts allowed:

```bash
sbx policy allow network "proxy.golang.org:443,sum.golang.org:443,storage.googleapis.com:443,vuln.go.dev:443"
```

## Verify

```bash
sbx exec <sandbox> bash -c "$(cat go/verify.sh)" verify online
```

## Release

Push a tag `<recipe>-<vendor>-v<N>`; `.github/workflows/publish.yml` builds `linux/amd64` and `linux/arm64` and pushes both tags. Recipe names carry no hyphen.
