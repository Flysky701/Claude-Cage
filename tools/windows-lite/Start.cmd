@echo off
setlocal
python -B "%~dp0shell.py" %*
set rc=%errorlevel%
if not %rc%==0 pause
exit /b %rc%
