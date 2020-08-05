@echo off
tasm test /i. /i%TDLPATH%\include /m6 /zi
wlink system darkx debug all lib %tdlpath%\lib\tdl.lib file test
