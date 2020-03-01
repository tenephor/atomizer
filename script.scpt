on CreateFileList()
	set fileList to {}
	set tempFList to {}
	try
		repeat with aPath in myPathList
			set foundPaths to (do shell script "/usr/bin/find " & quoted form of aPath & " -type f -iname '*.m4v' -or -iname '*.mp4' 2>/dev/null")
			set tempFList to paragraphs of foundPaths
			repeat with thisFile in tempFList
				set the end of fileList to {thisFile as string, text ((length of aPath) + 2) thru -1 of thisFile as string, aPath as string}
			end repeat
		end repeat
	on error errorMsg number errorNum -- there was an error with find (permissions, etc)
		display dialog "Error. Could not build list of files. " & errorMsg & errorNum buttons {"OK"}
		tell me to quit
	end try
	return fileListTrine
end CreateFileList
