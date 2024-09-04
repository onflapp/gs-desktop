Environment loadModule:'SystemShell'.

Shell executeCommand:'powerprofilesctl' withArguments:#('set' 'power-saver').
Shell executeCommand:'nxdisplay' withArguments:#('--set' '20').

NotMon showPanelWithTitle:'Change Mode' info:'power saver' delay:1
