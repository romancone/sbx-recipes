# syntax=docker/dockerfile:1
ARG BASE

# Runs on the build machine and cross-compiles, so arm64 needs no emulation here.
FROM --platform=$BUILDPLATFORM ${BASE} AS tools
ARG TARGETARCH
ARG GOPLS_VERSION
ARG STATICCHECK_VERSION
ARG GOVULNCHECK_VERSION
ARG DELVE_VERSION
ARG GOLANGCI_LINT_VERSION
USER root
ENV PATH=/usr/local/go/bin:$PATH GOPATH=/tmp/go GOCACHE=/tmp/go-cache GOTOOLCHAIN=local \
    CGO_ENABLED=0 GOOS=linux GOARCH=$TARGETARCH
RUN go install -trimpath -ldflags="-s -w" "golang.org/x/tools/gopls@${GOPLS_VERSION}" \
 && go install -trimpath -ldflags="-s -w" "honnef.co/go/tools/cmd/staticcheck@${STATICCHECK_VERSION}" \
 && go install -trimpath -ldflags="-s -w" "golang.org/x/vuln/cmd/govulncheck@${GOVULNCHECK_VERSION}" \
 && go install -trimpath -ldflags="-s -w" "github.com/go-delve/delve/cmd/dlv@${DELVE_VERSION}" \
 && mkdir /out \
 && find /tmp/go/bin -type f -exec cp {} /out/ \;
RUN set -e; \
    release="golangci-lint-${GOLANGCI_LINT_VERSION}"; \
    tarball="${release}-linux-${TARGETARCH}.tar.gz"; \
    url="https://github.com/golangci/golangci-lint/releases/download/v${GOLANGCI_LINT_VERSION}"; \
    cd /tmp; \
    curl -fsSLO "${url}/${tarball}"; \
    curl -fsSLO "${url}/${release}-checksums.txt"; \
    grep " ${tarball}\$" "${release}-checksums.txt" | sha256sum -c -; \
    tar -xzf "${tarball}"; \
    cp "${release}-linux-${TARGETARCH}/golangci-lint" /out/

# Entrypoint, command and flavor label stay the vendor base's.
FROM ${BASE}
USER root
COPY --from=tools /out/ /usr/local/bin/
# The agent's non-interactive shells read this file, not .bashrc.
RUN printf '%s\n' 'export GOTOOLCHAIN=local' 'export PATH="$HOME/go/bin:$PATH"' >> /etc/sandbox-persistent.sh
USER agent
