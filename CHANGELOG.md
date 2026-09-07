# Changelog

Published functions do not change. Additions get a minor version, fixes
get a patch. A breaking change would need a major version, and the point
of this library is that there is never a reason for one.

## 1.0.0 — unreleased

First release.

- Framework detection at runtime for VORP, RSG and RedEM:RP, with a
  custom slot for anything else
- `Jex.Core` — one set of names for player, money, items, jobs and
  notifications across every supported core
- `Jex.DB` — tables that build themselves on first start, additive only
- `Jex.Guard` — server-side distance, ownership, funds, job, argument
  and rate-limit checks
- `Jex.Callback` — client to server requests, namespaced per resource,
  with timeouts
- `Jex.Util` — coords, distance, text cleaning, and `Jex.Wait()` for the
  framework load race
- `Jex.Require()` — version check with a readable message

Tested on RSG. VORP and RedEM:RP are written against their source but
have not been run on a live server.
