@echo off
rem -- Run Vim --

setlocal
set NVIM_HOME=C:\Users\Jonas\AppData\Local\Neovim
set VIM_EXE_DIR=%NVIM_HOME%\bin
start "dummy" /b "%VIM_EXE_DIR%\nvim-qt.exe" %*
