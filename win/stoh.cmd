@echo off
setlocal
set PYTHONUNBUFFERED=1
uv run "%~dp0stoh.py" %*
