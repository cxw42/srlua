#!/bin/sh
# gen-inc.sh: Make rules in $1, and headers in $3, based on the file list in $2.
# No parameter or filename can have a $ in it.

rm -f "$1"
rm -f "$3"

while read -r destfn modulename sourcefn ; do
    #echo "$modulename in $sourcefn -> $destfn"
    includename=`basename "$destfn"`
    echo "#include \"$includename\"" >> "$3"
    varname=`echo "LSRC_$modulename" | tr '.' '_' | tr '[a-z]' '[A-Z]'`
    echo "GENERATED_INCS += $destfn" >> "$1"
    echo "$destfn: $sourcefn gen-inc.sh" >> "$1"

    echo -ne '\t' >> "$1"	# beginning of the recipe
    echo "@echo GEN_HEADER $modulename" >> "$1"
    echo -ne '\t' >> "$1"
    echo '@gawk -- '"'"'BEGIN { print "static char *'"$varname"' =" } \
        { sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$$/,""); } \
        $$0=="--" { next } \
        (($$0 !~ /^--[^\[\]]/) && /./) { \
            gsub(/\\/,"\\\\"); \
            gsub(/"/, "\\\""); \
            print "\"" $$0 "\\n\"" \
        } \
        END { print ";" }'"'"' $< > $@' >> "$1"

    echo "srlua.o: $destfn" >> "$1"
    echo >> "$1"

    # TODO save an array of the varnames and modulenames into "$3"
    # so I can load them in a loop
done < "$2"

# vi: set ts=4 sts=4 sw=4 et ai ff=unix: #
