Environment loadModule:'SystemShell'.

Shell executeCommand:'powerprofilesctl' withArguments:#('set' 'performance').

NotMon showPanelWithTitle:'Change Mode' info:'performance' delay:1