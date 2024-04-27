ALL_STD =	INCITS+ISO+IEC+9899-1999-6.10-from-all.org \
	INCITS+ISO+IEC+9899-2011-6.10-from-all.org \
	INCITS+ISO+IEC+9899-2018-6.10-from-all.org

all:	requirements.txt ${ALL_STD}

requirements.txt:	requirements.org
	pandoc -f org -t plain requirements.org >"$@"

# 1990: Delete all changes that are strictly after 1990.
INCITS+ISO+IEC+9899-1990-6.8-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{1990[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{1999[0-9|]*=[^}]*}}//g' \
	    -e '/^{{1999[0-9|]*=$$/,/^}}/d' \
	    -e 's/{{20[12][184][0-9|]*=[^}]*}}//g' \
	    -e '/^{{20[12][184][0-9|]*=$$/,/^}}/d' \
	    -e '/^{{1990[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

# 1999: Delete all changes for 1990 and that are strictly after 1999.
INCITS+ISO+IEC+9899-1999-6.10-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{1999[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{1990=[^}]*}}//g' \
	    -e 's/{{20[12][184][0-9|]*=[^}]*}}//g' \
	    -e '/^{{1990=$$/,/^}}/d' \
	    -e 's/{{20[12][184][0-9|]*=[^}]*}}//g' \
	    -e '/^{{20[12][184][0-9|]*=$$/,/^}}/d' \
	    -e '/^{{1999[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

# 2011: Delete strictly 1999 changes and changes strictly after 2011.
INCITS+ISO+IEC+9899-2011-6.10-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{1999=\([^}]*\)}}//g' \
	    -e 's/{{[0-9|]*2011[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{2018[0-9|]*=[^}]*}}//g' \
	    -e '/^{{1999=$$/,/^}}/d' \
	    -e '/^{{2018[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{2024[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{[0-9|]*2011[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

# 2018: Delete strictly 1999, 2011 changes and changes strictly after 2018.
INCITS+ISO+IEC+9899-2018-6.10-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{1999=\([^}]*\)}}//g' \
	    -e 's/{{[0-9|]*2011=\([^}]*\)}}//g' \
	    -e 's/{{[0-9|]*2018[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e 's/{{2024[0-9|]*=[^}]*}}//g' \
	    -e '/^{{1999=$$/,/^}}/d' \
	    -e '/^{{[0-9|]*2011=$$/,/^}}/d' \
	    -e '/^{{2024[0-9|]*=$$/,/^}}/d' \
	    -e '/^{{[0-9|]*2018[0-9|]*=$$/d' -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

clean:
	rm -f .DS_Store *.aux *.fdb_latexmk *.fls *.log *.out *.tex ${ALL_STD}
