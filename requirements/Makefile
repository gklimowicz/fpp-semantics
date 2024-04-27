ALL_GEN_STD = INCITS+ISO+IEC+9899-1990-6.8-from-all.org \
	INCITS+ISO+IEC+9899-1999-6.10-from-all.org \
	INCITS+ISO+IEC+9899-2011-6.10-from-all.org \
	INCITS+ISO+IEC+9899-2018-6.10-from-all.org

all:	requirements.txt ${ALL_GEN_STD}

requirements.txt:	requirements.org
	pandoc -f org -t plain requirements.org >"$@"

# 1990: Incorporate all 1990-specific text; Delete everything else.
INCITS+ISO+IEC+9899-1990-6.8-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{[0-9|]*1990[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e '/^{{[0-9|]*1990[0-9|]*=$$/d' \
            -e 's/{{[0-9|]*=[^}]*}}//g' \
	    -e '/^{{[0-9|]*=$$/,/^}}/d' \
	    -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

# 1999: Incorporate all 1999-specific text; Delete everything else.
INCITS+ISO+IEC+9899-1999-6.10-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{[0-9|]*1999[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e '/^{{[0-9|]*1999[0-9|]*=$$/d' \
            -e 's/{{[0-9|]*=[^}]*}}//g' \
	    -e '/^{{[0-9|]*=$$/,/^}}/d' \
	    -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

# 2011: Incorporate all 2011-specific text; Delete everything else.
INCITS+ISO+IEC+9899-2011-6.10-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{[0-9|]*2011[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e '/^{{[0-9|]*2011[0-9|]*=$$/d' \
            -e 's/{{[0-9|]*=[^}]*}}//g' \
	    -e '/^{{[0-9|]*=$$/,/^}}/d' \
	    -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

# 2018: Incorporate all 2018-specific text; Delete everything else.
INCITS+ISO+IEC+9899-2018-6.10-from-all.org: INCITS+ISO+IEC+9899-all-6.10.org Makefile
	sed -e 's/{{[0-9|]*2018[0-9|]*=\([^}]*\)}}/\1/g' \
	    -e '/^{{[0-9|]*2018[0-9|]*=$$/d' \
            -e 's/{{[0-9|]*=[^}]*}}//g' \
	    -e '/^{{[0-9|]*=$$/,/^}}/d' \
	    -e '/^}}/d' \
	    <INCITS+ISO+IEC+9899-all-6.10.org \
	    >"$@"

clean:
	rm -f .DS_Store *.aux *.fdb_latexmk *.fls *.log *.out *.tex \
	   ${ALL_GEN_STD}
