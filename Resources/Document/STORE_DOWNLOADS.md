# Store downloads and diagnostics

`StoreDownloadService` uses `volumeStoreDownloadProduct` first. It tries the
redownload endpoint once for failure 5002, a missing/empty songList, or a
"No Longer Available" availability message, with no failure code, account
dialog or action present. When the redownload stays empty — including its
empty HTTP 500 response — an iOS request (iPhone or iPad) draws the
`updateProduct` endpoint exactly once with the already resolved version.
Other rejections and transport errors are surfaced without this fallback.
Numeric failure codes and `metrics.messageCode` are recognized, and Apple's
customer messages are preserved in the error UI. License-required responses
still use the explicit acquisition UI. This mirrors the recovery chain of
[ipatool pull 554](https://github.com/majd/ipatool/pull/554): redownload
covers empty and unavailable volume responses, update covers the remaining
empty redownload failures, and the update response must be a single item
matching the requested app, bundle and version.

Before an unversioned fallback, the catalog resolves the current external version
ID for the selected platform and account's storefront. This asks redownload
for the selected platform's current build; the downloaded IPA is validated too. Explicit historical version IDs are kept
on both endpoints, using their respective `externalVersionId` / `appExtVrsId` keys.
A catalog failure stops the fallback instead of sending an unpinned request.
Existing saved packages without a platform default to iOS; new search results
retain the selected iPhone, iPad or Apple TV platform.

Xcode and Settings > Logs show `Store download [request ID]` entries with app ID,
platform, storefront, requested/resolved version, endpoint, HTTP status, response
size, item count, numeric error/status codes, and the fallback reason. Cookie
presence and dialog/message presence are booleans. Headers, raw bodies, Apple
messages, emails, DSIDs, device identifiers, signatures and asset URLs are not
logged. ApplePackage verbose logging stays disabled.

```sh
bash Resources/Scripts/check.downloads.sh
```

These checks exercise primary success, single-empty and 5002 fallbacks, the
iOS-only update hop, pinned history, failed catalog resolution, explicit
errors and dialogs, response redaction, endpoint-specific version keys, and
credential redirect restrictions.
The same checks run in a dedicated pull request workflow. Real account downloads
remain necessary to verify Apple's current behavior for any particular app.

The empty volume response and platform selection behavior are tracked in
[ipatool issue 538](https://github.com/majd/ipatool/issues/538#issuecomment-5578405805).

Version-history and version-metadata lookups share the same bounded fallback.
Their cache keys include the platform. After transfer, the main app's Info.plist
must match the expected bundle ID and iOS/tvOS platform before signature injection.
A response that reports a different requested version is rejected.
