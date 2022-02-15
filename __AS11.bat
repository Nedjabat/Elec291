@echo off
C:
cd "\Users\Louise Baldry\Documents\GitHub\Elec291\"
if exist Project 1 capacitor.lst del Project 1 capacitor.lst
if exist Project 1 capacitor.s19 del Project 1 capacitor.s19
if exist __err.txt del __err.txt
"C:\uni\3rd year\ELEC 291\CrossIDE\Call51\Bin\a51.exe"  Project 1 capacitor.asm > __err.txt
"C:\uni\3rd year\ELEC 291\CrossIDE\Call51\Bin\a51.exe"  Project 1 capacitor.asm -l > Project 1 capacitor.lst
if not exist s2mif.exe goto done
if exist Project 1 capacitor.s19 s2mif Project 1 capacitor.s19 Project 1 capacitor.mif > nul
:done
