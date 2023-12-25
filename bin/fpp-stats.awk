function dprint (n, s) {
    if (DEBUG >= n)
        print s >>"/dev/stderr"
}

# Eat up the "next" Hollerith literal.
# Note that this is messy, mostly because it seems
# like there are bugs in 'gensub' or I was using it
# terribly wrong.
# Note that since we are not doing legit tokenization,
# there are still cases we will get wrong.
function eat_hollerith(s,                _h, _hi, _n, _r) {
    dprint(1, "Eat Hollerith s='" s "'")

    if (s !~ /[0-9]+[Hh]/) {
        print "Eat Hollerith called without Hollerith '" s "'" >>"/dev/stderr"
        exit 1
    }

    # Eat up to nnnH.
    _h = s
    _n = 0
    do {
        _h = gensub(/^[^0-9]*/, "", 1, _h)
        dprint(1, "Eat Hollerith _h 1='" _h "'")
        if (_h ~ /^[0-9]+[Hh]/)
            break
        _h = gensub(/([0-9]+)/, "", 1, _h)
        dprint(1, "Eat Hollerith _h 2='" _h "'")
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
    dprint(1, "Eat Hollerith _hi=" _hi+0)

    _n = substr(_h, 1, _hi) + 0
    dprint(1, "Eat Hollerith _n=" _n+0)

    _r = substr(_h, _hi + _n + 1)
    dprint(1, "Eat Hollerith _r='" _r "'")

    return _r
}

BEGIN {
    if (JUST_HEADING) {
        # This must match the printf in the END block.
        print "File,Form,Lines,Directives,#include,#define,\"#define M()\",#undef,#ifdef,#ifndef,#if,#elif,#else,#endif,#line,\"# nnn\",#error,#warning,\"# empty\",\"# (other)\",Continuations,\"# op\",\"## op\",Indented,\"#if ...!\",fypp,Hollerith"
        exit 0
    }

    if (FIXED == "") {
        print "fpp-stats.awk: Need to specify -v FIXED=1 or -v FIXED=0" >"/dev/stderr"
        exit 1
    }
    FREE = !FIXED
}

{   # For every line...
    NUM_LINES++
    FIXED_CONTINUE_POUND = FIXED && substr($0, 6, 1) == "#"
}

FIXED && /^[Cc*]/ {
    # Don't examine fixed-format comment lines for now to avoid false positives.
    next
}

# /!/ {
#     # Delete comments that might have false positives.
#     $0 = gensub(/!.*/, "", 1, $0)
# }

# A new preprocessor line; assume not continuation until we examine further.
# Avoid counting fypp directives; we count them elsewhere.

#    # newline          # non-fypp         # not in continuation column
(/^[ \t]*#[ \t]*$/ || /^[ \t]*#[^:!]/)&& !FIXED_CONTINUE_POUND {
    DIRECTIVE++
    CONTINUED = 0

    # Delete C-style /* ... */ comments to avoid false positives.
    $0 = gensub(/\/\*.*\*\//, "", "g", $0)

    # Delete C-style // ... comments, too.
    $0 = gensub(/\/\/.*/, "", "g", $0)
}

/^[ \t]*#[^#]*##/ && !FIXED_CONTINUE_POUND {
    dprint(1, "## op '" $0 "'")
    HASH_HASH++
}
/^[ \t]*#[^#]*#[^#]/ && !FIXED_CONTINUE_POUND {
    dprint(1, "# op '" $0 "'")
    HASH++
}

/^[ \t][ \t]*#[^:]/ && !FIXED_CONTINUE_POUND {
    INDENT++
}

/^[ \t]*#[ \t]*include/ && !FIXED_CONTINUE_POUND {
    INCLUDE++
}

(/^[ \t]*#[ \t]*define[ \t]*[A-Za-z_][A-Za-z0-9_]*[ ]/ \
    || /^[ \t]*#[ \t]*define[ \t]*[A-Za-z_][A-Za-z0-9_]*$/) \
&& !FIXED_CONTINUE_POUND {
    DEFINE++
}
/^[ \t]*#[ \t]*define[ \t]*[A-Za-z_][A-Za-z0-9_]*[(]/ && !FIXED_CONTINUE_POUND {
    DEFINE_ARGS++
}

/^[ \t]*#[ \t]*undef/ && !FIXED_CONTINUE_POUND {
    UNDEF++
}

/^[ \t]*#[ \t]*ifdef/ && !FIXED_CONTINUE_POUND {
    IFDEF++
}
/^[ \t]*#[ \t]*ifndef/ && !FIXED_CONTINUE_POUND {
    IFNDEF++
}
/^[ \t]*#[ \t]*if[^dn]/ && !FIXED_CONTINUE_POUND {
    IF++
    if ($0 ~ /!/)
        IFBANG++
}
/^[ \t]*#[ \t]*elif/ && !FIXED_CONTINUE_POUND {
    ELIF++
    if ($0 ~ /!/)
        IFBANG++
}
/^[ \t]*#[ \t]*else/ && !FIXED_CONTINUE_POUND {
    ELSE++
}
/^[ \t]*#[ \t]*endif/ && !FIXED_CONTINUE_POUND {
    ENDIF++
}

/^[ \t]*#[ \t]*line/ && !FIXED_CONTINUE_POUND {
    LINE++
}

/^[ \t]*#[ \t]*[0-9]+/ && !FIXED_CONTINUE_POUND {
    NNN++
}

/^[ \t]*#[ \t]*error/ && !FIXED_CONTINUE_POUND {
    ERROR++
}
/^[ \t]*#[ \t]*warning/ && !FIXED_CONTINUE_POUND {
    WARNING++
}

/^[ \t]*#[ \t]*$/ && !FIXED_CONTINUE_POUND {
    EMPTY++
}

# Try to identify fypp directives; just counting them.

#     #: or #!         @:
(/^[ \t]*#[:!]/ || /^[ \t]*@:/) && !FIXED_CONTINUE_POUND {
    FYPP++
}

# Inline forms
/#{/ || /@{/ {
    line = $0
    FYPP += gsub(/#{[^}]*}#/, "", line)
    FYPP += gsub(/@{[^}]*}@/, "", line)
}

# FORMAT statement looking thing that contains Hollerith.
/^ *[0-9]* *[Ff][Oo][Rr][Mm][Aa][Tt] *\(.*[0-9]+[Hh]/ {
    dprint(1, "Hollerith format '" $0 "'")
    THIS_HOLLERITH = 0
    remain = $0
    _n = 0
    do {
        THIS_HOLLERITH++
        remain = eat_hollerith(remain)
        if (++_n > 30) {
            print "Give up on Hollerith in FORMAT: FILENAME '" FILENAME "' NR '" NR " '" $0 "'" >>"/dev/stderr"
            exit 1
        }
    } while (remain ~ /[0-9]+[Hh]/)
    dprint(1, "More Hollerith? " THIS_HOLLERITH " '" remain "'")
    HOLLERITH += THIS_HOLLERITH
}

# DATA statement looking thing that contains Hollerith.
/^ *[^/]*\/ *[0-9]+[Hh]/ {
    dprint(1, "Hollerith data '" $0 "'")
    THIS_HOLLERITH = 0
    remain = $0
    _n = 0
    do {
        THIS_HOLLERITH++
        remain = eat_hollerith(remain)
        if (++_n > 50) {
            print "Give up on Hollerith in DATA: FILENAME '" FILENAME "' NR '" NR " '" $0 "'" >>"/dev/stderr"
            exit 1
        }
    } while (remain ~ /[0-9]+[Hh]/)
    dprint(1, "More Hollerith? " THIS_HOLLERITH " '" remain "'")
    HOLLERITH += THIS_HOLLERITH
}

# A directive with a continuation line
/^[ \t]*#.*[\\]$/ {
    CONTINUE++
    CONTINUED = 1
}

# A non-preprocessor line with a continuation
CONTINUED && /^[ \t]*[^#].*[\\]$/ {
    CONTINUE++
}

# Count # and ## operators on continued lines
CONTINUED && /^[ \t]*[^#]*##/ {
    HASH_HASH++
}
CONTINUED && /^[ \t]*[^#]*#[^#]/ {
    HASH++
}

# An un-continued line after a continuation; don't count it.
CONTINUED && /.*[^\\]$/ {
    CONTINUED = 0
}

END {
    # Note that, oddly enough, the 'exit 0' in BEGIN
    # just brings us here.
    if (JUST_HEADING)
        exit 0

    OTHER = DIRECTIVE - (DEFINE + DEFINE_ARGS + UNDEF \
                         + IFDEF + IFNDEF + IF + ELIF + ELSE + ENDIF \
                         + INCLUDE + LINE + NNN + ERROR + WARNING + EMPTY)
    printf "\"%s\",%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", \
        FILENAME, FIXED?"fixed": "free", NUM_LINES, DIRECTIVE, \
        INCLUDE, DEFINE, DEFINE_ARGS, UNDEF, \
        IFDEF, IFNDEF, IF, ELIF, ELSE, ENDIF, \
        LINE, NNN, ERROR, WARNING, EMPTY, OTHER, \
        CONTINUE, HASH, HASH_HASH, INDENT, IFBANG, FYPP, \
        HOLLERITH
}
