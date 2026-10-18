# fmtq

printf-style formatting through the C API, compared with the host's snprintf (cases.h).

Language: C. Build: `make` (with PLAYDATE_SDK_PATH set).

Notes:

- expected/ref.txt is not a Simulator run: it is the host C library reference, made with `gcc -w -o ref ref.c && ./ref > ref.txt`. The probe prints matching "fmtq"/"fmtl" lines to the console.
