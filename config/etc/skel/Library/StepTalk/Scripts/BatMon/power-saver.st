Environment loadModule:'SystemShell'.

Shell executeCommand:'powerprofilesctl' withArguments:#('set' 'power-saver').

NotMon showPanelWithTitle:'Change Mode' info:'power saver' delay:1