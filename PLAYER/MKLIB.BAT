@echo off
del player.lib
wlib player + player
wlib player + modload
wlib player + load_mod
wlib player + load_s3m
wlib player + load_xm
wlib player + sb
del %tdlpath%\player.lib
copy player.lib %tdlpath%\player.lib
