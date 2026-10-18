# Files, the datastore, and pdxinfo

This file covers the Playdate file system as games see it: the read-only game bundle and the writable data folder,
how paths are resolved (letter case, "./", compiled modules), `playdate.file` in Lua and the C `file` interface
(open, read, write, seek, list, stat, mkdir, rename, delete), their return values and error messages, the open-file
limit, `playdate.datastore` (tables and images), the `pdxinfo` file and `playdate.metadata`, and how the data folder
is named. JSON encoding itself is in [json.md](json.md). Behaviour is given for the device (3.1.2, by analysis) and the
Simulator (SDK 3.1.1); where they differ it says so.

## Bundle and data folder

A game sees two places:

- **The bundle:** the game's `.pdx` folder (its compiled `main.pdz`, images, fonts, sounds, `pdxinfo`). Read-only.
- **The data folder:** a folder of its own on the data disk, in the Simulator `Disk/Data/<folder>/`. Writes always go
  here. Reads can see both places, depending on the mode (see the constants below).

The data folder is kept across `playdate.restart` (see [../system/menu.md](../system/menu.md)).

### The data folder's name

- The folder is named after the game's bundle ID (`bundleID` in `pdxinfo`).
- **Empty or missing bundle ID:** the Simulator names the folder after the bundle instead, for example
  `Disk/Data/connordelacruz_playdate-breakout/` for a game whose `pdxinfo` has `bundleID=` with no value. A common
  mistake is to use the root of the data disk, where such games' saves would land, shared between them.
- A `pdxinfo` that is a single line with literal `\n` sequences in it (archery) has no usable bundle ID either, so
  its bundle name is used.
- Two games with the same bundle ID share one data folder. (The SDK's HelloWorld and JSON C examples both use
  `com.panic.hellocapi`.)

## Paths

- **Relative to the game.** Paths name a file in the data folder or the bundle; a leading `/` is accepted
  (`listFiles("/songs/")`).
- **A leading `./`** names the same path: `"./images/"` lists like `"images/"`.
- **Letter case.** On the device (3.1.2, by analysis) names are matched ignoring letter case (its data disk is FAT),
  so a game that asks for `images/missile/explosion` finds `Explosion.pdt`, and `font.new("fonts/monocraft-18")` finds
  `Monocraft-18.fnt`. The macOS and Windows Simulators ignore case too; the Linux Simulator is case sensitive,
  and such games fail there (MissileCrank, PlayBook, Yonderu, playorama). Games are mostly made on case-insensitive
  systems, so an implementation should look up the exact name first and, only when no file has it, a name that
  matches ignoring ASCII case.
- **Compiled modules are not files.** The Lua modules compiled into `main.pdz` are invisible to the file functions:
  with a module `mod.lua`, `file.exists("mod")` and `file.exists("main")` are false and `getSize` gives -1, while
  `main.pdz` exists. `listFiles` of a folder that does not exist is nil even when a module has that name. (Orbeats
  lists `/songs/` with a `songs.lua` module; it gets nil, and the game then fails in the Simulator unless the data
  folder has a `songs` folder. `tests/probes/importq` covers imports.)
- **Compiled names.** Assets are listed and found under their compiled names (`.pdi`, `.pdt`, `.pft`, ...); the
  loaders also accept source names (see [../graphics/images.md](../graphics/images.md) and
  [../graphics/text.md](../graphics/text.md)).

## `playdate.file` (Lua)

### Constants

| Constant | Value |
| --- | --- |
| `kFileRead` | 3 (bundle and data folder) |
| `kFileWrite` | 4 |
| `kFileAppend` | 8 |
| `kSeekSet` | 0 |
| `kSeekFromCurrent` | 1 |
| `kSeekFromEnd` | 2 |

All are integers. The C API names the two read sources separately: `kFileRead` (1, the bundle) and `kFileReadData`
(2, the data folder); Lua's `kFileRead` is both.

### Functions

| Call | Result |
| --- | --- |
| `file.open(path)` | a file, or nil and `"No such file"` for a missing file |
| `file.open(path, kFileWrite)` in a missing folder | nil, `"No such file"` (folders are not created) |
| `file.exists(path)` | boolean |
| `file.isdir(path)` | boolean; true for folders in the data folder and in the bundle |
| `file.getSize(path)` | integer; -1 for a missing path |
| `file.getType(path)` | nil for a plain data file |
| `file.modtime(path)` | a table with `year`, `month`, `day`, `hour`, `minute`, `second` |
| `file.mkdir(path)` | true, also when the folder exists, and for nested folders |
| `file.rename(from, to)` | true on success (a boolean, not 0 or 1) |
| `file.delete(path)` | true; false for a missing file, and false for a non-empty folder |
| `file.delete(path, true)` | true; deletes a folder and its contents |
| `file.listFiles(path)` | see below |
| `file.load(path, [env])`, `file.run(path, [env])` | see below |

`getSize` of a folder is 4096 in the Simulator (the host file system's block size); the device's value is not known;
check on hardware.

### `listFiles`

- Returns the names in the folder, relative to it, in alphabetical order, with `/` after each subfolder:
  `"a.txt"`, `"sub/"`. This holds for the data folder (`tests/probes/dlistq`) and for folders inside the bundle
  (`listFiles("images/")`, with or without the trailing slash, gives `a.pdi`, `sub/`).
- The root of the bundle lists the bundle's top-level entries.
- A folder that does not exist gives nil (not an empty table).
- A name in both the data folder and the bundle is listed once (`tests/probes/audfdata`).
- A common mistake for bundle folders is to return the folder's own entry, or full paths.

### File objects

| Method | Result |
| --- | --- |
| `f:read(n)` | the data and the number of bytes read: `"abc\ndef", 7` |
| `f:readline()` | the next line without its ending; `""` for an empty line; nil at the end of the file |
| `f:write(string)` | the number of bytes written (5 for `"hello"`); the whole string is written, embedded NUL bytes included (measured, `tests/probes/jsonsmall`) |
| `f:seek(offset, [whence])`, `f:tell()` | as in C: on `"abc\ndef"`, `seek(2)` then `tell()` is 2, `read(2)` gives `"c\n"` and `tell()` 4; `seek(-1, kSeekFromEnd)` gives 6 |
| `f:flush()` | nothing |
| `f:close()` | closes the file |

`readline` ends a line at `\n`, `\r`, or `\r\n`. Writing `"a\nb\rc\r\nd\n\ne"` and reading lines gives `a`, `b`, `c`,
`d`, `""`, `e`, then nil. (A common mistake is to let a lone `\r` swallow the next character.)

`kFileAppend` appends: writing `"x"`, then appending `"y"`, reads back `"xy"`.

A missing string argument (`f:write()`), or an argument of the wrong type, is a Lua argument error that `pcall`
catches, never a crash.

### `file.load` and `file.run`

- `file.load(path)` returns a function compiled from a separately compiled `.pdz`; `file.run(path)` runs it and
  returns only that function's results.
- A missing file raises an error: `"file not found: nope.pdz"` (the path as given, plus `.pdz`).
- A separately compiled `.pdz` holds the file's own chunk and the modules it imports. Running it runs the file's own
  chunk (not whichever chunk comes first), and its imports resolve to the modules inside it. When no environment
  argument is passed, the chunk runs with the normal globals. (BlockDate's themes depend on this.)
- With an environment argument, the globals the file sets and those of the modules it imports go into that table,
  not into `_G`. A module already imported is not run again by a later `file.run` (`tests/probes/frunenv`).
- `file.load` takes only a `.pdz` without imports: for one with imported modules it raises
  `"pdz files loaded with file.load() can only contain one segment (i.e., no imports)"` (with the calling line in
  front when called from Lua code). `file.run` runs the same file (`tests/probes/frunenv`).

### The open-file limit

At most 64 files can be open at once, reading and writing counted together. One more `open` returns nil and
`"Too many open files"` until a file is closed or collected (a file the game drops is closed when it is
collected: 200 opens with a collection every 10 all succeed, `tests/probes/gckeep`). Files the system opens for the game (datastore and image
writes) count against the same limit. (`tests/probes/flimq`; the playbit test suite checks it too.)

## The C `file` interface

- **`open(path, mode)`:** NULL on failure, after which `geterr()` returns a non-empty message. The mode flags are
  `kFileRead` (bundle), `kFileReadData` (data folder), `kFileWrite` and `kFileAppend`. `open("pdxinfo", kFileRead)`
  reads the bundle's `pdxinfo` (its first bytes are `name=`).
- **`read` and `write`:** return the byte count; `read` at the end of the file returns 0.
- **`seek(file, pos, whence)` and `tell`:** `SEEK_SET`, `SEEK_CUR`, `SEEK_END`. On an 11-byte file, `seek(3, SET)`
  gives 3, `seek(2, CUR)` 5, and `seek(-1, END)` 10.
- **`flush`:** returns 0.
- **`stat(path, &st)`:** 0 on success and -1 for a missing path. `FileStat` has `isdir`, `size` and the modification
  time (`m_year`, `m_month`, ...). `stat(path, NULL)` is used as an existence check by some games (gamekid) and, on the
  device (3.1.2, by analysis), works; an implementation must not write through the NULL record.
- **`listfiles(path, callback, userdata, showhidden)`:** calls the callback with each name, in alphabetical order,
  folders with a trailing `/` (`sub/`, `x.txt`), and returns 0.
- **`rename(from, to)`:** returns 0 on success. (Lua's `file.rename` returns the inverse as a boolean.)
- **`unlink(path, recursive)`:** 0 on success; -1 for a non-empty folder without `recursive`.
- **NULL paths:** on the device (3.1.2, by analysis), `open`, `listfiles`, `mkdir`, `unlink` and `rename` with a NULL
  path fail (NULL or -1); they must not crash.

## Datastore

`playdate.datastore` stores a Lua table as a JSON file in the data folder.

### `write`, `read` and `delete`

- `datastore.write(value, [name], [prettyPrint])` writes `<name>.json` (the documented default name is `data`).
  - It is pretty-printed **unless** `prettyPrint` is given as false. *Inside Playdate* says only when it is true;
    the Simulator does the opposite of that.
  - Nested empty tables are written as `[]` at any depth, and read back as empty tables. (Writing `null` for them,
    so that they read back as nil, broke Project Loose.)
  - Besides a table, a boolean or a string is accepted, and reads back unchanged. A number is written, but reads back
    as nil.
  - Returns true.
- `datastore.read([name])` returns the value, or nil for a missing, empty or invalid store (never an error message).
  `{ x = 1, y = { 2, 3 } }` reads back with integer 1, 2 and 3.
- `datastore.delete([name])` returns true, and a later `read` is nil.

### Images

- `datastore.writeImage(image, path)` writes into the data folder, under `images/` when the path names no folder,
  with the name as given (no extension is added): `"pic"` becomes `images/pic`, `"sub/pic2"` stays `sub/pic2`. A name
  ending in `.gif` writes a GIF. It returns nothing.
- `datastore.readImage(path)` uses the same folder rule, also finds `name.pdi` when given `name`, and returns nil for
  a missing image. It reads only from the data folder, not from the bundle.
- With no arguments, `readImage()` is a Lua argument error that `pcall` catches.

The Simulator's PDI for a 10 by 6 opaque image is 48 bytes, and its GIF encoder compresses. Games read these files
back only through `readImage`, so a reimplementation need not match the exact bytes.

## pdxinfo

`pdxinfo` is a text file of `key=value` lines in the bundle. On the device (3.1.2, by analysis):

- A line's trailing carriage return is dropped.
- Some keys are matched ignoring letter case, among them `bundleID`, `imagePath` and `launchSoundPath`: the SDK
  example MenuLocalization writes `bundleid`, and its data folder is still `com.panic.menufonttest`. Others, such as
  `name`, `author` and `version`, are case sensitive.
- The file has no terminating NUL; a parser must stop at its length.

### `playdate.metadata`

`playdate.metadata` holds only the documented keys, as strings: `name`, `author`, `description`, `bundleID`,
`version`, `buildNumber`, `imagePath`, `launchSoundPath`, `contentWarning` and `contentWarning2`, plus `pdxversion` as
an integer. `buildtime` and any keys of the game's own are left out. (`tests/probes/metaq`)
