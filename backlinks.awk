# backlinks.awk
#  -- demonstration program of the MediaWiki Awk API Library.
#
#  Prints the full list of backlinks such as seen at "Special:What Links Here"
#   * It uses the "continue" function (not limited by 500 results).
#   * It includes (transcluded) pages for Template: types, and (file) pages for File: types
#   * It includes second-level backlinks (from redirects)
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

        gsub(" ","_",entity)

        url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" entity "&blredirect&bllimit=250&continue=&blfilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag
        blinks = getbacklinks(url, entity, "blcontinue") # normal backlinks

        if ( entity ~ "^Template:") {    # transclusion backlinks
            url = "http://en.wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" entity "&continue=&eilimit=500&format=json&utf8=1&maxlag=" Maxlag
            blinks = blinks "\n" getbacklinks(url, entity, "eicontinue")
        } else if ( entity ~ "^File:") { # file backlinks
            url = "http://en.wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" entity "&iuredirect&iulimit=250&continue=&iufilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag
            blinks = blinks "\n" getbacklinks(url, entity, "iucontinue")
        }

        blinks = uniq(blinks)
        if ( length(blinks) > 0) print blinks 
        return length(blinks)

}

function getbacklinks(url, entity, method,      jsonin, jsonout, continuecode) {

        jsonin = http2var(url)
        jsonout = json2var(jsonin)
        continuecode = getcontinue(jsonin, method)

        while ( continuecode ) {

            if ( method == "eicontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=embeddedin&eititle=" entity "&eilimit=500&continue=-||&eicontinue=" continuecode "&format=json&utf8=1&maxlag=" Maxlag
            if ( method == "iucontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=imageusage&iutitle=" entity "&iuredirect&iulimit=250&continue=&iufilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag
            if ( method == "blcontinue" )
                url = "http://en.wikipedia.org/w/api.php?action=query&list=backlinks&bltitle=" entity "&blredirect&bllimit=250&continue=-||&blcontinue=" continuecode "&blfilterredir=nonredirects&format=json&utf8=1&maxlag=" Maxlag

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


#
# Uniq a list of \n separated names
#
function uniq(names,    b,c,i,x) {

        c = split(names, b, "\n")
        names = "" # free memory
        while (i++ < c) {
            if(b[i] ~ "for API usage") {
                print "Max lag exceeded. Try again when servers less busy or increase Maxlag variable. See https://www.mediawiki.org/wiki/Manual:Maxlag_parameter."
                exit
            }
            if(b[i] == "")
                continue
            if(x[b[i]] == "")
                x[b[i]] = b[i]
        }
        delete b # free memory
        return join2(x,"\n")
}

