**UPDATE (June 2018)** -- this project no longer maintained. [BotWikiAwk](https://github.com/greencardamom/BotWikiAwk) is a newer project that includes expanded libraries and tools. Library functions are in library.awk and updated JSON functions are in json.awk


MediaWiki Awk API
===========================
by User:Green Cardamom at en.wikipedia.org
May 2015 (1.0)
MIT license

A library of functions in GNU Awk for accessing the MediaWiki API.
For building applications in Awk that use the MediaWiki API.
Supports read/download API functions only, not write.

There are 2 library files and 1 example program (backlinks.awk).

Library files
=============

mwapi.awk

	The API and other functions for building Wikipedia bots and scripts.

json2var.awk

	Json parser. Given a json file, return a single variable with the values needed.
	Depending on the API call, you'll customize a couple lines in parse_value() to 
	extract the fields you want.


Demonstration program
=====================

backlinks.awk

	This shows all the backlinks (ie. "Special:What Links Here") for a page. 
	It also shows how to use the "continue" command to load > 500 items.

	To run:

		awk -bE backlinks.awk

A complete application, "Backlinks Watchlist" is at
	https://github.com/greencardamom/Backlinks-Watchlist


Other awk based tools
=====================

Wikiget
	https://github.com/greencardamom/Wikiget

WebArchiveMerge
	https://github.com/greencardamom/WebArchiveMerge

WaybackMedic (version 0 is pure awk, 1+ is awk + nim)
	https://github.com/greencardamom/WaybackMedic

PG2WP
	https://github.com/greencardamom/PG2WP

