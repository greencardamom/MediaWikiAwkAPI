#
# Library of routines for building scripts and bots, for Wikipedia or anything else.
#   by User:Green_Cardamom at en.wikipedia.org
#   https://github.com/greencardamom/MediaWikiAwkAPI
#   


#
# Run a system command and return result in a variable
#   eg. googlepage = sys2var("wget -q -O- http://google.com")
# Supports pipes inside command string. Stderr is sent to null.
# If command fails return null
#
function sys2var(command        ,fish, scale, ship) {

         command = command " 2>/dev/null"
         while ( (command | getline fish) > 0 ) {
             if ( ++scale == 1 )
                 ship = fish
             else
                 ship = ship "\n" fish
         }
         close(command)
         return ship
}

#
# Webpage to variable
#  Assumes a global variable "Agent", or pass it an agent string 
#
function http2var(url) {

        return sys2var("wget --no-check-certificate --user-agent=" shquote(Agent) " -q -O- " shquote(url))
}

# 
# Make string safe for shell
#  print shquote("Hello' There")    produces 'Hello'\'' There'              
#  echo 'Hello'\'' There'           produces Hello' There                 
# 
function shquote(str,  safe) {

        safe = str
        gsub(/'/, "'\\''", safe)
        gsub(/’/, "'\\’'", safe)
        return "'" safe "'"
}

#
# entity_exists - see if a page on Wikipedia exists
#   eg. if ( ! entity_exists("Project Guuuuuuutenberg") ) print "Unknown page"
#
function entity_exists(entity   ,url, jsonin) {
     
        url = "http://en.wikipedia.org/w/api.php?action=query&titles=" urlencodeawk(entity) "&format=json"
        jsonin = http2var(url)
        if(jsonin ~ "\"missing\"")
          return 0
        return 1
}

#
# Strip leading/trailing whitespace
#
function strip(str) {
       return gensub(/^[[:space:]]+|[[:space:]]+$/,"","g",str)
}                


#
# Merge an array of strings into a single string. Array indice are numbers.
#
function join(array, start, end, sep,    result, i)
{

        result = array[start]
        for (i = start + 1; i <= end; i++)
          result = result sep array[i]
        return result
}

#
# Merge an array of strings into a single string. Array indice are strings.
#
function join2(arr, sep         ,i,lobster) {

        for ( lobster in arr ) {
            if(++i == 1) {
                result = lobster
                continue
            }
            result = result sep lobster
        }
        return result
}

#
# Escape regex symbols
#   eg: print regesc("&^$(){}[].*+?|\\=:") produces &[\\^][$][(][)][{][}]\[\][.][*][+][?][|]\\[=][:]
#   Credit: https://github.com/cheusov/runawk/blob/master/modules/str2regexp.awk
#
function regesc(str,   safe) {

        safe = str
        gsub(/\[/, "---open-sq-bracket---", safe)
        gsub(/\]/, "---close-sq-bracket---", safe)

        gsub(/[?{}|()*+.$=:]/, "[&]", safe)
        gsub(/\^/, "[\\^]", safe)

        if (safe ~ /\\/)
          gsub(/\\/, "\\\\", safe)

        gsub(/---open-sq-bracket---/, "\\[", safe)       
        gsub(/---close-sq-bracket---/, "\\]", safe)       

        return safe
}

#
# strip wiki comments <!-- comment -->
#  eg. "George Henry is a [[lawyer]]<!-- source? --> from [[Charlesville (Virginia)|Charlesville <!-- west? --> Virginia]]"
#      "George Henry is a [[lawyer]] from [[Charlesville (Virginia)|Charlesville Virginia]]"
#
function stripwikicomments(str, a,c,i,out,sep) {

        c =  patsplit(strip(str), a, /<[ ]{0,}[!][^>]*>/, sep)
        out = sep[0]
        while(i++ < c) {
          out = out sep[i]
        }
        return strip(out)
}

#
# Check for file existence. Return 1 if exists, 0 otherwise.
#  Requires GNU Awk: @load "filefuncs"
#
function exists(name    ,fd) {
        if ( stat(name, fd) == -1)
          return 0
        else
          return 1
}

#
# File size
#   Requires GNU Awk: @load "filefuncs"
#
function filesize(name         ,fd) {
        if ( stat(name, fd) == -1)
          return -1  # doesn't exist
        else
          return fd["size"]
}

#
# Make a directory ("mkdir -p dir")
#  requires: @load "filefuncs"
#  requires: mkdir in PATH
#
function mkdir(dir,    ret, var, cwd) {

        sys2var("mkdir -p " shquote(dir) " 2>/dev/null")
        cwd = ENVIRON["PWD"]
        ret = chdir(dir)
        if (ret < 0) {
          printf("Could not create %s (%s)\n", dir, ERRNO) > "/dev/stderr"
          return 0
        }
        ret  = chdir(cwd)
        if (ret < 0) {
          printf("Could not chdir to %s (%s)\n", cwd, ERRNO) > "/dev/stderr"
          return 0
        }
        return 1
}

#
# Print the directory portion of a /dir/filename string. End with trailing "/"
#   eg. /home/adminuser/wi-awb/tcount.awk -> /home/adminuser/wi-awb/
#
function dirname (pathname){
        if (sub(/\/[^\/]*$/, "", pathname))
                return pathname "/"
        else
                return "." "/"
}

#
# strip blank lines from start/end of a file
#  Require: @load "readfile"
#
#  Optional type = "inplace" will overwrite file, otherwise return as variable
#    These do the same:
#      out = stripfile("test.txt"); print out > "test.txt"; close("test.txt")
#      stripfile("test.txt", "inplace")
#
#  One-liner shell method:
#    https://stackoverflow.com/questions/7359527/removing-trailing-starting-newlines-with-sed-awk-tr-and-friends
#      awk '{ LINES=LINES $0 "\n"; } /./ { printf "%s", LINES; LINES=""; }' input.txt | sed '/./,$\!d' > output.txt
#
function stripfile(filen, type,    i,c,a,o,start,end,out) {
  
        if( ! exists(filen) ) {
          print "stripfile(): Unable to find " filen > "/dev/stderr"
          return
        }

        c = split(readfile(filen),a,"\n")

       # First non-blank line
        while(i++ < c) {
          if(a[i] != "") {
            start = i
            break
          }
        }

        i = 0

       # Last non-blank line
        while(i++ < c) {
          if(a[i] != "")
            end = i
        }

        i = 0

        while(i++ < c) {
          if(i >= start && i <= end) {
            if(i == start)
              out = a[i]
            else
              out = out "\n" a[i]
          }
        }

        if(type == "inplace") {
          system("")   # flush buffers
          print out > filen
          close(filen)
        }
        else
          return out
}

#
# Sleep for seconds
#  requires: unix 'sleep' in PATH
#
function sleep(seconds) {
        if(seconds > 0)
          sys2var( "sleep " seconds)  
}

#
# Return a random number between 1 to max
#
#  Seed is clock-based (systime) so ensure there is plenty of time between each call or it will return the same number.
#  Otherwise find a different method to seed srand.
#
function randomnumber(max) {
        srand(systime() + PROCINFO["pid"])
        return int( rand() * max)
}

#
# Return 1 if str is a pure digit
#  eg. "1234" == 1. "0fr123" == 0
#
function isanumber(str,    safe,i) {

        if(length(str) == 0) return 0
        safe = str
        if(safe == "") return 0
        if(safe == "0") return 1
        while( i++ < length(safe) ) {
          if( substr(safe,i,1) !~ /[0-9]/ )
            return 0
        }
        return 1
}

#
# countsubstring
#
#   Returns number of occurances of pattern in str.
#   Pattern treated as a literal string, it is regex char safe
#
#   Example: print countsubstring("[do&d?run*d!run>run*", "run*")
#            2
#
#   To count substring using regex use gsub ie. total += gsub("[.]","",str)
#
function countsubstring(str, pat,    len, i, c) {

        c = 0
        if( ! (len = length(pat) ) ) {
          return 0
        }
        while(i = index(str, pat)) {
          str = substr(str, i + len)
          c++
        }
        return c
}

# 
# URL-encode limited set of characters needed for Wikipedia templates
#    https://en.wikipedia.org/wiki/Template:Cite_web#URL
#
function urlencodelimited(url,  safe) {

        safe = url
        gsub(/[ ]/, "%20", safe)
        gsub(/["]/, "%22", safe)
        gsub(/[']/, "%27", safe)
        gsub(/[<]/, "%3C", safe)
        gsub(/[>]/, "%3E", safe)
        gsub(/[[]/, "%5B", safe)
        gsub(/[]]/, "%5D", safe)
        gsub(/[{]/, "%7B", safe)
        gsub(/[}]/, "%7D", safe)
        gsub(/[|]/, "%7C", safe)
        return safe
}

#
# Convert XML to plain
#
function convertxml(str,   safe) {

      safe = str
      gsub(/&lt;/,"<",safe)
      gsub(/&gt;/,">",safe)
      gsub(/&quot;/,"\"",safe)
      gsub(/&amp;/,"\\&",safe)
      gsub(/&#039;/,"'",safe)
      return safe
}

#
# Retrieve wikitext of a page
#   requires: GNU awk with -b option set
#   optional "follow" if set to "no" returns contents of redirect page otherwise it follows the redirect
#
function getwikitext(namewiki,follow,     command,f,r,redirurl) {

        command = "https://en.wikipedia.org/w/index.php?title=" urlencodeawk(strip(namewiki)) "&action=raw"
        f = http2var(command)
        if(length(f) < 5)
          return ""

        if( tolower(f) ~ /[#][ ]{0,}redirect[ ]{0,}[[]/ && tolower(follow) !~ /no/) {
          match(f, /[#][ ]{0,}[Rr][Ee][^]]*[]]/, r)
          gsub(/[#][ ]{0,}[Rr][Ee][Dd][Ii][^[]*[[]/,"",r[0])
          redirurl = strip(substr(r[0], 2, length(r[0]) - 2))
          command = "https://en.wikipedia.org/w/index.php?title=" urlencodeawk(redirurl) "&action=raw"
          f = http2var(command)
        }
        if(length(f) < 5)
          return ""
        else
          return f
}


#
# Uniq a list of \n separated names that were obtained from Wikipedia API
#  Exit program if Max lag exceeded.
#
function uniq(names,    b,c,i,x) {

        c = split(names, b, "\n")
        names = "" # free memory
        while (i++ < c) {
            gsub(/\\["]/,"\"",b[i])      # convert \" to "
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


#
# Percent encode a string for use in a URL
#  requires: GNU Awk -b to encode extended ascii eg. "ł"
#  Credit: Rosetta Code May 2015
#
function urlencodeawk(str,  c, len, res, i, ord) {

        for (i = 0; i <= 255; i++)
                ord[sprintf("%c", i)] = i
        len = length(str)
        res = ""
        for (i = 1; i <= len; i++) {
                c = substr(str, i, 1);
                if (c ~ /[0-9A-Za-z]/)
                        res = res c
                else
                        res = res "%" sprintf("%02X", ord[c])
        }
        return res
}

#
# Basic check of Wikipedia API results for error
#   type = xml or json
#
function apierror(input, type,   pre, code) {

        pre = "API error: "

        if(length(input) < 5) {
          errormsg(pre "Received no response.")
          return 1
        }

        if(type == "json") {
          if(match(input, /"error"[:]{"code"[:]"[^\"]*","info"[:]"[^\"]*"/, code) > 0) {
            errormsg(pre code[0])
            return 1
          }
        }
        else if(type == "xml") {
          if(match(input, /error code[=]"[^\"]*" info[=]"[^\"]*"/, code) > 0) {
            error(re code[0])
            return 1
          }
        }
        else
          return
}

#
# Print error message to STDERR
#
function errormsg(msg) {

        if(length(msg) > 0)
          print msg > "/dev/stderr"
        else
          print "Unknown error" > "/dev/stderr"
}

