Environment loadModule:'SystemShell'.

Shell executeCommand:'powerprofilesctl' withArguments:#('set' 'performance').
Shell executeCommand:'nxdisplay' withArguments:#('--set' '100').

NotMon showPanelWithTitle:'Change Mode' info:'performance' delay:1
