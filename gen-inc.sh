#!/bin/sh
# gen-inc.sh: Make rules in $1, and headers in $3, based on the file list in $2.
# No parameter or filename can have a $ in it.

rm -f "$1"
rm -f "$3"

varnames=()
modulenames=()
while read -r destfn modulename sourcefn ; do
    #echo "$modulename in $sourcefn -> $destfn"
    includename=`basename "$destfn"`
    echo "#include \"$includename\"" >> "$3"

    varname=`echo "LSRC_$modulename" | tr '.' '_' | tr '[a-z]' '[A-Z]'`
    varnames+=("$varname")
    modulenames+=("$modulename")

    echo "GENERATED_INCS += $destfn" >> "$1"
    echo "$destfn: $sourcefn gen-inc.sh $2" >> "$1"

    echo -ne '\t' >> "$1"	# beginning of the recipe
    echo "@echo GEN_HEADER $modulename" >> "$1"
    echo -ne '\t' >> "$1"
    echo '@gawk -- '"'"'BEGIN { print "static const char *'"$varname"' =" } \
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

done < "$2"

# Make a function to register everything.  I was getting "initializer element
# is not constant" errors when I tried to do it as data.
echo 'void register_lsources(lua_State *L) {' >> "$3"
idx=0
while [[ $idx -lt ${#varnames[@]} ]] ; do
    echo "  load_embedded_module(L, \"${modulenames[$idx]}\", ${varnames[$idx]});" >> "$3"
    idx=$(( $idx + 1 ))
done
echo '}' >> "$3"

# vi: set ts=4 sts=4 sw=4 et ai ff=unix: #
