# Synthetic pointer clicks and key presses through XTest (ctypes), for driving the Simulator's UI
import ctypes, sys, time
x11 = ctypes.CDLL('libX11.so.6'); xt = ctypes.CDLL('libXtst.so.6')
x11.XOpenDisplay.restype = ctypes.c_void_p
dpy = ctypes.c_void_p(x11.XOpenDisplay(None))
x11.XStringToKeysym.restype = ctypes.c_ulong
def flush(): x11.XFlush(dpy)
def move(x, y): xt.XTestFakeMotionEvent(dpy, -1, x, y, 0); flush(); time.sleep(0.05)
def click(x, y, n=1):
    move(x, y)
    for _ in range(n):
        xt.XTestFakeButtonEvent(dpy, 1, 1, 0); flush(); time.sleep(0.03)
        xt.XTestFakeButtonEvent(dpy, 1, 0, 0); flush(); time.sleep(0.05)
def key(name):
    code = x11.XKeysymToKeycode(dpy, ctypes.c_ulong(x11.XStringToKeysym(name.encode())))
    xt.XTestFakeKeyEvent(dpy, code, 1, 0); flush(); time.sleep(0.03)
    xt.XTestFakeKeyEvent(dpy, code, 0, 0); flush(); time.sleep(0.03)
names = {'-': 'minus', '.': 'period'}
for cmd in sys.argv[1:]:
    op, _, arg = cmd.partition(':')
    if op == 'click': x, y = map(int, arg.split(',')); click(x, y)
    elif op == 'tripleclick': x, y = map(int, arg.split(',')); click(x, y, 3)
    elif op == 'type':
        for ch in arg: key(names.get(ch, ch))
    elif op == 'key': key(arg)
    elif op == 'drag':
        x0, y0, x1, y1 = map(int, arg.split(','))
        move(x0, y0); xt.XTestFakeButtonEvent(dpy, 1, 1, 0); flush(); time.sleep(0.1)
        for k in range(1, 11): move(x0 + (x1 - x0) * k // 10, y0 + (y1 - y0) * k // 10)
        xt.XTestFakeButtonEvent(dpy, 1, 0, 0); flush(); time.sleep(0.1)
    elif op == 'sleep': time.sleep(float(arg))
print('done')
