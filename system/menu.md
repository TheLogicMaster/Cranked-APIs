# System menu, system state, and the network

This file covers the system menu as a game uses it (the game's own menu items, checkmark and options items, their
values, the three-item limit and its messages, the menu image, the pause and resume events), the system and device
information functions (power and battery, language and settings, headphones, `isSimulator`, `apiVersion`, system
info, stats), restarting and launch arguments, and the network and online functions (access, `getStatus`, HTTP and
TCP in C, `getServerTime`, scoreboards, Mirror). The CoreLibs crank indicator is in [input.md](input.md). Behaviour
is given for the device (3.1.2, by analysis) and the Simulator (SDK 3.1.1).

## Menu items (Lua)

`playdate.getSystemMenu()` returns the menu, a userdata, and a new value on each call.

| Call | Result |
| --- | --- |
| `menu:addMenuItem(title, callback)` | the item and nil |
| `menu:addCheckmarkMenuItem(title, [value], callback)` | the item and nil |
| `menu:addOptionsMenuItem(title, options, [value], callback)` | the item and nil |
| a fourth item of any kind | nil and `"Cannot add more items to this menu."` (a returned message, not a raised error) |
| `menu:getMenuItems()` | a table of the items; they are new values, not the ones `addMenuItem` returned |
| `menu:removeMenuItem(item)`, `menu:removeAllMenuItems()` | remove them; `#getMenuItems()` is then smaller, or 0 |
| `item:getTitle()`, `item:setTitle(t)` | the title |
| `item:getValue()`, `item:setValue(v)` | see below |
| `item:setCallback(f)` | replaces the callback |

A game may add at most three items. Options must be strings; a non-string option is a Lua argument error.

### Item values

- **Plain item:** an integer, kept as given (`setValue(7)` reads back 7).
- **Checkmark item:** a boolean, or otherwise an integer.
- **Options item:**
  - a number n selects option n, counting from 1; a number past the end, or below 1, selects the first;
  - a string selects the option with that text, or the first when none matches;
  - `getValue()` returns the selected option's text (`"y"` for an item created with `{ "x", "y" }` and `"y"`).

A common mistake is to take the number as a 0-based index, so that `setValue(1)` chooses the second option.
(`tests/probes/menuq`)

### Unknown fields

Setting a field that a `playdate.menu.item` does not have is an error: `"Could not set value for 'foo' on
playdate.menu.item"`. A number key is named by its number (`'1'`), and `callback` counts as unknown (use
`setCallback`). Reading an unknown field gives nil. (`tests/probes/newidx`)

## Menu items (C)

- `system->addMenuItem(title, callback, userdata)`, `addCheckmarkMenuItem(title, value, callback, userdata)` and
  `addOptionsMenuItem(title, options, count, callback, userdata)` return a `PDMenuItem*`. A fourth item returns
  NULL.
- The userdata is stored and passed to the callback unchanged; `getMenuItemUserdata` returns it, and
  `setMenuItemUserdata` replaces it. Any value works, including small integers such as `(void *) 1`: it is never
  treated as an address.
- `getMenuItemValue` and `setMenuItemValue`: a checkmark item's value is 1 or 0; an options item's value is the
  index of the selected option (`setMenuItemValue(m, 2)` reads back 2).
- `getMenuItemTitle`, `setMenuItemTitle`, `removeMenuItem`, `removeAllMenuItems`.
- **NULL items are accepted:** the menu item functions do nothing for a NULL item. Waternet sets an item's value
  before creating it; on the device (3.1.2, by analysis) that call does nothing.

## The menu image

`playdate.setMenuImage(image, [xOffset])` sets the image shown beside the menu while the game is paused.

- nil (or no image) clears it.
- Anything else that is not an image is an argument error: `"bad argument #1 to '?' (playdate.graphics.image or
  nil)"`. Calling it with no argument raises this error too.
- C `system->setMenuImage(bitmap, xOffset)` accepts NULL, meaning no image.

## Pause and resume

Opening the system menu pauses the game: Lua `playdate.gameWillPause()` runs before the menu appears and
`playdate.gameWillResume()` when it closes; C games get `kEventPause` and `kEventResume` through their event handler.
The order of these events and the game clock's behaviour while the menu is open were not measured; this follows
*Inside Playdate*.

## System and device information

| Call | In the Simulator (SDK 3.1.1) |
| --- | --- |
| `playdate.isSimulator` | 1 in the Simulator; nil on the device (3.1.2, by analysis). A common mistake is 0, which is truthy in Lua |
| `playdate.apiVersion()` | `30101, 10000` (the SDK version and the minimum supported version) |
| `playdate.getSystemLanguage()`, C `getLanguage()` | 0, `kLanguageEnglish` (`kLanguageJapanese` is 1; both also in `playdate.graphics.font`) |
| `getReduceFlashing()`, `getFlipped()`, `shouldDisplay24HourTime()` | false, false, false (booleans; C returns 0) |
| `playdate.getPowerStatus()` | `{ charging = true, USB = true, screws = false }` (booleans) |
| `getBatteryPercentage()`, `getBatteryVoltage()` | floats: 100 and 4.2 |
| C `getPowerStatus()` | charging, over USB, as in Lua |
| `playdate.sound.getHeadphoneState()` | two booleans, headphones and microphone: true, false on the Linux Simulator |
| C `sound->getHeadphoneState(&h, &m, NULL)` | leaves the outputs untouched |
| `playdate.getSystemVolume()` | exists |
| C `getSystemInfo()` | a non-NULL structure |
| `playdate.getStats()` | nil; `setStatsInterval(n)` is accepted |
| `setAutoLockDisabled(flag)` | accepted |
| C `setSerialMessageCallback(cb)` | accepted |

The Simulator reports a full device on its cable. Games may take other paths on battery: cloudburst switches to a
5 fps low-power mode when not charging, so an implementation that reports a battery that is not charging runs it
differently from the Simulator. On a device the values are real. (`tests/probes/powq`)

An implementation that behaves as a device should leave `isSimulator` nil, provide no `playdate.simulator` functions,
and report no headphones.

## Restarting, launch arguments, leaving the game

- **`playdate.restart([args])` and C `system->restartGame(args)`:** the call returns, and the rest of the current
  update runs. The game then starts again from scratch, with a fresh Lua state and globals; the data folder is kept.
  The argument string is split at every single space, and the pieces follow the game's name in `playdate.argv`:
  `"alpha beta  gamma"` gives `alpha`, `beta`, an empty argument, `gamma`. With no arguments, `argv` holds just the
  name. (`tests/probes/restq`)
- **`playdate.argv[1]`** names the game: the Simulator gives the `.pdx` name (`"netq.pdx"`), and on the device
  (3.1.2, by analysis) it is the game's path. Launch arguments follow it.
- **C `getLaunchArgs(&path)`** returns NULL when there are no arguments, and sets `path` to the game, as in
  `argv[1]`.
- **`playdate.exitToLauncher()`** runs `playdate.gameWillTerminate()` and ends the game; the device returns to the
  launcher.

## Network

### Access

- The first `playdate.network.http.new`, `https.new` or `tcp.new` (or `requestAccess`) asks for access: the game
  stops at that call while the system shows "Allow Internet Access?". If the player declines, `new` returns nil, and
  later calls return nil at once. (`tests/probes/netq`, with the prompt answered "No thanks".)
- `playdate.network.getStatus()` then returns 2. The constants are `kStatusNotConnected` 0, `kStatusConnected` 1 and
  `kStatusNotAvailable` 2. C `network->getStatus()` returns 0 (not connected) in the Simulator.
- `network.setEnabled` does nothing visible; the Simulator never ran its callback.

### C

On the device (3.1.2, by analysis):

- `network->http->newConnection` returns NULL without access (the Simulator does too).
- `network->tcp->newConnection` always makes the object, and `tcp->open` returns -20 without access.
- An emulator without an access prompt can decline: `requestAccess` returns `kAccessDenied`.

### Server time

`playdate.getServerTime(callback)` without a network calls back at the next update with nil and
`"Internal Error: -20"`. C `system->getServerTime` does the same, after the next update callback.
(`tests/probes/csrvtime`)

### Scoreboards

Offline, measured in the Simulator (`tests/probes/scoreb`): `playdate.scoreboards` exists with `addScore`,
`getScores`, `getScoreboards` and `getPersonalBest`, and none of them returns a value. `getPersonalBest` calls back
with `{ code = "ERROR", message = "Player not registered" }` and nil, after the call returns and before the next
`playdate.update`; the other callbacks never run. A game with a high-score screen (moon-is-friend) indexes
`playdate.scoreboards`, so the table must exist. The online behaviour was not measured.

### Mirror

`playdate.sendMirrorData` and C `system->sendMirrorData` return false (0) when no Mirror is connected.
