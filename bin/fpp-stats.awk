function dprint (n, s) {
    if (DEBUG >= n)
        print s >>"/dev/stderr"
}

# Remove comments and strings from 'string'
# to avoid false positive tests. Some pattern
# tests will compare againts the cleaned-up
# string instead of $0.
function cleanup(string,                col1) {
    # if (string ~ /[/][*]/) dprint(0, "    See /*: '" string "'")
    if (FIXED) {
        col1 = substr(string, 1, 1)
        if (col1 == "C" || col1 == "c" || col1 == "*")
            string = ""
    }
    if (string != "") {
        string = gensub(/"[^"]*"/, "", "g", string)
        string = gensub(/'[^']*'/, "", "g", string)
        string = gensub(/[/][/].*/, "", "g", string)
        string = gensub(/[/][*].*[*][/]/, "", "g", string)
        if (string !~ /^\s*#\s*([Ee][Ll])?[Ii][Ff]/)
            string = gensub(/!.*/, "", "g", string)
    }

    return string
}

# Eat up the "next" Hollerith literal.
# Note that this is messy, mostly because it seems
# like there are bugs in 'gensub' or I was using it
# terribly wrong.
# Note that since we are not doing legit tokenization,
# there are still cases we will get wrong.
#
# Since multiple return values is a pain in awk,
# this routine has the side effect of counting '&'
# in free-form lines...
function eat_hollerith(s,                _h, _hi, _n, _r) {
    dprint(1, "Eat Hollerith s='" s "'")

    if (s !~ /[0-9]+H/) {
        print "Eat Hollerith called without Hollerith '" s "'" >>"/dev/stderr"
        exit 1
    }

    # Eat up to nnnH.
    _h = s
    _n = 0
    do {
        _h = gensub(/^[^0-9]*/, "", 1, _h)
        dprint(1, "Eat Hollerith _h after eating up to digits='" _h "'")
        if (_h ~ /^[0-9]+H/)
            break
        _h = gensub(/([0-9]+)/, "", 1, _h)
        dprint(1, "Eat Hollerith _h after eating digits='" _h "'")
        if (_n++ > 20) {
            print "Eat Hollerith: Give up on getting to the Hollerith " \
                FILENAME ":" NR " at '" _h "'" >>"/dev/stderr"
            exit 1
        }
    } while (_h != "")

    if (_h == "") {
        print "Eat Hollerith: Can't happen, _h = empty" >>"/dev/stderr"
        exit 1
    }

    _hi = index(_h, "h")
    if (_hi == 0)
        _hi = index(_h, "H")
    if (_hi == 0) {
        print "Eat Hollerith: Can't happen, _hi == 0, file " FILENAME ", line " NR >>"/dev/stderr"
        exit 1
    }
    dprint(1, "Eat Hollerith _hi index of 'H'=" _hi+0)

    _n = substr(_h, 1, _hi) + 0
    dprint(1, "Eat Hollerith _n nnn=" _n+0)
    dprint(1, "Eat Hollerith string='" substr(_h, _hi+1, _n) "'")
    dprint(1, "Eat Hollerith after='" substr(_h, _hi+_n+1) "'")

    if (FREE && substr(_h, _hi, _n + 1) ~ /&$/) {
        HOLLERITH_AMPERSAND++
        dprint(1, "Eat Hollerith free & ='" substr(_h, _hi+1, _n) "'")
    }
    _r = substr(_h, _hi + _n + 1)
    dprint(1, "Eat Hollerith _r='" _r "'")

    return _r
}

BEGIN {
    if (JUST_HEADING) {
        # This must match the printf in the END block.
        print "File,Form,Lines,Directives,#include,#define,\"#define M()\",#undef,#ifdef,#ifndef,#if,#elif,#else,#endif,#pragma,#line,\"# nnn\",#error,#warning,\"# empty\",\"# (other)\",Continuations,\"# op\",\"## op\",\"Ftn op\",Indented,\"#.../*...*/\",\"#.../*...\",\"#...//\",\"Ftn include\",Hollerith,\"Hollerith &\",\"#if ...!\",fypp"
        exit 0
    }

    #Ignore case in all pattern expressions.
    IGNORECASE = 1

    if (FIXED == "") {
        print "fpp-stats.awk: Need to specify -v FIXED=1 or -v FIXED=0" >"/dev/stderr"
        exit 1
    }
    FREE = !FIXED
}

{   # For every line...
    NUM_LINES++
    FIXED_CONTINUE_POUND = FIXED && substr($0, 6, 1) == "#"

    # For some of the tests, we want to check for specific strings
    # but we want to make sure we don't look inside strings or comments
    # we can get a number of false positives.
    CLEANED = cleanup($0);
    # if (CLEANED != $0) {
    #     dprint(0, "  clean   '" $0 "'")
    #     dprint(0, "  cleaned '" CLEANED "'")
    # }
}

# Don't examine fixed-format comment linesto avoid false positives.
FIXED && /^[c*]/ {
    next
}

# If we are in the midst of an unterminated
# C-style comment, look for the end of it.
# If this line doesn't complete it, skip
# further examination of it.
IN_UNTERMINATED_SLASH_STAR && !/[*][/]/ {
    next
}

# If this line does complete it, delete the comment
# text and treat this line as if it is a continuation
# of the previous line.
IN_UNTERMINATED_SLASH_STAR {
    rep_count = sub(/.*[*][/]/, "", $0)
    if (rep_count == 0) {
        dprint(0, "Can't find proper end of unterminated C-style comment in '" $0 "'")
    }
    IN_UNTERMINATED_SLASH_STAR = 0
    CONTINUED = 1
}

# A new preprocessor line; assume not continuation until we examine further.
# Avoid counting fypp directives; we count them elsewhere.

#    # newline    # non-fypp     # not in continuation column
(/^\s*#\s*$/ || /^\s*#[^:!]/) && !FIXED_CONTINUE_POUND {
    DIRECTIVE++
    CONTINUED = 0

    # Delete (but count) C-style /* ... */ comments to avoid false positives.
    if ($0 ~ /[/][*]/) {
        rep_count = gsub(/[/][*].*[*][/]/, "", $0)
        DIR_SLASH_STAR += rep_count
        rep_count = sub(/[/][*].*$/, "", $0)
        if (rep_count) {
            DIR_SLASH_STAR_UNTERMINATED++
            IN_UNTERMINATED_SLASH_STAR = 1
        }
    }

    # Delete C-style // ... comments, too.
    if ($0 ~ /[/][/]/) {
        $0 = gensub(/[/][/].*/, "", "g", $0)
        DIR_SLASH_SLASH++
    }

    # Track the directive we're currently in
    IN = ""
}

# Look for continued directive with (possible) strings
# that appears to have a /* ... */ comment on it.
# This may start us looking for unterminated comments again.
CONTINUED && /^[^"]*("[^"]*")?[^"]*[/][*]/ {
    rep_count = gsub(/[/][*].*[*][/]/, "", $0)
    DIR_SLASH_STAR += rep_count
    rep_count = sub(/[/][*].*$/, "", $0)
    if (rep_count) {
        DIR_SLASH_STAR_UNTERMINATED++
        IN_UNTERMINATED_SLASH_STAR = 1
    }
}

# Look for continued directive with (possible) strings
# that appears to have a // comment on it.
CONTINUED && /^[^"]*("[^"]*")?[^"]*[/][/]/ {
    DIR_SLASH_SLASH++
}


/^\s*#\s*include\s/ && !FIXED_CONTINUE_POUND {
    INCLUDE++
    IN = "include"
}

!CONTINUED && CLEANED ~ /^\s*include\s/ {
    FTN_INCLUDE++
}

# Various forms of #define
/^\s*#\s*define\s*[A-Za-z_][A-Za-z0-9_]*(\s+|\s*$)/ \
&& !FIXED_CONTINUE_POUND {
    DEFINE++
    IN = "define"
}
/^\s*#\s*define\s*[A-Za-z_][A-Za-z0-9_]*[(]/ && !FIXED_CONTINUE_POUND {
    DEFINE_ARGS++
    IN = "define()"
}

/^\s*#\s*undef/ && !FIXED_CONTINUE_POUND {
    UNDEF++
    IN = "undef"
}

/^\s*#\s*ifdef/ && !FIXED_CONTINUE_POUND {
    IFDEF++
    IN = "ifdef"
}
/^\s*#\s*ifndef/ && !FIXED_CONTINUE_POUND {
    IFNDEF++
    IN = "ifndef"
}
/^\s*#\s*if[^dn]/ && !FIXED_CONTINUE_POUND {
    IF++
    IN = "if"
    if ($0 ~ /!/)
        IFBANG++
}
/^\s*#\s*elif/ && !FIXED_CONTINUE_POUND {
    ELIF++
    IN = "elif"
    if ($0 ~ /!/)
        IFBANG++
}
/^\s*#\s*else/ && !FIXED_CONTINUE_POUND {
    ELSE++
    IN = "else"
}
/^\s*#\s*endif/ && !FIXED_CONTINUE_POUND {
    ENDIF++
    IN = "endif"
}
/^\s*#\s*pragma/ && !FIXED_CONTINUE_POUND {
    PRAGMA++
    IN = "pragma"
}

/^\s*#\s*line/ && !FIXED_CONTINUE_POUND {
    LINE++
    IN = "line"
}

/^\s*#\s*[0-9]+/ && !FIXED_CONTINUE_POUND {
    NNN++
    IN = "nnn"
}

/^\s*#\s*error/ && !FIXED_CONTINUE_POUND {
    ERROR++
    IN = "error"
}
/^\s*#\s*warning/ && !FIXED_CONTINUE_POUND {
    WARNING++
    IN = "warning"
}

/^\s*#\s*$/ && !FIXED_CONTINUE_POUND {
    EMPTY++
    IN = "empty"
}

# # operators
CLEANED ~ /^\s*#[^#]*#[^#:{]/ && !FIXED_CONTINUE_POUND {
    tmp = $0
    rep_count = gsub(/^\s*#[^#]*#[^#:{]/, "# ", tmp)
    dprint(1, "# op '" $0 "': " rep_count)
    HASH += rep_count
}

CONTINUED && CLEANED ~ /^\s*[^#]*#[^#:{]/ {
    tmp = $0
    rep_count = gsub(/^\s*[^#]*#[^#:{]/, "# ", tmp)
    dprint(1, "# op '" $0 "': " rep_count)
    HASH += rep_count
}

# ## operators
CLEANED ~ /^\s*#[^#]*##/ && !FIXED_CONTINUE_POUND {
    tmp = $0
    rep_count = gsub(/^\s*#[^#]*##/, "# ", tmp)
    dprint(1, "## op '" $0 "': " rep_count)
    HASH_HASH += rep_count
}
CONTINUED && CLEANED ~ /^\s*[^#]*##/ {
    tmp = $0
    rep_count = gsub(/^\s*[^#]*##/, "", tmp)
    dprint(1, "## op '" $0 "': " rep_count)
    HASH_HASH += rep_count
}

# Fortran .xxx. operators?
CLEANED ~ /^\s*#\s*((el)?if)[^.]*\.(n?eq|n?eqv|[gl][et]|not|and|or)\./ \
&& !FIXED_CONTINUE_POUND \
&& (IN == "if" || IN == "elif") {
    tmp = $0
    rep_count = gsub(/\.(n?eq|n?eqv|[gl][et]|not|and|or)\./, "# ", tmp)
    dprint(1, "Ftn op '" $0 "': " rep_count ", FN='" FILENAME "', NR=" NR)
    FTN_OP += rep_count
}
CONTINUED && CLEANED ~ /^\s*[^.]*\.(n?eq|n?eqv|[gl][et]|not|and|or)\./ \
&& (IN == "if" || IN == "elif") {
    tmp = $0
    rep_count = gsub(/\.(n?eq|n?eqv|[gl][et]|not|and|or)\./, "", tmp)
    dprint(1, "Ftn op cont'd '" $0 "': " rep_count ", FN='" FILENAME "', NR=" NR)
    FTN_OP += rep_count
}

/^\s\s*#[^:]/ && !FIXED_CONTINUE_POUND {
    INDENT++
}

# FORMAT statement looking thing that contains Hollerith.
# Only look at the line with strings and comments removed.
CLEAN ~ /^ *[0-9]* *format *\(.*[0-9]+H/ {
    dprint(1, "Hollerith format '" $0 "'")
    this_hollerith = 0
    remain = CLEAN
    _n = 0
    do {
        this_hollerith++
        remain = eat_hollerith(remain)
        if (++_n > 30) {
            print "Give up on Hollerith in FORMAT: FILENAME '" FILENAME "' NR '" NR " '" $0 "'" >>"/dev/stderr"
            exit 1
        }
    } while (remain ~ /[0-9]+H/)
    dprint(1, "More Hollerith? " this_hollerith " '" remain "'")
    HOLLERITH += this_hollerith
}

# DATA statement looking thing that contains Hollerith.
# Only look at the line with strings and comments removed.
CLEAN ~ /^ *[^/]*\/ *[0-9]+H/ {
    dprint(1, "Hollerith data '" $0 "'")
    this_hollerith = 0
    remain = CLEAN
    _n = 0
    do {
        this_hollerith++
        remain = eat_hollerith(remain)
        if (++_n > 50) {
            print "Give up on Hollerith in DATA: FILENAME '" FILENAME "' NR '" NR " '" $0 "'" >>"/dev/stderr"
            exit 1
        }
    } while (remain ~ /[0-9]+H/)
    dprint(1, "More Hollerith? " this_hollerith " '" remain "'")
    HOLLERITH += this_hollerith
}

# Try to identify fypp directives; just counting them.

#     #: or #!         @:
(CLEANED ~ /^\s*#[:!]/ || CLEANED ~ /^\s*@:/) && !FIXED_CONTINUE_POUND {
    FYPP++
}

# Inline forms
CLEANED ~ /#{/ || CLEANED ~ /@{/ {
    line = $0
    FYPP += gsub(/#{[^}]*}#/, "", line)
    FYPP += gsub(/@{[^}]*}@/, "", line)
}

# A directive with a continuation line
CLEANED ~ /^\s*#.*[\\]$/ {
    CONTINUE++
    CONTINUED = 1
}

# A continued directive line with another continuation
CONTINUED && CLEANED ~ /[\\]$/ {
    CONTINUE++
}

# An un-continued line after a continuation
CONTINUED && CLEANED ~ /.*[^\\]$/ {
    CONTINUE++
    CONTINUED = 0
}

END {
    # Note that, oddly enough, the 'exit 0' in BEGIN
    # just brings us here.
    if (JUST_HEADING)
        exit 0

    OTHER = DIRECTIVE - (INCLUDE + DEFINE + DEFINE_ARGS + UNDEF \
                         + IFDEF + IFNDEF + IF + ELIF + ELSE + ENDIF \
                         + PRAGMA + LINE + NNN + ERROR + WARNING \
                         + EMPTY)
    printf "\"%s\",%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", \
        FILENAME, FIXED?"fixed": "free", NUM_LINES, DIRECTIVE, \
        INCLUDE, DEFINE, DEFINE_ARGS, UNDEF, \
        IFDEF, IFNDEF, IF, ELIF, ELSE, ENDIF, \
        PRAGMA, LINE, NNN, ERROR, WARNING, EMPTY, OTHER, \
        CONTINUE, HASH, HASH_HASH, FTN_OP, INDENT, \
        DIR_SLASH_STAR, DIR_SLASH_STAR_UNTERMINATED, DIR_SLASH_SLASH, \
        FTN_INCLUDE, HOLLERITH, HOLLERITH_AMPERSAND, IFBANG, FYPP
}
