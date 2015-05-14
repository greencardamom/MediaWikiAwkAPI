# ==========================================================================================================
# http2var - save an HTML page to a variable.
#   example: page = http2var("http://en.wikipedia.org/w/api.php?action=query...")
#   Handles redirects. Adapted for Wikipedia API URL format. 
#
# Credit: by User: Green Cardamom at en.wikipedia.org
#         Adapted from Peteris Krumins's "get_youtube_vids.awk"
#         https://code.google.com/p/lawker/source/browse/fridge/gawk/www/get_youtube_vids.awk
# MIT license. May 2015
# ==========================================================================================================
function http2var(url   ,urlhost,urlrequest, c,i,a,p,f,j,output, foO, headerS, matches, inetfile, request, loop)
{

 # Assumes a URL containing standard Wikipedia API URL syntax
 #   eg: http://en.wikipedia.org/w/api.php?action=query...

  split(url, a, "/")
  urlhost = a[3]                                # en.wikipedia.org
  split(url, a, "[?]")
  urlrequest = "/w/api.php?" a[2]               # /w/api.php?action=query... 

  inetfile = "/inet/tcp/0/" urlhost "/80"
  request = "GET " urlrequest " HTTP/1.0\r\n"   # 1.1 doesn't work due to Transfer-Encoding: chunked
  request = request "Host: " urlhost "\r\n"
  request = request "User-Agent: " G["api agent"] "\r\n"  #           <-- Custom API Agent string
#  request = request "Accept-Encoding: gzip \r\n"         #           <-- To Do
  request = request "Cache-Control: no-cache \r\n"
  request = request "\r\n\r\n"

  do {
    get_headers(inetfile, request, headerS)
    if ("Location" in headerS) {
      close(inetfile)
      if (match(headerS["Location"], /http:\/\/([^\/]+)(\/.+)/, matches)) {
        foO["InetFile"] = "/inet/tcp/0/" matches[1] "/80"
        foO["Host"]     = matches[1]
        foO["Request"]  = matches[2]
      }
      else {
        foO["InetFile"] = ""
        foO["Host"]     = ""
        foO["Request"]  = ""
      }
      inetfile = foO["InetFile"]
      request  = "GET " foO["Request"] " HTTP/1.0\r\n"
      request  = request "Host: " foO["Host"] "\r\n"
      request  = request "User-Agent: " G["api agent"] "\r\n"  #           <-- Custom API Agent string
      request  = request "Cache-Control: no-cache \r\n"
      request  = request "\r\n\r\n"
      if (inetfile == "") {
        print "Failed 1 (" url "), got caught in Location loop!" > "/dev/stderr"
        return -1
      }
    }
    loop++
  } while (("Location" in headerS) && loop < 5)
  if (loop == 5) {
        print "Failed 2 (" url "), got caught in Location loop!" > "/dev/stderr"
        return -1
  }

  while ((inetfile |& getline) > 0) {
    j++
    output[j] = $0
  }
  close(inetfile)
  if(length(output) == 0)
    return -1
  else
    return join(output, 1, j, "\n")
}

function get_headers(Inet, Request, headerS) {

    delete headerS

    # save global vars
    OLD_RS=RS

    print Request |& Inet

    # get the http status response
    if (Inet |& getline > 0) {
        headerS["_status"] = $2
    }
    else {
        print "Failed reading from the net. Quitting!"
        exit 1
    }

    RS="\r\n"
    while ((Inet |& getline) > 0) {
        # we could have used FS=": " to split, but i could not think of a good
        # way to handle header values which contain multiple ": "
        # so i better go with a match
        if (match($0, /([^:]+): (.+)/, Matches)) {
          headerS[Matches[1]] = Matches[2]
        }
        else { break }
    }
    RS=OLD_RS
}

