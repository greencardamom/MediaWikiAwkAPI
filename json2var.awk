# =====================================================================================================
# JSON parse function. Returns a list of values parsed from json data.
#   example:  jsonout = json2var(jsonin)
# Returns a string containing values separated by "\n".
# See the section marked "<--" in parse_value() to customize for your application.
#
# Credits: by User:Green Cardamom at en.wikipedia.org
#          JSON parser derived from JSON.awk
#          https://github.com/step-/JSON.awk.git
# MIT license. May 2015        
# =====================================================================================================
function json2var(jsonin) {

        TOKEN=""
        delete TOKENS
        NTOKENS=ITOKENS=0
        delete JPATHS
        NJPATHS=0
        VALUE=""

        tokenize(jsonin)

        if ( parse() == 0 ) {
          return join(JPATHS,1,NJPATHS, "\n")
        }
}
function parse_value(a1, a2,   jpath,ret,x) {
        jpath=(a1!="" ? a1 "," : "") a2 # "${1:+$1,}$2"
        if (TOKEN == "{") {
                if (parse_object(jpath)) {
                        return 7
                }
        } else if (TOKEN == "[") {
                if (ret = parse_array(jpath)) {
                        return ret
        }
        } else if (TOKEN ~ /^(|[^0-9])$/) {
                # At this point, the only valid single-character tokens are digits.
                #report("value", TOKEN!="" ? TOKEN : "EOF")
                return 9
        } else {
                VALUE=TOKEN
        }
        if (! (1 == BRIEF && ("" == jpath || "" == VALUE))) {

                # This will print the full JSON data to help in building custom filter
                # x = sprintf("[%s]\t%s", jpath, VALUE)
                # print x

                if ( a2 == "\"*\"" || a2 == "\"title\"" ) {     # <-- Custom filter for MediaWiki API backlinks. Add custom filters here.
                    x = substr(VALUE, 2, length(VALUE) - 2)
                    NJPATHS++
                    JPATHS[NJPATHS] = x
                }

        }
        return 0
}
function get_token() {
        TOKEN = TOKENS[++ITOKENS] # for internal tokenize()
        return ITOKENS < NTOKENS
}
function parse_array(a1,   idx,ary,ret) {
        idx=0
        ary=""
        get_token()
        if (TOKEN != "]") {
                while (1) {
                        if (ret = parse_value(a1, idx)) {
                                return ret
                        }
                        idx=idx+1
                        ary=ary VALUE
                        get_token()
                        if (TOKEN == "]") {
                                break
                        } else if (TOKEN == ",") {
                                ary = ary ","
                        } else {
                                return 2
                        }
                        get_token()
                }
        }
        VALUE=""
        return 0
}
function parse_object(a1,   key,obj) {
        obj=""
        get_token()
        if (TOKEN != "}") {
                while (1) {
                        if (TOKEN ~ /^".*"$/) {
                                key=TOKEN
                        } else {
                                #report("string", TOKEN ? TOKEN : "EOF")
                                return 3
                        }
                        get_token()
                        if (TOKEN != ":") {
                                #report(":", TOKEN ? TOKEN : "EOF")
                                return 4
                        }
                        get_token()
                        if (parse_value(a1, key)) {
                                return 5
                        }
                        obj=obj key ":" VALUE
                        get_token()
                        if (TOKEN == "}") {
                                break
                        } else if (TOKEN == ",") {
                                obj=obj ","
                        } else {
                                #report(", or }", TOKEN ? TOKEN : "EOF")
                                return 6
                        }
                        get_token()
                }
        }
        VALUE=""
        return 0
}
function parse(   ret) {
        get_token()
        if (ret = parse_value()) {
                return ret
        }
        if (get_token()) {
                #report("EOF", TOKEN)
                return 11
        }
        return 0
}
function tokenize(a1,   pq,pb,ESCAPE,CHAR,STRING,NUMBER,KEYWORD,SPACE) {

        # POSIX character classes (gawk) - contact me for non-[:class:] notation
        # Replaced regex constant for string constant, see https://github.com/step-/JSON.awk/issues/1
        SPACE="[[:space:]]+"
        gsub(/\"[^[:cntrl:]\"\\]*((\\[^u[:cntrl:]]|\\u[0-9a-fA-F]{4})[^[:cntrl:]\"\\]*)*\"|-?(0|[1-9][0-9]*)([.][0-9]*)?([eE][+-]?[0-9]*)?|null|false|true|[[:space:]]+|./, "\n&", a1)
        gsub("\n" SPACE, "\n", a1)
        sub(/^\n/, "", a1)
        ITOKENS=0 # get_token() helper
        return NTOKENS = split(a1, TOKENS, /\n/)

}
