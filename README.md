# shared-packages

Reusable Dart/Flutter packages, one folder per package under `packages/`. Packages are consumed as git dependencies pinned to a per-package tag, so each one is versioned independently.

| Package | For | Tag format |
|---|---|---|
| [`m18_shared`](packages/m18_shared) | M18 Residences admin + tenant apps | `m18_shared-vX.Y.Z` |

## Consuming a package

```yaml
dependencies:
  m18_shared:
    git:
      url: https://github.com/whatever413y/shared-packages.git
      path: packages/m18_shared
      ref: m18_shared-v0.1.0
```

Local development against a sibling checkout: a gitignored `pubspec_overrides.yaml` in the app with `dependency_overrides: {m18_shared: {path: ../shared-packages/packages/m18_shared}}`.

## Releasing a package

1. Bump `version:` in the package's `pubspec.yaml` and add a `CHANGELOG.md` entry.
2. Commit, then tag and push the tag: `git tag m18_shared-vX.Y.Z && git push origin m18_shared-vX.Y.Z`.
3. Point each consuming app's `ref:` at the new tag.

CI (`.github/workflows/`) runs format, analyze and tests per package on the latest stable Flutter.

This repo is public: never commit secrets, real tokens or production data (test fixtures use synthetic data).
