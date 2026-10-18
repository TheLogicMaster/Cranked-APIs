# JSON

This file covers JSON in the Playdate API: Lua's `json.encode`, `json.encodePretty`, `json.encodeToFile`,
`json.decode` and `json.decodeFile`, and the C `json` interface (`json->decode`, `json->decodeString` with a
`json_decoder` of callbacks, and the `json_encoder` writer). It describes number formatting, key order, pretty
printing, the error values and messages, the decoder's edge cases, and the order of the C callbacks. The rules
below are those of the device (3.1.2, by analysis); the Simulator (SDK 3.1.1) was measured to give the same results for
Lua and C decoding and for encoding, except where a section says otherwise. The datastore, which stores tables as JSON
files, is in [files.md](files.md).

## Encoding (Lua)

### Arrays and objects

A Lua table becomes a JSON array or a JSON object by its keys:

- **Array:** every key is an integral number of at least 1. The array runs from index 1 to the largest key, and
  missing indexes are written as `null`. An empty table is an array: `json.encode({})` is `[]`, at any depth.
- **Object:** any other table.
  - If the table also has an array part, it is written as an `"_array"` member holding that array.
  - Number keys above the largest array index are written as object keys, as integers.
  - Other number keys (0, negative numbers, and fractions below the largest index) are dropped.
  - A key of any other type (a boolean, a table, ...) is an error.

### Values

| Lua value | Written as |
| --- | --- |
| integer | decimal integer |
| float | `%.14g` of the value widened from single precision: `0.1` is written `0.10000000149012`; `2.5` is `2.5` |
| float outside the single-precision range | `null` |
| string | a JSON string, with `"` escaped as `\"` |
| boolean | `true` / `false` |
| function, userdata, thread | a string such as `"function 0x..."` (the type name and the address) |
| a table nested inside itself | the string `"RECURSION ERROR"` at the point of recursion |

Lua numbers on the Playdate are 32-bit integers and single-precision floats (see
[../lua/runtime.md](../lua/runtime.md)), which is why a float like `0.1` prints with float error.

`json.null` is not special to the encoder: in the Simulator it is a table with `__tostring` and `__call` members,
and `json.encode({ a = json.null })` writes it as an object holding those two members as function strings
(`{"a":{"__tostring":"function 0x...","__call":"function 0x..."}}`), not as `null`.

### Key order

- **`json.encode`** writes an object's keys in table order, the order `pairs` gives. Lua's string hash is seeded at
  start-up from the time and some addresses, on the device (3.1.2, by analysis) too, so this order changes from boot to
  boot and cannot be reproduced exactly. For example `json.encode({ a = 1, b = { 1, 2, 3 }, c = "x", d = true })` gave
  `{"b":[1,2,3],"a":1,"d":true,"c":"x"}` in one run. (`tests/probes/jsonord` records the order twice per run.)
  An implementation that wants repeatable runs may fix the seed as an option, but the default should stay
  unpredictable, like the device.
- **`json.encodePretty`** sorts the keys. A table with both number and string keys therefore raises Lua's comparison
  error.

### Compact and pretty output

`json.encode` writes compact JSON with no white space: `[1,2.5,"a",false]`.

`json.encodePretty` (and `encodeToFile` with pretty set) uses these rules:

- one member or element per line, indented with one tab per level;
- no space after the colon before a plain value (`"a":1`), and one space before a table or array (`"b": [`);
- the closing bracket on its own line at the parent's indentation.

So `json.encodePretty({ a = 1, b = { 2 } })` is:

    {
    <tab>"a":1,
    <tab>"b": [
    <tab><tab>2
    <tab>]
    }

### Files

- `json.encodeToFile(path, pretty, table)` writes the JSON to a file in the game's data folder.
  `json.encodeToFile("j2.json", true, { a = 1 })` writes `{\n\t"a":1\n}`.
- The datastore writes JSON through the same encoder (see [files.md](files.md#datastore)).

### Errors while encoding

A key of a type JSON cannot hold raises a Lua error. After an encode or decode error inside a nested table, the next
encode of a table can crash the Simulator (for example `json.encodePretty({ [true] = 1 })`, then any table). The device
(3.1.2, by analysis) is likely affected too (check on hardware). An implementation should raise the error and stay
usable afterwards.

## Decoding (Lua)

`json.decode(string)` returns a Lua value, or nil and a message. `json.decodeFile(pathOrFile)` accepts a path (and,
as documented, an open file). A missing file gives `nil, "file not found: missing.json"` (the path as given).

**Short files.** `json.decodeFile` returns `nil, "empty file at line 1"` for any file shorter than 3 bytes, whatever
it holds and whether given a path or an open file: `[]`, `{}`, `1`, `12`, `1 `, `""`, `\n\n` and an empty file all
do, while `json.decode` of the same text gives `{}`, `{}`, `nil, nil`, ... So a table that `json.encodeToFile` saved
compactly as `[]` reads back as nil; saved pretty (3 bytes) it reads back as `{}`. From 3 bytes on, files
decode as `json.decode` would (`[1]`, `"x"`, `-1 `, `[ ]`), except that a leading UTF-8 byte order mark is skipped
(`EF BB BF` then `[]` is `{}`; a BOM alone is "empty file"; `EF BB BF 31` gives `nil, nil`, the silent failure of
a number at the end of the input). (`tests/probes/jsonsmall`)

### Values

- **Objects** become tables with string keys, **arrays** become tables with keys 1..n.
- **`null`:** a `null` array element leaves a hole at its index; a `null` object member removes its key (so
  `{"c":null}` decodes to an empty table).
- **Duplicate keys:** the last value wins.
- **`"_array"`:** a member named `_array` whose value is a table (an array) is merged into its parent, the reverse
  of what the encoder writes.
- **Integers and floats:** `3` decodes as the integer 3 and `3.0` as the float 3.0.

### The number rules

The decoder reads one byte at a time with rules of its own, which differ from a general-purpose JSON library:

- The integer part accumulates in a 32-bit integer that wraps: `9999999999` reads as 1410065407.
- A fraction takes at most 9 digits and is computed in single precision (`0.1` is the float with bits 0x3DCCCCCD).
- An exponent without a fraction gives an integer when the exponent is positive and the result is in range on the
  side of its sign: at most 2^31-1 for a number written without a minus sign, at least -2^31 for one written with
  it. `1e3` is the integer 1000, `-2e9` the integer -2000000000; `2.1e9` (a fraction), `1e10`, `214748365e1` and
  `5e0` (exponent 0) are floats. Only that one bound is checked, so an integer part that has wrapped can pass with a
  result out of range, which then reads as -2^31: `7667237095e1` (whose integer part wraps to -922697497) and
  `-7688231203E020` both give the integer -2147483648 in the Simulator, whose x86 conversion gives -2^31 for any
  out-of-range value. On the device (3.1.2, by analysis) the conversion saturates, so the second gives 2147483647
  (the first, below -2^31, gives -2147483648 on both). An emulator should follow the device; check on hardware.
- The exponent's digits also wrap in 32 bits: `3e2147483648` is 0.0 and `1e4294967297` is the integer 10.
- How the exponent is applied (measured in the Simulator; exact to the bit for all 4,730 numbers of
  `tests/probes/jsonexp`):
  - **with a fraction**, the single-precision mantissa (above) is multiplied, in single precision, by the float
    nearest to 10^e, which is 0 below 10^-45 and infinity above 10^38. About a third of such numbers are then not
    the float nearest to the decimal number: `1.2345e-7` is 0x34048DAE (nearest 0x34048DAD), `1.17549435e-38` is
    0x007FFFFF (nearest 0x00800000), `2.8e-45` is 0x00000003, and `1.5e-50` is 0. A double-precision product,
    `(float)(mantissa * 10.0^e)`, differs from the Simulator in about one case in five. `0.0e39` (0 times
    infinity) is a NaN, with bits 0xFFC00000;
  - **without a fraction**, the integer is multiplied in double precision by the double nearest to 10^e and the
    result rounded once to single precision: `1e-45` is the smallest subnormal (bits 0x00000001), `1e-46` is 0, and
    `1e39` is infinity. `0e400` is a NaN (0xFFC00000).
  - an exponent without digits counts as 0: `[1e]` gives the float 1.0 and `[1.5e]` 1.5.
- Leading zeros are accepted (`007`).
- `1.` and `.5` are errors, and so is `+` in an exponent (`1e+3`).

### Strings

- A `\u` escape below 0x100 becomes one raw byte: `\u00e9` is the Latin-1 byte 0xE9, not UTF-8.
- Larger values become 2- or 3-byte UTF-8.
- Surrogate pairs are not combined: each half is encoded on its own as 3 bytes.
- Ordinary escapes work: `"a\nb\u0041"` decodes to `a`, a newline, then `bA`.

### Errors

An invalid document returns `nil, "<message> at line <n>"`, with a 1-based line number:

- `json.decode("{bad")` returns `nil, "decode_table expected '\"' at line 1"`.
- Other messages include `expected "true"`, `bad number format` and `empty file`.

`json.decode` never raises a Lua error for bad input; a common mistake is to raise one.

**Silent failures:** a number or string that is still open when the input ends fails without a message.
`json.decode("12")` returns `nil, nil`, while `json.decode("12 ")` returns 12.

The probe `tests/probes/jsondec` holds the decode cases (numbers, strings, nesting, errors) and `tests/probes/jsonfmt`
the encode formats, `encodePretty`, cycles and decoded types; `tests/probes/jsonenc` holds the encode cases.

## C API

### Decoding: `json->decode` and `json->decodeString`

The C decoder follows the same parsing rules as Lua and reports the document through the `json_decoder` callbacks.

**Callback sequence.** Every table or array, including the root, gets:

1. `willDecodeSublist(decoder, name, type)`;
2. its values, in document order;
3. `didDecodeSublist(decoder, name, type)`, whose return value the parent then receives as the sublist's value.

The root's name is `_root`. A sublist inside a table is named by its key. A sublist inside an array is named
`parent[index]` with a 1-based index, but with the index's decimal digits reversed: element 13 of the root is
`_root[31]`. Single-digit indexes look normal (`_root[2]`). Games see this name, so an implementation should
reproduce it.

**Values.**

- A table member goes to `didDecodeTableValue(decoder, key, value)`, in document order.
- An array element goes to `didDecodeArrayValue(decoder, pos, value)`, with a 1-based `pos`.
- A sublist's value is delivered after its `didDecodeSublist`.
- `value.type` uses the SDK's `json_value_type` numbering: null 0, true 1, false 2, integer 3, float 4, string 5,
  array 6, table 7.

For example, decoding `{"a":1,"b":[2,3.5,"s"],"c":{"d":true},"e":null}` gives:

    willDecodeSublist(_root, table)
      didDecodeTableValue(a, integer 1)
      willDecodeSublist(b, array)
        didDecodeArrayValue(1, integer 2)
        didDecodeArrayValue(2, float 3.5)
        didDecodeArrayValue(3, string "s")
      didDecodeSublist(b, array)
      didDecodeTableValue(b, array)
      willDecodeSublist(c, table)
        didDecodeTableValue(d, true)
      didDecodeSublist(c, table)
      didDecodeTableValue(c, table)
      didDecodeTableValue(e, null)
    didDecodeSublist(_root, table)

and `[1,[2],{}]` gives `will(_root)`, `av(1)`, `will(_root[2])`, `av(1)`, `did(_root[2])`, `av(2)`,
`will(_root[3])`, `did(_root[3])`, `av(3)`, `did(_root)`. Arrays nested in arrays are delivered like any other
sublist.

**Filters.** `shouldDecodeTableValueForKey(decoder, key)` and `shouldDecodeArrayValueAtIndex(decoder, pos)`
returning 0 skip that value entirely: no value callback, and for a table or array no sublist callbacks either.
`{"a":1,"b":2,"c":3}` with "b" filtered out gives only `a` and `c`.

**Changing the decoder from a callback.** A callback may change the decoder's fields (for example `returnString`,
or the callback pointers). The change takes effect at once and is undone when the current sublist ends, so changes
made in `willDecodeSublist` apply to that sublist only.

**Errors.** Invalid JSON calls `decodeError(decoder, error, linenum)` with the message and the 1-based line number,
after the root's `willDecodeSublist`, and the decode returns 0. With an error at the top level, the path the
Simulator passes along with it is meaningless, so do not compare it.

**Bare values.** A document that is not a table or an array, such as `42`, returns 0 with no callbacks at all. It
must not crash.

**The reader.** `json->decode(decoder, reader, outval)` calls `reader.read(userdata, buf, bufsize)` on demand, with a
1,024-byte buffer, and parses as a stream. A large file (FactoryFarming decodes a 632 KB world) therefore needs
little memory; an implementation should not read the whole input into the game's heap, nor keep every string it has
passed to the game until the end.

`tests/probes/cjson` holds the C decode cases.

### Encoding: `json_encoder`

`json->initEncoder(&encoder, write, userdata, pretty)` makes a writer whose functions (`startArray`, `addArrayMember`,
`endArray`, `startTable`, `addTableMember`, `endTable`, `writeNull`, `writeFalse`, `writeTrue`, `writeInt`,
`writeDouble`, `writeString`) produce the same text as the Lua encoder:

- compact: `{"a":1,"b":[2,2.5,"q\"x"],"c":true,"d":false,"e":null}`;
- pretty: the same tab and colon rules as `encodePretty`:
  `{\n\t"a":1,\n\t"b": [\n\t\t2,\n\t\t2.5,\n\t\t"q\"x"\n\t],\n\t"c":true,\n\t"d":false,\n\t"e":null\n}`.

`writeDouble(2.5)` writes `2.5`, not `2.500000` (a `%f` format is a common mistake).
