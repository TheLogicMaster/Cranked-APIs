# Input: buttons, crank, accelerometer, keyboard

This file covers how a game reads input: button state and the pressed and released edges, the Lua button callbacks
and `playdate.inputHandlers`, C `getButtonState` and `setButtonCallback`, the crank (angle, change, accelerated
change, docking, ticks, crank sounds, the CoreLibs crank indicator), the accelerometer, and the CoreLibs keyboard
(`playdate.keyboard`). Behaviour is given for the device (3.1.2, by analysis) and the Simulator (SDK 3.1.1). Crank
behaviour that could not be driven in the Linux Simulator is marked as taken from *Inside Playdate*.

## Buttons

### Constants

| Constant | Value |
| --- | --- |
| `kButtonLeft` | 1 |
| `kButtonRight` | 2 |
| `kButtonUp` | 4 |
| `kButtonDown` | 8 |
| `kButtonB` | 16 |
| `kButtonA` | 32 |

The C names (`kButtonLeft`, ... in `PDButtons`) have the same values.

### Lua queries

- `playdate.getButtonState()` returns three integers: the buttons held now, those pressed since the last update, and
  those released since the last update. With nothing touched it is `0, 0, 0`. The pressed and released bits are set
  for one frame each.
- `buttonIsPressed(b)` is true on every frame the button is held; `buttonJustPressed(b)` and `buttonJustReleased(b)`
  are true for exactly one frame. They are booleans (false when idle).
- These functions accept a constant or a name: `"a"`, `"b"`, `"up"`, `"down"`, `"left"`, `"right"`.
- `setButtonQueueSize(n)` is accepted.

### Lua callbacks

- A press calls `AButtonDown` once, and the release calls `AButtonUp` once (likewise for B and the d-pad
  callbacks).
- `AButtonHeld` (and `BButtonHeld`) fires once while the button stays down, one second after the press: at 30 fps,
  31 frames after it.

### `playdate.inputHandlers`

- `push(handler, [masksPreviousHandlers])` puts a handler table on a stack; `pop()` removes the top one. Popping an
  empty stack is harmless.
- An event goes to the top handler first. **If the handler has a function for it, the event stops there**: earlier
  handlers and the global `playdate.*` callbacks do not get it. With a pushed handler that defines `BButtonDown`, only
  that function runs.
- A handler pushed with `masksPreviousHandlers` true also stops the events it does not handle.
- A common mistake is to pass handled events on down the stack and to the global callbacks as well.

### C

- `system->getButtonState(&current, &pushed, &released)` fills the three masks; any of the pointers may be NULL
  (`getButtonState(&c, NULL, NULL)` is fine).
- `PDButtons` is **one byte** in games built with the SDK (arm-none-eabi uses short enums), so `getButtonState` stores
  one byte through each pointer and leaves the bytes after the game's variable untouched. Storing 32 bits overwrites a
  neighbouring variable. (`tests/probes/enumq`)
- `system->setButtonCallback(callback, userdata, queuesize)` sets a callback for button events; NULL removes it.
  (`tests/probes/btncb` drives it with scripted input.)

## The crank

### Position, docking, and change

- `playdate.getCrankPosition()` returns the angle in degrees as a float, 0 when nothing has moved it. C
  `getCrankAngle()` likewise.
- `playdate.isCrankDocked()` is a boolean, true at start in the Simulator; C `isCrankDocked()` returns 1.
- `crankDocked()` and `crankUndocked()` are called once each when the crank is docked and undocked, and
  `isCrankDocked` follows (*Inside Playdate*).
- `playdate.getCrankChange()` returns two floats, the change since the previous call and the accelerated change;
  both 0 at first. It keeps its own previous angle, separate from the one used to compute the `cranked(change,
  acceleratedChange)` callback's arguments, so it works when a game also defines `playdate.cranked`. The change is
  wrapped into -180 to 180 degrees. (A common mistake is to share one previous angle, so that `getCrankChange` always
  returns 0 in games with a `cranked` callback.)
- `cranked` reports each change, with its accelerated value (*Inside Playdate*).

### The accelerated change

`acceleratedChange = change * 1 / (1.04^(20 - |change|) + 0.2)`, computed in double precision and then rounded to
single. That is about 0.42 times the change for small changes, 0.83 at 20 degrees, and 2.45 at 60. Measured in the
Simulator by setting the crank angle frame by frame (`tests/probes/crankacc`), changes of 5, 20, 25, 30, 45, 50 and
90 degrees give 2.49882126, 16.666666, 24.4635849, 34.2636223, 78.2449799, 98.3634949 and 340.626007, the formula's
values to the last bit. Games that move by the accelerated value (BrickCrusher2020's paddle, Project Loose's cauldron)
move 2.4 times too far at slow speeds if it is taken to equal the change.

### Crank ticks

`playdate.getCrankTicks(ticksPerRevolution)` exists only once `CoreLibs/crank` is imported; without it, calling it is
"field 'getCrankTicks' is not callable (a nil value)". It is Lua code, not a native function. Turning 270 degrees at
4 ticks per revolution gives 3 ticks (*Inside Playdate*).

### Crank sounds

C `system->setCrankSoundsDisabled(flag)` returns whether the sounds were disabled before: 0 the first time, then 1
after disabling them. Lua `playdate.setCrankSoundsDisabled` is accepted.

### The crank indicator (CoreLibs)

`CoreLibs/ui/crankIndicator.lua` (SDK 3.1.1) loads 11 assets from the system files under `CoreLibs/assets/crank/`: the
crank animation as image tables at 1x, 2x, 4x and 8x, the notice bubble (with a separate 1x file), and the notice text.
Games do not bundle these files; the Simulator supplies them, and so does the device (3.1.2, by analysis). An
implementation must supply the same version of them, or the indicator's bubble and animation come out a pixel off
(Breakout shows the indicator over its screen). These are Panic's SDK files, so shipping them inside an emulator needs
Panic's permission, or a user's installed SDK.

## Accelerometer

- `playdate.accelerometerIsRunning()` is false until `startAccelerometer()`, true after it, and false again after
  `stopAccelerometer()`.
- `readAccelerometer()` returns three nils while the accelerometer is stopped, and three floats while it runs.
- C: after `setPeripheralsEnabled(kAccelerometer)`, `getAccelerometer(&x, &y, &z)` reads (0, 1, 0) by default in the
  Simulator. On the device (3.1.2, by analysis) the values are real readings.

## The keyboard (`playdate.keyboard`, CoreLibs)

- The keyboard draws its letters in Roobert-24-Keyboard-Medium (36 pixels high; "ABC@" is 132 wide) and plays its own
  click, key, denial and selection sounds. Like the crank indicator's, these assets come with the system (the SDK's
  CoreLibs folder in the Simulator, the system files on the device), not with the game. With another font the
  keyboard's columns are drawn in a different face at other positions. (`tests/probes/kbq` compares the keyboard
  after its show animation; music_box's rename dialog uses it.)
- `playdate.keyboard.left()` returns `keyboardRect.x`, a field of a geometry rect, so it is a float (222.0), not an
  integer. Every numeric field of a geometry object is a float (see [../lua/objects.md](../lua/objects.md)).
