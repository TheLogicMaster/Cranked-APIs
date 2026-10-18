// Probe cases: printf-style formatting through the C API (formatString and logToConsole)
#define CASES(X) \
  X("%d|%i|%u|%x|%X|%o", -5, 7, 4000000000u, 0xbeef, 0xbeef, 8) \
  X("%hhd|%hd|%hhu|%hu", 300, 70000, 300, 70000) \
  X("%lld|%llu|%llx", -1234567890123LL, 18000000000000000000ULL, 0x123456789abcLL) \
  X("%f|%.3f|%e|%g|%10.2f|%-8.1f|", 3.14159, 2.5, 12345.678, 0.0001, -1.005, 7.25) \
  X("%s|%.3s|%10s|%-6s|", "hello", "abcdef", "right", "left") \
  X("%c%c%c|%5c|", 'a', 'b', 'c', 'z') \
  X("%*d|", 6, 42) \
  X("%-*d|", 6, 42) \
  X("%.*f|", 2, 3.14159) \
  X("%.*s|", 2, "xyz") \
  X("%*d|%-*d|%.*f|%.*s|", 6, 42, 6, 42, 2, 3.14159, 2, "xyz") \
  X("%d %f %d %f %d %f %d %f", 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5) \
  X("%d %d %d %d %d %d %d %d %d %d", 1, 2, 3, 4, 5, 6, 7, 8, 9, 10) \
  X("%lld %d %lld %d", 1LL, 2, 3LL, 4) \
  X("%%|%+d|% d|%#x|%#o|%05d", 5, 5, 255, 8, 42)
