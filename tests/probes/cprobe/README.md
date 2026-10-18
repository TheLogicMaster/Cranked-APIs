# cprobe

C API cases across system, display, files, graphics, tilemap, video, sprites, JSON, sound, network and scoreboards.

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- Not included (supply it to build the probe): video/appear_frames.pdv, copied from the SDK's Disk/System/Launcher.pdx/video/appear/.
- `drive.py sim <cprobe.pdx> <out.txt>` or `drive.py emu <cprobe.pdx> <out.txt> <runner>` (the emulator runner binary is required for emu) runs the probe repeatedly, skipping a case that stops the program (listed in skipc.txt in the data folder), until every case has a line.
- In the Simulator two cases stop the program and have no line in expected/sim_outc.txt: t_sprite_query_all_overlapping (segmentation fault) and t2_sound_misc (abort).
- Output: outc.txt in the data folder, one "name<TAB>result" line per case.
