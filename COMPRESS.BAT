@echo off

@echo Deleting OBJ files...
del /y objs

@echo Deleting LIB files...
del /y lib

@if "%1"=="diskette" goto compress_multivolume
@echo.
@echo Compressing TDL into one solid archive...
rar a -r tdl
@echo.
@echo TDL compressed into TDL.RAR
@goto compress_end

:compress_multivolume
@echo.
@echo Compressing TDL into multiple 1.44Mb volumes...
rar a -r -v1457664b tdl
@echo.
@echo TDL compressed into TDL.R* file/s

:compress_end
