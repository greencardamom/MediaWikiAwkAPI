#!/bin/awk -bE

# backlinks.awk
#  -- demonstration program of the MediaWiki Awk API Library.
#
#  Prints the full list of backlinks such as seen at "Special:What Links Here"
#   * Uses the "continue" API command (not limited by 500 results).
#   * Includes (transcluded) pages for Template: types, and (file) pages for File: types
#   * Includes second-level backlinks (from redirects)
#

@include "json2var.awk"
@include "mwapi.awk"

BEGIN {

	entity = "Template:Librivox author"

        Agent = "Backlinks.awk - YourContactInfo"

        Maxlag = 5

	if ( entity_exists(entity) ) {
	    if ( ! backlinks(entity) ) 
                print "No backlinks for " entity
        }

        exit
}

function backlinks(entity,	url, blinks) {

        
        url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" urlencodeawk(entity) "&blredirect&bllimit=250&continue=" urlencodeawk("-||") "&blfilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag
        blinks = getbacklinks(url, entity, "blcontinue") # normal backlinks

        if ( entity ~ "^Template:") {    # transclusion backlinks
            url = "http://en.wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" urlencodeawk(entity) "&continue=" urlencodeawk("-||") "&eilimit=500&format=json&utf8=1&maxlag=" Maxlag
            blinks = blinks "\n" getbacklinks(url, entity, "eicontinue")
        } else if ( entity ~ "^File:") { # file backlinks
            url = "http://en.wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" urlencodeawk(entity) "&iuredirect&iulimit=250&continue=" urlencodeawk("-||") "&iufilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag
            blinks = blinks "\n" getbacklinks(url, entity, "iucontinue")
        }

        blinks = uniq(blinks)
        if ( length(blinks) > 0) print blinks 
        return length(blinks)

}

function getbacklinks(url, entity, method,      jsonin, jsonout, continuecode) {

        jsonin = http2var(url)
        if(apierror(jsonin, "json") > 0)
          return ""
        jsonout = json2var(jsonin)
        continuecode = getcontinue(jsonin, method)

        while ( continuecode ) {

            if ( method == "eicontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" urlencodeawk(entity) "&eilimit=500&continue=" urlencodeawk("-||") "&eicontinue=" urlencodeawk(continuecode) "&format=json&utf8=1&maxlag=" Maxlag
            if ( method == "iucontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" urlencodeawk(entity) "&iuredirect&iulimit=250&continue=" urlencodeawk("-||") "&iucontinue=" urlencodeawk(continuecode) "&iufilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag
            if ( method == "blcontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" urlencodeawk(entity) "&blredirect&bllimit=250&continue=" urlencodeawk("-||") "&blcontinue=" urlencodeawk(continuecode) "&blfilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag

            jsonin = http2var(url)
            jsonout = jsonout "\n" json2var(jsonin)
            continuecode = getcontinue(jsonin, method)
        }

        return jsonout
}

function getcontinue(jsonin, method     ,re,a,b,c) {

        # eg. "continue":{"blcontinue":"0|20304297","continue"

        re = "\"continue\"[:][{]\"" method "\"[:]\"[^\"]*\""
        match(jsonin, re, a)
        split(a[0], b, "\"")

        if ( length(b[6]) > 0)
            return b[6]
        return 0
}


