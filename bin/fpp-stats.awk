function dprint (s) {
    if (0)
        print s >>"/dev/stderr"
}

BEGIN {
    if (FILENAME ~ /\.[Ff]$/)
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
/^[ \t]*#[^#]*##/ { HASH_HASH++; }
/^[ \t]*#[^#]*#[^#]/ { HASH++; }
/^[ \t][ \t]*#[^:]/ { INDENT++ }
/^[ \t]*#:/ { FYPP++ }
/^#[ \t]*include/ { INCLUDE++ }
/^#[ \t]*define[ \t]*[^(]/ {DEFINE++}
/^#[ \t]*define[ \t][ \t]*[A-Za-z_][A-Za-z0-9_]*[(]/ {DEFINE_ARGS++}

/^#[ \t]*undef/ { UNDEF++ }

/^#[ \t]*ifdef/ { IFDEF++ }
/^#[ \t]*ifndef/ { IFNDEF++ }
/^#[ \t]*if[^d]/ { IF++ }
/^#[ \t]*elif/ { ELIF++ }
/^#[ \t]*else/ { ELSE++ }
/^#[ \t]*endif/ { ENDIF++ }

/^#[ \t]*error/ { ERROR++ }
/^#[ \t]*warning/ { WARNING++ }

/^ *[0-9]* *[Ff][Oo][Rr][Mm][Aa][Tt] *\(.*[0-9][0-9]*[Hh]/ { HOLLERITH++ }
/^ *[0-9]* *[Dd][Aa][Tt][Aa].*\/.*[0-9][0-9]*[Hh]/ { HOLLERITH++ }

# A directive with a continuation line
/^[ \t]*#.*[\\]$/ { CONTINUE++; CONTINUED = 1; dprint($0) }

# A non-preprocessor line with a continuation
CONTINUED && /^[ \t]*[^#].*[\\]$/ { CONTINUE++; dprint($0)}

# An un-continued line after a continuation; don't count it.
CONTINUED && /.*[^\\]$/ { CONTINUED = 0; dprint($0) }

END {
    UNCATEGORIZED = DIRECTIVE - (INCLUDE + DEFINE + DEFINE_ARGS + \
                   UNDEF + IFDEF + IFNDEF + IF + ELIF + ELSE + ENDIF + \
                   ERROR + WARNING)
    printf "%s,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", \
        FILENAME, NUM_LINES, DIRECTIVE, CONTINUE, INDENT, FYPP, INCLUDE, \
        DEFINE, DEFINE_ARGS, UNDEF, \
        IFDEF, IFNDEF, IF, ELIF, ELSE, ENDIF,   \
        HASH, HASH_HASH, HOLLERITH, \
        ERROR, WARNING, UNCATEGORIZED
}
