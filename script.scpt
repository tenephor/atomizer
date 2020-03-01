

--ATOMIZER GPL v3 DJL 2020

property version : "4.3"
--The following line is the only line need be changed when adding new users.
property cr : ASCII character 13
global myPathList

------------------------------------------

on run {}
	set allSetThisSession to false
	--set keepAlive to true
	try
		get myPathList
		if myPathList is equal to {} then set myPathList to PromptForPath({})
	on error
		set myPathList to PromptForPath({})
	end try
	if myPathList is not equal to {} then
		Main()
	else
		tell me to quit
	end if
	
end run

------------------------------------------

on Main()
	set Choices to {"Dump Atoms", "Change Path(s)"}
	set Choice to (choose from list Choices with title ("Atomizer v" & version) cancel button name "Quit" OK button name "Do" with prompt "Choose an action…") as string
	if Choice is equal to "Dump Atoms" then
		dumpAtoms()
	else if Choice is equal to "Change Path(s)" then
		set myPathList to PromptForPath(myPathList)
	end if
	if Choice is equal to "false" then --"quit" button returns not a boolean but a string: "false"!
		tell me to quit
		return
	else
		Main()
	end if
end Main

------------------------------------------

on dumpAtoms()
	
	display dialog "Scanning and dumping your movie atoms. You will be notified when done." buttons {"OK"} giving up after 5
	if WriteAtomFile(CreateAtomList(CreateFileList())) = true then
		set success to true
	else
		set success to false
	end if
	if success is true then
		display dialog "Completed dumping your atoms." buttons {"OK"}
	else
		display dialog "ERROR: Could not dump your atoms." buttons {"OK"}
	end if
	return true
end dumpAtoms

------------------------------------------

on PromptForPath(currentPaths)
	set cleanList to {}
	if currentPaths is equal to {} then set currentPaths to currentPaths & ChoosePath()
	if currentPaths is equal to {} then
		return {}
	end if
	set pathsChoice to (choose from list currentPaths with title "My Path(s)" with prompt "No selection to add a path, or select any path to remove it." cancel button name "Back to Main screen" OK button name "Add/Remove" with empty selection allowed)
	if pathsChoice is equal to {} then --no selection, add a path
		set currentPaths to currentPaths & ChoosePath()
		set currentPaths to PromptForPath(currentPaths)
	else if pathsChoice is false then --"back to main" selected
		if the (count of items in currentPaths) is equal to 0 then
			display dialog "You need at least one path." buttons {"OK"}
			set currentPaths to PromptForPath(currentPaths)
		end if
	else --delete a path
		repeat with i from 1 to count currentPaths
			if currentPaths's item i is not equal to item 1 of pathsChoice then set cleanList's end to currentPaths's item i
		end repeat
		set currentPaths to cleanList
		set cleanList to {} --Gotcha!
		set currentPaths to PromptForPath(currentPaths)
	end if
	return currentPaths
end PromptForPath

------------------------------------------

on ChoosePath()
	try
		set thisPath to choose folder with prompt "Select a path to add…"
		return text 1 thru -2 of POSIX path of thisPath
	on error
		return {}
	end try
end ChoosePath

------------------------------------------

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
	return fileList
end CreateFileList

------------------------------------------

on CreateAtomList(fileList)
	set atomList to {}
	repeat with x from 1 to count (fileList)
		set atomRow to ReadAtomsFromFile(item x of fileList)
		copy atomRow to end of atomList
	end repeat
	return atomList
end CreateAtomList

------------------------------------------

on GetIndexPathAndFileName()
	set oldDelimiters to text item delimiters
	set text item delimiters to "/"
	set thisScriptPath to text items of POSIX path of (path to me)
	set thisScriptPath to items 1 thru -2 of thisScriptPath
	set myIndexFile to (thisScriptPath as string) & "/" & "atoms.csv"
	set text item delimiters to oldDelimiters
	return myIndexFile
end GetIndexPathAndFileName

------------------------------------------

on WriteAtomFile(atomList)
	set writeFile to GetIndexPathAndFileName()
	try
		set writeFileRef to open for access writeFile with write permission
		set eof of writeFileRef to 0 --overwrite
	on error errorMsg number errorNum
		display dialog "ERROR. Could not create an atom update file." & cr & errorMsg & cr & errorNum buttons {"OK"}
		close access writeFileRef
		tell me to quit
	end try
	set oldDelimiters to text item delimiters
	set text item delimiters to quote & "," & quote
	set headerLine to text items of ColumnHeaders()
	write version & cr to writeFileRef as «class utf8»
	write quote & headerLine & quote & cr to writeFileRef as «class utf8»
	repeat with thisAtomRow in atomList
		set thisLine to thisAtomRow as string
		write quote & thisLine & quote & cr to writeFileRef as «class utf8»
	end repeat
	set text item delimiters to oldDelimiters
	close access writeFileRef
	return true
end WriteAtomFile

------------------------------------------

on ReadAtomsFromFile(fileList)
	
	set atomRow to setAtomDefaults()
	set oldDelimiters to text item delimiters
	set text item delimiters to "|" --this is needed for getting the Rating (atomRow 19)
	
	set thisFile to item 1 of fileList -- use for script-internal reading of atoms
	set thisFileRelPath to item 2 of fileList -- add to data for crate update use
	set thisFileRootPath to item 3 of fileList -- add to data for crate update use
	
	set readFileRef to open for access thisFile --opens for read only
	set start to 1
	
	try -- Recursively read all the atomic metadata from the current file into the variables:
		repeat
			--Read the first or next atom:
			set atomlength to read readFileRef from start for 4 as unsigned integer
			set atomName to read readFileRef from start + 4 for 4 as string
			if atomlength = 1 then
				set atomlength to read readFileRef from start + 8 for 8 as double integer
			end if
			
			--If it's an atom we want, assign the data to the atomRow list:
			if atomName = "stik" then
				set Stik to read readFileRef from (start + 21) for 4 as unsigned integer --make use of 3 null spaces to read a whole integer
				if Stik = 0 or Stik = 9 then
					set item 1 of atomRow to "Movie"
				else if Stik = 10 then
					set item 1 of atomRow to "TVShow"
				else if Stik = 6 then
					set item 1 of atomRow to "MusicVideo"
				else
					set item 1 of atomRow to Stik
				end if
			end if
			
			if atomName = "©nam" then set item 2 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8»)
			if atomName = "©too" then set item 6 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8»)
			if atomName = "desc" then set item 7 of atomRow to ParseQuotes(ParseCRs(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8»))
			
			if atomName = "gnre" then -- Genre atom is a pre-defined ID3 spec number (+1)
				set Gnre to read readFileRef from (start + 22) for 4 as unsigned integer --pre-defined genre. See note 2.
				if Gnre = 58 then --"Comedy" Is only pre-defined in the list I can see that anyone could use for a video, the rest deal with music, ie "Techno"
					set item 8 of atomRow to "Comedy"
				else
					set item 8 of atomRow to "ID3 Code=" & Gnre & "*"
				end if
			end if
			
			if atomName = "©gen" then set item 8 of atomRow to read readFileRef from (start + 24) for (atomlength - 24) as «class utf8» --user defined genre. See note 2.
			if atomName = "©art" then set item 9 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8») --actors (artist)
			if atomName = "©day" then set item 10 of atomRow to ParseQuotes(read readFileRef from (start + 24) for 4 as «class utf8») --only take 4 digit year. See note 3.
			if atomName = "ldes" then set item 11 of atomRow to ParseQuotes(ParseCRs(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8»))
			
			
			
			if atomName = "sonm" then set item 12 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8»)
			if atomName = "tvsh" then set item 13 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8») --TV Show Name
			if atomName = "tven" then set item 14 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8») --epsiode ID
			if atomName = "tvsn" then set item 15 of atomRow to read readFileRef from (start + 24) for 4 as unsigned integer --TVShow Season
			if atomName = "tves" then set item 16 of atomRow to read readFileRef from (start + 24) for 4 as unsigned integer --TVShow episode number
			if atomName = "covr" then set item 17 of atomRow to "Yes" --Artwork
			if atomName = "©cmt" then set item 18 of atomRow to ParseQuotes(read readFileRef from (start + 24) for (atomlength - 24) as «class utf8»)
			
			if atomName = "----" then
				set meanLength to read readFileRef from (start + 8) for 4 as unsigned integer
				set Mean to read readFileRef from (start + 20) for (meanLength - 12) as «class utf8»
				if Mean is equal to "com.apple.iTunes" then
					set nameLength to read readFileRef from (start + 36) for 4 as unsigned integer
					set theName to read readFileRef from (start + 48) for (nameLength - 12) as «class utf8»
					if theName is equal to "iTunEXTC" then
						set ratingLength to read readFileRef from (start + 56) for 4 as unsigned integer
						set ratingTag to read readFileRef from (start + 72) for (ratingLength - 16) as «class utf8»
						set text item delimiters to "|"
						set atomItems to text items of ratingTag
						try
							set item 20 of atomRow to item 2 of atomItems as «class utf8»
						end try
					end if
				end if
			end if
			
			if atomName = "trak" then
				if (read readFileRef from start + 12 for 4 as string) is "tkhd" then
					set candidateWidth to read readFileRef from (start + 92) for 2 as small integer --width of encode in pixels, 2 bytes
					if candidateWidth is not equal to 0 then
						set item 21 of atomRow to (candidateWidth as string) & "x" & ((read readFileRef from (start + 96) for 2 as small integer) as string) --add height of encode in pixels, 2 bytes
					end if
					
				end if
			end if
			--Note: The Track Header atom always seems to come right after the "Trak" atom. 
			--		This tendency is relied on above to avoid having to drill into Trak, which
			--		makes the script take eons to work.
			
			--Move to the next atom, or drill into the current atom:
			if atomName is "moov" or atomName is "udta" or atomName is "ilst" then --drill
				set start to start + 8
			else if atomName is "meta" then --drill
				set start to start + 12
			else
				set start to start + atomlength --skip
			end if
		end repeat
		
	on error errorString number errorNumber
		if errorNumber = -39 then --reached EOF
			close access readFileRef
		else
			display dialog "ERROR. Could not read " & thisFile & cr & "Atom: " & atomName & cr & errorString & errorNumber
			close access readFileRef
			tell me to quit
		end if
	end try
	
	--CLOSEOUT ACTIONS:
	set text item delimiters to oldDelimiters
	
	set theFileSize to ((the size of (info for thisFile)) / 1000000)
	set theFileSize to round theFileSize
	set theFileSize to (theFileSize / 1000)
	
	--set the file size data:
	if length of (theFileSize as string) < 5 then
		set item 19 of atomRow to ((theFileSize as string) as «class utf8») --file size
	else
		set item 19 of atomRow to (text 1 thru 5 of (theFileSize as string)) as «class utf8»
	end if
	
	
	--set the file path data:
	set item 3 of atomRow to thisFileRootPath --Path, root location selected
	set item 4 of atomRow to thisFileRelPath --file name with relative path from root path selection
	
	--set the file mod date data:
	set item 5 of atomRow to the modification date of (info for thisFile) as string --mod date
	
	--overwrite all TV related atoms if this is a Movie:
	if item 1 of atomRow = "Movie" or item 1 of atomRow = "MusicVideo" then
		set item 13 of atomRow to "-" --show name
		set item 14 of atomRow to "-" --episode ID
		set item 15 of atomRow to "-" --season
		set item 16 of atomRow to "-" --ep num
	end if
	
	return atomRow
end ReadAtomsFromFile

------------------------------------------

on setAtomDefaults()
	set defaultAtomRow to {}
	set ColumnHeaders to ColumnHeaders()
	repeat with x from 1 to count ColumnHeaders
		copy "NF" to end of defaultAtomRow
	end repeat
	--set item 1 of defaultAtomRow to "NF" --stik (type)
	--set item 2 of defaultAtomRow to "NF" --name
	-- item 3 is file meta: root path location
	-- item 4 is file meta: file name with relative path
	-- item 5 is file meta: mod date
	set item 6 of defaultAtomRow to "NF" --tool used to create this file
	set item 7 of defaultAtomRow to "NF" --The short description
	set item 8 of defaultAtomRow to "NF" --Genre (either internal or custom)
	set item 9 of defaultAtomRow to "NF" --if no Actors (artists) Found. See note 9.
	set item 10 of defaultAtomRow to "NF" --Year
	set item 11 of defaultAtomRow to "NF" --Long description
	set item 12 of defaultAtomRow to "NF" --Sort Name
	set item 13 of defaultAtomRow to "NF" --TVShow name
	set item 14 of defaultAtomRow to "NF" --Episode ID, Note this will be changed to "-" for a movie or music vid
	set item 15 of defaultAtomRow to "NF" --Season,  Note this will be changed to "-" for a movie or music vid
	set item 16 of defaultAtomRow to "NF" --Episode Number, Note this will be changed to "-" for a movie or music vid
	set item 17 of defaultAtomRow to "NF" --Artwork, yes or no
	set item 18 of defaultAtomRow to "NF" --Comment
	-- item 19 is the file size
	set item 20 of defaultAtomRow to "NF" --R ating
	set item 21 of defaultAtomRow to "THNF" --dimensions, "Track Header atom Not First", meaning it was not the first atom after "Trak" see note above.
	return defaultAtomRow
end setAtomDefaults

------------------------------------------

on ParseQuotes(atomData) --this function will change " to "" within atom data (for CSV compliance)
	if atomData = "" then return "<empty tag>" --see note 6.
	set oldDelimiters to text item delimiters
	set text item delimiters to "\"" --an ascii quote is the same byte as a unicode quote
	set textItems to text items of atomData
	set text item delimiters to "\"\""
	tell textItems to set textItems to item 1 & ({""} & rest)
	return textItems
end ParseQuotes

------------------------------------------

on ParseCRs(atomData) --this function will change carriage returns to (CR) within atom data (for CSV compliance)
	set oldDelimiters to text item delimiters
	set text item delimiters to cr --a carriage return
	set textItems to text items of atomData
	set text item delimiters to "(CR)"
	tell textItems to set textItems to item 1 & ({""} & rest)
	return textItems
end ParseCRs

------------------------------------------

on ColumnHeaders()
	set ColHeads to {}
	copy "Type" to end of ColHeads --1
	copy "Name" to end of ColHeads --2
	copy "Path" to end of ColHeads --3
	copy "FileName" to end of ColHeads --4
	copy "ModDate" to end of ColHeads --5
	copy "Tool" to end of ColHeads --6
	copy "Desc" to end of ColHeads --7
	copy "Genre" to end of ColHeads --8
	copy "Actors" to end of ColHeads --9
	copy "Year" to end of ColHeads --10
	copy "Long Desc" to end of ColHeads --11
	copy "SortName" to end of ColHeads --12
	copy "ShowName" to end of ColHeads --13
	copy "Ep.ID" to end of ColHeads --14
	copy "Season" to end of ColHeads --15
	copy "Ep.Num" to end of ColHeads --16
	copy "Art" to end of ColHeads --17
	copy "Comment" to end of ColHeads --18
	copy "Size" to end of ColHeads --19
	copy "Rating" to end of ColHeads --20
	copy "Dimensions" to end of ColHeads --21
	return ColHeads
end ColumnHeaders

------------------------------------------

(*
NOTES:
1. If a video has no sort name set, there will probably be no atom for it in the mpeg4. iTunes will still show the show's title in the sort box
2. A video will either have a pre-defined genre or a user defined genre. This script will find either but favor a user defined.
3. Careful, The year is might be stored as YYYY-MM-DD, or all that with Time too.
4. 
5. Some software writes sloppy tags, ie carriage returns or html in the description fields. What a hassle.
6. Some software apparently creates un-needed tags. ie a TV Show Name tag might be found in a movie.
7. There are many more atoms we ignore. For more possible atoms, see http://code.google.com/p/mp4v2/wiki/iTunesMetadata
8. Some long descriptions are the length of a small fucking book. seriously.
9. Actors are often listed in the "Artist" atom/Get Info of the encode. Those do not matter, the ones that matter are in an Apple XML section of the encode.
10. If you write anything to the file with quotes, double quotes are required for a CSV which uses enclosure quotes, use -->  \"\"
*)
