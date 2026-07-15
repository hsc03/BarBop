# Release Process

This document describes the direct distribution path for BarBop. It is a
preparation guide; it does not store certificates, Apple credentials, app
specific passwords, or notary credentials.

## Release Goals

- Build a Release configuration app.
- Sign the app with a Developer ID Application certificate for public
  distribution.
- Notarize the app with Apple's notary service.
- Staple the notarization ticket to the app or distributable container.
- Publish a GitHub Release with the artifact and SHA-256 checksum.
- Use the GitHub Release URL and checksum later for Homebrew Cask work.

## Local Release Artifact

For a local build artifact:

```sh
scripts/build-release.sh
```

The script writes:

- `build/release/BarBop.zip`
- `build/release/BarBop.zip.sha256`

This local script validates that a Release build can be created and packaged.
It does not guarantee that the result is correctly Developer ID signed or
notarized.

## Developer ID Signing Requirements

Before public distribution, the app must be signed with a Developer ID
Application certificate. Development, ad hoc, Mac App Store, and local signing
identities are not suitable for direct public distribution.

Release signing should satisfy:

- Developer ID Application certificate
- Hardened Runtime enabled
- Secure timestamp
- No `get-task-allow` entitlement in the final public artifact
- No private signing credentials committed to Git

Recommended first pass:

1. Create an archive from Xcode.
2. Open Xcode Organizer.
3. Choose Distribute App.
4. Choose Developer ID.
5. Let Xcode sign and upload for notarization.
6. Export the notarized app.

This UI flow is the least error-prone starting point. Scripted signing can be
added after the first successful manual release.

## Version and Build Number Policy

Release versioning is handled on the `release` branch.

- `MARKETING_VERSION` is the user-facing version, such as `0.1.0`.
- `CURRENT_PROJECT_VERSION` is the monotonically increasing build number.
- Version changes should be made in Xcode build settings or with a dedicated
  project-file-aware tool, not by manually editing `project.pbxproj`.
- Git tags should use the user-facing version, such as `v0.1.0`.

Before creating a GitHub Release:

```sh
xcodebuild -showBuildSettings -scheme BarBop | grep -E 'MARKETING_VERSION|CURRENT_PROJECT_VERSION|PRODUCT_BUNDLE_IDENTIFIER'
```

Record the version, build number, and bundle identifier in the release notes.

## Notary Credentials

For command-line notarization, store credentials in Keychain:

```sh
xcrun notarytool store-credentials "barbop-notary" \
    --apple-id "<APPLE_ID>" \
    --team-id "<TEAM_ID>" \
    --password "<APP_SPECIFIC_PASSWORD>"
```

Do not write these values into repository files.

## Command-Line Notarization Outline

After exporting a Developer ID signed app:

```sh
ditto -c -k --keepParent "BarBop.app" "BarBop.zip"
xcrun notarytool submit "BarBop.zip" --keychain-profile "barbop-notary" --wait
xcrun stapler staple "BarBop.app"
xcrun stapler validate "BarBop.app"
ditto -c -k --keepParent "BarBop.app" "BarBop.zip"
shasum -a 256 "BarBop.zip" > "BarBop.zip.sha256"
```

ZIP archives can be submitted to the notary service, but the ticket is stapled
to the app bundle before creating the final ZIP.

## GitHub Release Checklist

- [ ] Confirm `develop` has the validated release candidate.
- [ ] Merge the release candidate into `release`.
- [ ] Set the release version and build number.
- [ ] Build Release configuration.
- [ ] Sign with Developer ID.
- [ ] Notarize and staple.
- [ ] Create final ZIP.
- [ ] Generate SHA-256 checksum.
- [ ] Draft GitHub Release notes.
- [ ] Upload ZIP and checksum.
- [ ] Verify the download URL.
- [ ] Download the artifact from GitHub and launch it on a clean macOS account
      or machine.

## GitHub Release Notes Template

Use this as the body of the GitHub Release:

````md
## BarBop vX.Y.Z

### Changes

- Menu bar click effect utility for macOS.
- Flash, Pulse, Sweep, and Aurora effect styles.
- Local settings for color, opacity, duration, and style.

### Verification

- Release build completed.
- Developer ID signing completed.
- Apple notarization completed.
- Stapling validation completed.

### Checksums

`BarBop.zip`

```text
<SHA-256>
```
````

## Homebrew Follow-Up

After the GitHub Release is published, the Homebrew Cask step needs:

- Stable release URL
- Version
- SHA-256 checksum
- App bundle name
- Minimum supported macOS version
- Uninstall and zap behavior

The first Homebrew distribution will use the separate public personal tap
`hsc03/homebrew-tap`. Follow `docs/personal-homebrew-tap.md` for the repository
layout, Cask template, validation commands, update policy, and completion
criteria.
