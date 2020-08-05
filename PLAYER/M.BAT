@echo off
tasm play       -m8 -i. -i%TDLPATH%\INCLUDE
tasm load_mod   -m8 -i. -i%TDLPATH%\INCLUDE
tasm load_s3m   -m8 -i. -i%TDLPATH%\INCLUDE
tasm load_xm    -m8 -i. -i%TDLPATH%\INCLUDE
tasm modload    -m8 -i. -i%TDLPATH%\INCLUDE
tasm sb         -m8 -i. -i%TDLPATH%\INCLUDE
tasm player     -m8 -i. -i%TDLPATH%\INCLUDE

del player.lib
rem wlib player + player
rem wlib player + modload
rem wlib player + load_mod
rem wlib player + load_s3m
rem wlib player + load_xm
rem wlib player + load_it

wlib %TDLPATH%\lib\tdl.lib +- player
wlib %TDLPATH%\lib\tdl.lib +- modload
rem wlib %TDLPATH%\lib\tdl.lib +- load_mod
rem wlib %TDLPATH%\lib\tdl.lib +- load_s3m
wlib %TDLPATH%\lib\tdl.lib +- load_xm
wlib %TDLPATH%\lib\tdl.lib +- sb

rem %tdlpath%\player.lib
copy player.lib %tdlpath%\lib\player.lib
wlink @play.lnk
del *.obj
del *.bak


