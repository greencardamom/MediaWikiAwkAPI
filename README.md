MediaWiki Awk API
===========================
by User:Green Cardamom at en.wikipedia.org
May 2015 (1.0)
MIT license

A library of functions in GNU Awk for accessing the MediaWiki API.
For building applications in Awk that use the MediaWiki API.
Supports read/download API functions only, not write.

There are 3 library files and 1 example program (backlinks.awk).

Library files
=============

http2var.awk 

	Networking code. Loads a web page to a string variable.

json2var.awk

	Json parser. Given a json file, return a single variable with the values needed.
	Depending on the API call, customize a couple lines in parse_value() to extract the 
	fields you want.

mwapiutils.awk

	General utility functions. 
	Most with generic application, not just for MediaWiki API.


Demonstration program
=====================

backlinks.awk

	This shows all the backlinks (ie. "Special:What Links Here") for a page. 
	It also shows how to use the "continue" command to load > 500 items.

	To run:

		awk -f backlinks.awk

A complete application, "Backlinks Watchlist" is at
	https://github.com/greencardamom/Backlinks-Watchlist
