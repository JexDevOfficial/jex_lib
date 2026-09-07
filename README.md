<div align="center">

# jex_lib

**The library every Jex script runs on.**
Detects your framework and gets out of the way.

[![Release](https://img.shields.io/github/v/release/JexDevOfficial/jex_lib?style=flat-square&color=B7FF3C)](../../releases/latest)
[![License](https://img.shields.io/badge/license-MIT-B7FF3C?style=flat-square)](LICENSE)

[Download the latest release](../../releases/latest) · [jex.dev](https://jex.dev)

</div>

---

One dependency. Free, always.

Every Jex script loads this and nothing else. It works out which
framework your server is built on when it starts, so there is no core to
set and no SQL to import.

## Install

1. Grab **`jex_lib.zip`** from the [latest release](../../releases/latest)
2. Unzip it into your `resources` folder
3. Add it above anything that uses it

```cfg
ensure oxmysql
ensure jex_lib
```

That is the install. No core to set, no SQL to import.

> Take `jex_lib.zip` from the release, not the green **Code → Download
> ZIP** button. That one gives you the whole repository in a folder named
> after the branch, which you would then have to rename. The release zip
> is already just the resource.

## What it does

**Detects your framework** — VORP, RSG or RedEM:RP, at runtime. Nothing
to configure. Core and inventory are detected separately, because plenty
of servers run one with somebody else's other.

**Gives every script one set of names.** `Jex.Core.GetMoney(src, 'cash')`
does the right thing whichever core you run. The differences between them
stay inside the adapters.

**Builds its own tables.** A script hands over its schema and the library
creates whatever is missing on first start. Nobody imports a SQL file.

**Validates on the server.** Distance, ownership, funds, job and rate
limits in one call. The client sends intent; the server decides.

**Does not move.** Once a function is published, its name and signature
are fixed. Additions yes, breaking changes no. Updating this will not
break a script you already own.

## Requirements

- [oxmysql](https://github.com/overextended/oxmysql)
- VORP, RSG or RedEM:RP — or fill in one file for anything else

## Using it

In your script's `fxmanifest.lua`:

```lua
dependency 'jex_lib'

shared_scripts {
    '@jex_lib/init.lua',
    'config.lua',
}
```

Everything then lives on `Jex`.

```lua
local price = 12

if not Jex.Guard.Check(src, { coords = office.coords, cost = price }) then
    return
end

Jex.Core.RemoveMoney(src, 'cash', price, 'telegram')
Jex.Core.Notify(src, 'Sent.', 'success')
```

That runs unchanged on every supported core.

### Version check

```lua
Jex.Require('1.2')
```

Stops with a readable message if the installed library is too old,
rather than failing on a missing function three files later.

## API

### Jex.Core

Same signatures on every framework.

| | |
|---|---|
| `GetIdentifier(src)` | Character id — use as your database key |
| `GetName(src)` | `"First Last"` |
| `GetCharInfo(src)` | `{ firstname, lastname, birthdate, gender }` |
| `GetJob(src)` / `GetGang(src)` | Never nil |
| `HasJob(src, jobs, minGrade)` | `jobs` is a string or a list |
| `GetPlayers()` | Array of server ids |
| `IsLoaded(src)` | Is their character in yet |

**Money** — accounts are `cash`, `bank` or `gold`

| | |
|---|---|
| `GetMoney(src, account)` | |
| `AddMoney(src, account, amount, reason)` | |
| `RemoveMoney(src, account, amount, reason)` | false if they cannot afford it |

**Items**

| | |
|---|---|
| `AddItem(src, item, amount, meta, slot)` | |
| `RemoveItem(src, item, amount, meta, slot)` | |
| `GetItems(src)` | Array of items, one shape on every inventory |
| `GetItemCount(src, item)` / `HasItem(src, item, amount)` | |
| `CanCarry(src, item, amount)` | |
| `RegisterUsableItem(item, cb)` | `cb(src)` |

**Notify** — `Jex.Core.Notify(src, msg, type, duration)` on the server,
`Jex.Core.Notify(msg, type, duration)` on the client. Types are
`success`, `error`, `info`, `warning`.

### Jex.Guard

Server-side checks. Every one returns false rather than throwing.

```lua
Jex.Guard.Check(src, {
    coords = point.coords,   -- actually standing there
    within = 4.0,
    job = 'sheriff', grade = 2,
    cost = 50, account = 'bank',
    item = 'telegram', amount = 1,
    rate = 'send', perMinute = 10,
})
```

Also available on their own: `Near`, `Job`, `CanAfford`, `HasItem`,
`Owns`, `Rate`, and `Str` / `Int` / `OneOf` for arguments.

### Jex.DB

```lua
Jex.DB.Install {
    [[CREATE TABLE IF NOT EXISTS `jex_telegram_messages` ( ... )]],
}

Jex.DB.Ready(function()
    local rows = Jex.DB.Query('SELECT * FROM jex_telegram_messages WHERE to_number = ?', { number })
end)
```

`Query`, `Single`, `Scalar`, `Insert`, `Update`, and `AddColumn` for
adding a column safely on every start.

### Jex.Callback

```lua
-- server
Jex.Callback.Register('inbox', function(src)
    return getMessagesFor(src)
end)

-- client
local inbox = Jex.Callback.Await('inbox')
```

Namespaced per resource, so two Jex scripts never answer each other's
calls. Every request times out.

### Jex.Util

`Round`, `Comma`, `Coords`, `Distance`, `Near`, `Closest`, `Trim`,
`Clean`, `Id`, and `Jex.Wait()` for anything that touches player data at
resource start.

## Shapes

```lua
-- Job
{ name = 'sheriff', label = 'Sheriff', grade = 2,
  gradeLabel = 'Deputy', onDuty = true, isBoss = false }

-- Item
{ name = 'consumable_apple', label = 'Apple', amount = 3, slot = 1,
  weight = 100, type = 'item', unique = false, useable = true,
  meta = {}, image = 'apple.png' }
```

Job and gang getters never return nil — you get an empty job instead.
List getters always return a table. Item metadata is always `meta`,
whatever the inventory calls it internally.

## Unsupported cores

`core/custom.lua` has every function with the body left empty and a note
saying what it should return. Fill it in and every Jex script works — you
never touch a script itself.

## What is tested

| Framework | Status |
|---|---|
| RSG | Written against source and run on a live server |
| VORP | Written against source, **not yet run live** |
| RedEM:RP | Written against source, **not yet run live** |

VORP and RedEM:RP calls are wrapped so a wrong guess degrades instead of
taking the resource down. RedEM:RP does not expose its inventory the way
the others do — money, jobs and identity are solid there, items are the
least certain part. If you hit something, open an issue with your
console output.

## Repo layout

```
jex_lib/            the resource - this is what goes in your server
  fxmanifest.lua
  init.lua          the only file a script references
  config.lua        fallbacks, rarely touched
  boot.lua          reports what it detected, on start
  core/             one adapter per framework
  modules/          db, callbacks, validation, helpers
```

Everything outside `jex_lib/` is documentation and tooling. Only the
folder itself ships.

## Contributing

Bug reports and framework fixes are welcome, particularly from anyone
running VORP or RedEM:RP.

One rule: **published functions do not change.** New functions yes,
renamed or removed ones no. Scripts depend on this staying still.

## License

MIT. See [LICENSE](LICENSE).
