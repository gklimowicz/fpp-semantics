# Makefile for Fortran preprocessor statistincs.
# Requires 'gmake' as we use the .ONESHELL target to simplify
# the wanky parallel script that computes the statistics.
# (It's getting to the point where this should probably
# be pulled into a separate bash script.)

E=fortran-examples

.ONESHELL:
SHELL=/bin/bash

all: stats.csv all-fpp-conditional-expressions.txt \
	all-comment-directives.txt

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
# for each fortran file f
#     Remove all continuation lines;
#     Select `#if' and `#elif' expressions
#     Squeeze out /* ... */ comments
#     Squeeze out extra blanks
#     Sort and keep only unique entries
all-fpp-conditional-expressions.txt:	$E/all-fortran-files.txt
	export LC_ALL=C; \
	tr '\n' '\0' <$E/all-fortran-files.txt \
	| (builtin cd $E; xargs -0 \
	      awk '{if (sub(/\\$$/,"")) printf "%s", $$0; else print $$0}') \
	| sed -E -n -e 's/^[[:space:]]*#[[:space:]]*(if|elif)[[:space:]]+(.*)/\2/p' \
	| sed -E -e 's;/\*.*\*/; ;g' \
	      -e 's/[[:space:]][[:space:]]+/ /g' \
	      -e 's/[[:space:]]$$//' \
	| sort --ignore-case -u > "$@"

# Identify all compiler directives embedded in
# Fortran comment lines. We are looking for `!$word'
# and `!word$'. In fixed-form, the `word' is probably only
# three characters long.
#
# (for each fixed-format Fortran file f
#      Remove all non-comment lines
#      Print directive from all comment lines that look like directives
#  for each free-format Fortran file f
#      Remove all lines that do not begin with a comment
#      Print directive from all comment lines that look like directives)
# | (Downcase everything
#    check directives again (unnecessary)
#    sort and print unique entries)
all-comment-directives.txt: $E/all-fortran-files-fixed.txt \
	             $E/all-fortran-files-free.txt
	(export LC_ALL=C; \
	 builtin cd $E \
	 && cat all-fortran-files-fixed.txt \
	 | tr '\n' '\0' \
	 | xargs -0 gawk '/^[^CcDd*]/ { next } \
	                /^.[a-zA-Z][a-zA-Z][a-z]A-Z][$$]/ { print substr($$1,2,4); next } \
	                /^.[$$][a-zA-Z][a-zA-Z][a-zA-Z]*/ { print substr($$1,2.4); next }'; \
	 cat all-fortran-files-free.txt \
	 | tr '\n' '\0' \
	 | xargs -0 gawk '/^[^ ]*!/ { next } \
	                /^ *[^!]*$$/ { next } \
			$$1 ~ /^![a-zA-Z][a-zA-Z]*[$$]/ { print substr($$1,2,4) } \
	                $$1 ~ /^![$$][a-zA-Z][a-zA-Z]*/ { print substr($$1,2) }') \
	| (export LC_ALL=C; \
	   tr -d ' ' \
	   | tr '[[:upper:]]' '[[:lower:]]' \
	   | sort -u) > "$@"

#	   | gawk '/^[$$][a-zA-Z][a-zA-Z][a-zA-Z]*/ \
#	            || /^[a-zA-Z][a-zA-Z][a-zA-Z][$$]/ \
#	            || /^[a-zA-Z][a-zA-Z][$$]/ { print }' \

FORCE:
