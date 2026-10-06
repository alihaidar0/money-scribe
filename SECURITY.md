# Security Policy

## Scope

This repository is a **GitHub Template** — it ships developer tooling,
CI/CD workflows, and dev container configuration, with **no application
code**. Most application-level vulnerability classes (auth bypass,
injection, XSS, etc.) don't apply here.

In scope for this repo:

- Secrets or credentials committed to the repository history
- A GitHub Actions workflow that could allow unauthorized code execution or
  exfiltration of secrets (e.g. via script injection through untrusted
  input, or an unpinned/compromised third-party action)
- A Husky hook or `postCreateCommand` that executes untrusted code
- A dependency (npm, pub, or GitHub Action) with a known critical CVE

Once you run `flutter create` and start building your app, the security of
your **application code and its dependencies** becomes your own
responsibility — this policy covers only the template itself.

## Supported Versions

Only the latest commit on `main` is supported. This is a template, not a
versioned library — always start new projects from the current `main`.

## Supply chain

- Every GitHub Action is pinned to a full commit SHA, workflows run with
  least-privilege `permissions:` and `persist-credentials: false`, and
  `${{ }}` values reach scripts only through `env:`. Dependabot proposes
  updates weekly with a 7-day cooldown, and `actionlint` checks every
  workflow on each pull request.
- Once a project has a `pubspec.lock`, pull requests scan every resolved
  package against the OSV vulnerability database.
- The npm dependencies (Husky, commitlint) are locked in `pnpm-lock.yaml`.
- The template needs no secrets; deployment credentials belong in
  environment secrets added per project.
- A weekly check compares the template with the `flutter-devcontainer` image
  so the two cannot drift apart unnoticed.

## Reporting a Vulnerability

**Please do not open a public issue for security vulnerabilities.**

Report privately via [GitHub Security Advisories](https://github.com/alihaidar0/flutter-template/security/advisories/new)
for this repository. Include:

- A description of the vulnerability and its potential impact
- Steps to reproduce (a minimal example is ideal)
- A suggested fix, if you have one

Expect an initial response within **5 business days**. Once confirmed, a fix
will be prioritized and a GitHub Security Advisory published when a patch is
available.

## Related

Vulnerabilities in the base Docker image itself (OS packages, SDKs, CLI
tools) belong to [`flutter-devcontainer`'s security policy](https://github.com/alihaidar0/flutter-devcontainer/blob/main/SECURITY.md).
