# Makefile for Fortran preprocessor statistincs.
# Requires 'gmake' as we use the .ONESHELL target to simplify
# the wanky parallel script that computes the statistics.
# (It's getting to the point where this should probably
# be pulled into a separate bash script.)

E=fortran-examples

.ONESHELL:
SHELL=/bin/bash

all: stats.csv

clean: FORCE
	rm -f stats.csv

# Compute the stats in parallel and concatenate results.
# This is awkward, but cuts the time to generate them down dramatically.
# Note that since all-fortran-files.txt is sorted, the stats-directives.csv
# file will be as well, without having to explicitly sort it.

# Calculation of N_SPLIT adds 1 to avoid a tiny file at the end.

stats.csv:	fortran-examples/all-fortran-files.txt \
		fortran-examples/bin/create-stats-file \
		bin/fpp-stats bin/fpp-stats.awk
	fortran-examples/bin/create-stats-file \
		-H fortran-examples/all-fortran-files.txt \
		bin/fpp-stats \
	| cpif "$@"
	wc -l "$@"

# Identify all variations of `#if' and `#elif' expressions.
# For each fortran file f
#     Remove all continuation lines;
#     Select `#if' and `#elif' expressions
#     Squeeze out /* ... */ comments
#     Squeeze out extra blanks
#     Sort and keep only unique entries
pp-expressions.txt:	fortran-examples/all-fortran-files.txt
	export LC_ALL=C; \
	tr '\n' '\0' <fortran-examples/all-fortran-files.txt \
	| (builtin cd fortran-examples; xargs -0 \
	      awk '{if (sub(/\\$$/,"")) printf "%s", $$0; else print $$0}') \
	| sed -E -n -e 's/^[[:space:]]*#[[:space:]]*(if|elif)[[:space:]]+(.*)/\2/p' \
	| sed -E -e 's;/\*.*\*/; ;g' \
	      -e 's/[[:space:]][[:space:]]+/ /g' \
	      -e 's/[[:space:]]$$//' \
	| sort -u > "$@"

FORCE:
