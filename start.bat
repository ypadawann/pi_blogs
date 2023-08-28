@echo off

pushd %~dp0%

START /B /WAIT cmd /c "bundle exec ruby main.rb"

popd

ECHO +-------------------------------------------------------+
ECHO  Press Enter key to finish.
ECHO +-------------------------------------------------------+
PAUSE