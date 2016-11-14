#
# Run a system command and store result in a variable
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
#
function http2var(url) {

        return sys2var("wget --no-check-certificate --user-agent=\"" Agent "\" -q -O- \"" url "\"")

}

#
# entity_exists - see if a page on Wikipedia exists
#   eg. if ( ! entity_exists("Project Guuuuuuutenberg") ) print "Unknown page"
#
function entity_exists(entity   ,url, jsonin) {

        gsub(" ","_",entity)
        url = "http://en.wikipedia.org/w/api.php?action=query&titles=" entity "&format=json"
        jsonin = http2var(url)
        if(jsonin ~ "\"missing\"")
          return 0
        return 1
}

#
# Strip leading/trailing whitespace
#
function strip(str)
{
        gsub(/^[[:space:]]+|[[:space:]]+$/,"",str)
        return str
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

