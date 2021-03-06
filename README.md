# Atomizer ![logo](Icon-small.png)

This is an Applescript script that parses metadata atoms from .m4v and .mp4 encoded video files.
Obviously, it only runs under OSX.

It is offered as proof-of-concept. Delightfully useless yet deliciously alluring. This basic algorithm could be extended or re-tooled for a variety of needs.

This script has nothing to do with the hackable text editor named Atom.

## What It Does:

1. The script allows the user to choose one or more paths (folders).
2. The script then examines those folders for all .mp4 and .m4v video files
3. Each video file in those folders is scanned for its atomic meta data
4. The meta data is harvested and saved into a .csv file, one row per video file.

An example of .csv output (only a few columns shown):

![output](output.png)

## The Atomic Meta Data Harvested:
Atoms are returned if found. For any atom not found "NF" is returned in its place.

#### The Video Type atom (stik)
This atom is integer coded in the video file. A string is returned by the script based on the numeric value found:
- 0 or 9: returns "Movie"
- 10: returns "TV Show"
- 6: returns "Music Video"

For any other (non-video) values the integer is returned as-is.

#### The Name Atom (©nam)
The name of the movie or show. This atom is string coded in the video file. The string is returned but any quotes contained are re-coded (changed from " to "") for CSV

#### The Tool Atom (©too)
The tool that created the file (if present). e.g., *Handbrake 0.9.5*. This atom is string coded in the video file. The string is returned but any quotes contained are re-coded (changed from " to "") for CSV

#### The Description Atom (desc)
The short (summary) description of the video. This atom is string coded in the video file. The string is returned but any quotes contained are re-coded (changed from " to "") for CSV. Any carriage returns in the string are replaced with "CR" for CSV compliance. Note that with an easy change to the script these could simply be removed as well.

#### The (pre-defined) Genre atom (gnre)
The genre of the video. This atom is integer coded in the video file. A string is returned by the script based on the numeric value found:
- 58: returns "Comedy"

58 is the only pre-defined value in the list that anyone might use for a video, the other values deal with music, ie "Techno". For all other values the integer is returned as part of the string: "ID3 Code=*n*"

#### The (user-defined) Genre atom (©gen)
The genre of the video. This atom is string coded in the video file. The string is returned as-is.

Only one of the two previous genre atoms is returned. If the user-defined atom is found its value supercedes (replaces) any pre-defined genre atom found. Most genre atoms found are user-defined.

#### The Artist (Actors) Atom (©art)
The actors in the video. These are typically placed in the *artist* atom. This atom is string coded in the video file. The string is returned as-is.

#### The Date Atom (©day)
The video's year of release, returned as string in format YYYY. For example, Star Wars would be "1977". The 4-digit year of the video is pulled from this string-coded atom. The date might be stored in the video file as YYYY-MM-DD, or that with time too.

#### The Long Description Atom (ldes)
The long description of the video. This can be a long page of text if the video's creator liked to paste summaries from Wikipedia. This atom is string coded in the video file. The string is returned but any quotes contained are re-coded (changed from " to "") for CSV. Some software writes sloppy tags, ie carriage returns or html in the description fields. Any carriage returns in the string are replaced with "CR" for CSV compliance. Note that with an easy change to the script these could simply be removed as well.

#### The Sort-Name Atom (sonm)
The sort-name for the video. Movie library apps typically use this atom to sort the titles in a GUI. This allows sequels to be shown adjacent to prequels in lists. e.g., *Silence of the Lambs* and *Hannibal* could have SOTL1 and SOTL2 set as sort names respectively. It is also used to remove "The.." so that "The Prestige" with a sort-name of "Prestige" is shown alphabetically under P in a GUI, not under T. This atom is string coded in the video file. The string is returned as-is.

#### The TV Show Name (tvsh)
This atom is string coded in the video file. It often contains the same value as the Name atom. The string is returned but any quotes contained are re-coded (changed from " to "") for CSV.

#### The TV Episode ID (tven)
This atom is string coded in the video file. It is usually the name of the specific episode. For standalone (non-episodic) TV shows, it's often just a copy of the Name and/or TV Show Name atoms, but could be any string. The string is returned

#### The TV Show Season Number (tvsn)
This atom is integer coded in the video file. It is usually a number like 3. The number is returned. A value is rather irrelevant for files of type *Movie*, but any value found is returned regardless.

#### The TV Show Episode Number (tves)
This atom is integer coded in the video file. It is usually a number like 5. The number is returned. A value is rather irrelevant for files of type *Movie*, but any value found is returned regardless.

#### The Artwork Atom (covr)
This atom is tested for existence. If it exists, then the video file is assumed to contain "cover art". In this case "Yes" is returned. The script does not extract binary artwork from the video file.

#### The Comment Atom (©cmt)
This atom holds comments, often a field offered by library GUI apps. It's content could be anything from "I watched this in Jan 2002" to a copy of the Description. It all depends on the app that created the atom and the user.
The string is returned but any quotes contained are re-coded (changed from " to "") for CSV. 

#### Rating Atom (iTunEXTC)
This is an iTunes-created atom. It is a string that denotes the rating. e.g., PG13. The rating substring is pulled from the atom and returned as is.

## How to Use:
1. Download then run the script under OSX.
2. From the main menu, select Add or Change Path(s): select one or more folders containing video encodes (.m4v and/or .mp4 files)
3. Go back to the main menu and select "Dump Atoms". A .csv will be written into the same folder as the script. It might take a few minutes depending on how many video files are parsed.
4. Use OSX's Script Editor to examine and/or modify the script

## Accuracy
There are countless applications, current and obsolete, that allow writing metadata to video files. iTunes was a popular one. Subler was another. There are countless applications, current and obsolete, that *automatically* write metadata to video files. MetaX and MetaZ are two examples. The quality and accuracy of metadata read from any video file is largely dependent on the quality of the app writing it, and decisions of the person using the app. Some apps, like iTunes, would mostly use standard atoms, but also create its own atoms in its own custom-created XML space within the file. Sometimes there will be off-plane characters in an atom because an app wasn't diligent enough to filter them out before writing. Often people would misuse atoms for the wrong purpose. The bottom line here is, tagging has never been an excercise in consistency, at least not from user to user. Notice in the output example above that the standalone television special *Frosty the Snowman* had been, for some reason, tagged with a season number and episode number! This script reads whatever is in the file, right or wrong, it does not correct or assume. Bullshit in = bullshit out.

## Taking it Further:
Apple's script editor can package the script as an application.

## Further Reading:
There are many atoms the script currently ignores. For more info, see 
- https://www.adobe.com/devnet/video/articles/mp4_movie_atom.html
- http://code.google.com/p/mp4v2/wiki/iTunesMetadata
