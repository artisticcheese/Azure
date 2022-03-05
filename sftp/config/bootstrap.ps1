net use \\sftpgreg.file.core.windows.net\sftp zcifXclAm5y0fDotsBDO4V/dcIbJfNAQcpAe5jlKq42if/N+IDOrIs2TbcrrhPf9bWiFpQiiG1Hg+AStkAjKEg== /user:localhost\sftpgreg
net use \\sftpgreg.file.core.windows.net\sftpConfig zcifXclAm5y0fDotsBDO4V/dcIbJfNAQcpAe5jlKq42if/N+IDOrIs2TbcrrhPf9bWiFpQiiG1Hg+AStkAjKEg== /user:localhost\sftpgreg
new-item -ItemType SymbolicLink -Path c:\sftp -Target \\sftpgreg.file.core.windows.net\sftp
new-item -ItemType SymbolicLink -Path c:\config -Target \\sftpgreg.file.core.windows.net\sftpConfig