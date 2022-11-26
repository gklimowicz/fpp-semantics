function dprint (s) {
    if (0)
        print s >>"/dev/stderr"
}

{ L++ }

# A new preprocessor linee; assume not continuation until we examine further.
/^[ \t]*#[^:]/ { P++; CONTINUED = 0; }
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

# A directive with a continuation line
/^[ \t]*#.*[\\]$/ { CONTINUE++; CONTINUED = 1; dprint($0) }

# A non-preprocessor line with a continuation
CONTINUED && /^[ \t]*[^#].*[\\]$/ { CONTINUE++; dprint($0)}

# An un-continued line after a continuation; don't count it.
CONTINUED && /.*[^\\]$/ { CONTINUED = 0; dprint($0) }

END {
    MISSING = P - (INCLUDE + DEFINE + DEFINE_ARGS + \
                   UNDEF + IFDEF + IFNDEF + IF + ELIF + ELSE + ENDIF + \
                   ERROR + WARNING)
    printf "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", \
        L, P, CONTINUE, INDENT, FYPP, INCLUDE, DEFINE, DEFINE_ARGS,  \
        UNDEF, IFDEF, IFNDEF, IF, ELIF, ELSE, ENDIF, \
        ERROR, WARNING, MISSING
}
