# sbx-recipes

Docker Sandbox (`sbx`) template recipes: an agent's base image plus language tooling, multi-arch, published to `ghcr.io/romancone/sbx`.

| Recipe | Adds |
|---|---|
| `go` | `gopls`, `staticcheck`, `govulncheck`, `dlv`, `golangci-lint`, `GOTOOLCHAIN=local`, on the base's Go |

Images are tagged `<recipe>-<vendor>-v<N>`, with a moving `<recipe>-<vendor>` tag. `vendors` pins each base by digest; `<recipe>/versions` pins the tools.

## Host setup — Ubuntu 24.04 or later, x86_64 or aarch64

The host needs KVM; a cloud VM without nested virtualisation has none.

```bash
ls -l /dev/kvm
```

Install `sbx` and give your user KVM access:

```bash
curl -fsSL https://get.docker.com | sudo REPO_ONLY=1 sh
```

```bash
sudo apt-get install -y docker-sbx
```

```bash
sudo usermod -aG kvm "$USER"
```

Log out and back in, then confirm the group and the version. `sbx` state — login, images, secrets, policy — is per Unix user, so run everything from here on as the user who will run the sandboxes.

```bash
id -nG | grep -w kvm && sbx version
```

Sign in to Docker (device code, once per user) and set the network policy — registries and `github.com` open, everything else denied:

```bash
sbx login
```

On a host with no keyring, `sbx login` warns that the secret is stored on disk with file permissions; that is expected.

```bash
sbx policy init balanced
```

Allow the hosts a Go job needs:

```bash
sbx policy allow network "proxy.golang.org:443,sum.golang.org:443,storage.googleapis.com:443,vuln.go.dev:443"
```

## Use

Pin a release by digest. `sbx` needs the registry in the reference.

```bash
mkdir -p ~/sbx-verify && sbx create --name go-verify -t ghcr.io/romancone/sbx:go-claude-code-v1@sha256:a031ae0b5e84a1e0281a7febfe619480455becf9da8dd35afa9cd2395835a1c1 claude ~/sbx-verify
```

## Verify

From a clone of this repository, run the checks inside the sandbox, then remove it:

```bash
git clone https://github.com/romancone/sbx-recipes.git ~/sbx-recipes
```

```bash
sbx exec go-verify bash -c "$(cat ~/sbx-recipes/go/verify.sh)" verify online
```

```bash
sbx rm --force go-verify
```

`OFFLINE PASSED` then `ONLINE PASSED` is a pass. A failure after `OFFLINE PASSED` is the network policy: re-check the allow rule above.

## Release

Push a tag `<recipe>-<vendor>-v<N>`; `.github/workflows/publish.yml` builds `linux/amd64` and `linux/arm64` and pushes both tags. Recipe names carry no hyphen.
