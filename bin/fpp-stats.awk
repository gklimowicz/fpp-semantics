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
        print "Eat Hollerith: Can't happen, _hi == 0" >>"/dev/stderr"
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
        # This must match output in END block.
        print "File,Lines,Directives,#define,\"#define M()\",#undef,#ifdef,#ifndef,#if,#elif,#else,#endif,#include,Continuations,#,##,Indented,fypp,Hollerith,#error,#warning,Uncategorized"
        exit 0
    }

    if (FILENAME ~ \
           /\.([Ff]|[Ff]77|[Ff][Oo][Rr]|[Ff][Tt][Nn]|[Ff][Pp][Pp]|[Ff][Tt][Nn]77)$/)
        fixed = 1
    else
        fixed = 0
}

{ NUM_LINES++ }

fixed && /^[Cc*]/ {
    # Skip fixed-format comment lines for now to avoid false positives.
    next
}

/!/ {
    # Delete comments that might have false positives.
    $0 = gensub(/!.*/, "", 1, $0)
}

# A new preprocessor line; assume not continuation until we examine further.
/^[ \t]*#[^:]/ { DIRECTIVE++; CONTINUED = 0; }
/^[ \t]*#[^#]*##/ { dprint(1, "## op '" $0 "'"); HASH_HASH++; }
/^[ \t]*#[^#]*#[^#]/ {  dprint(1, "# op '" $0 "'"); HASH++; }
/^[ \t][ \t]*#[^:]/ { INDENT++ }
/^[ \t]*#:/ { FYPP++ }
/^[ \t]*#[ \t]*include/ { INCLUDE++ }
/^[ \t]*#[ \t]*define[ \t]*[^(]/ {DEFINE++}
/^[ \t]*#[ \t]*define[ \t][ \t]*[A-Za-z_][A-Za-z0-9_]*[(]/ {DEFINE_ARGS++}

/^[ \t]*#[ \t]*undef/ { UNDEF++ }

/^[ \t]*#[ \t]*ifdef/ { IFDEF++ }
/^[ \t]*#[ \t]*ifndef/ { IFNDEF++ }
/^[ \t]*#[ \t]*if[^dn]/ { IF++ }
/^[ \t]*#[ \t]*elif/ { ELIF++ }
/^[ \t]*#[ \t]*else/ { ELSE++ }
/^[ \t]*#[ \t]*endif/ { ENDIF++ }

/^[ \t]*#[ \t]*error/ { ERROR++ }
/^[ \t]*#[ \t]*warning/ { WARNING++ }

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
/^[ \t]*#.*[\\]$/ { CONTINUE++; CONTINUED = 1 }

# A non-preprocessor line with a continuation
CONTINUED && /^[ \t]*[^#].*[\\]$/ { CONTINUE++ }

# Count # and ## operators on continued lines
CONTINUED && /^[ \t]*[^#]*##/ { HASH_HASH++; }
CONTINUED && /^[ \t]*[^#]*#[^#]/ { HASH++; }

# An un-continued line after a continuation; don't count it.
CONTINUED && /.*[^\\]$/ { CONTINUED = 0 }

END {
    UNCATEGORIZED = DIRECTIVE - (INCLUDE + DEFINE + DEFINE_ARGS + \
                   UNDEF + IFDEF + IFNDEF + IF + ELIF + ELSE + ENDIF + \
                   ERROR + WARNING)
    printf "%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", \
        FILENAME, NUM_LINES, DIRECTIVE, \
        DEFINE, DEFINE_ARGS, UNDEF, \
        IFDEF, IFNDEF, IF, ELIF, ELSE, ENDIF, \
        INCLUDE, CONTINUE, HASH, HASH_HASH, INDENT, FYPP, \
        HOLLERITH, ERROR, WARNING, UNCATEGORIZED
}
