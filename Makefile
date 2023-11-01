E=fortran-examples

all: stats.csv

update:
	(cd fortran-examples; \
	 git pull origin main; \
	 git submodule update)

update-all: update all

stats.csv:	fortran-examples/all-fortran-files.txt Makefile bin/fpp-stats bin/fpp-stats.awk
	export HERE=`pwd`; \
	$$HERE/bin/fpp-stats -H >"$@"; \
	(builtin cd ${E} && \
	 export LC_ALL=C; \
	 cat all-fortran-files.txt \
	 | tr '\n' '\0' \
	 | xargs -0 $$HERE/bin/fpp-stats) \
	>>"$@"
	wc -l "$@"

FORCE:
