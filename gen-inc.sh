#!/bin/bash
# gen-inc.sh: Make rules in $1, and headers in $3, based on the file list in $2.
# No parameter or filename can have a $ in it.

rm -f "$1"
rm -f "$3"

varnames=()
modulenames=()
is_manual=()
idx="-1"
mainidx=
while read -r destfn modulename sourcefn conditions ; do
    #echo "$modulename in $sourcefn -> $destfn"

    # Skip blank lines, or lines in which the first non-whitespace character
    # is a #
    if [[ -z $destfn || $destfn == '#'* ]]; then continue ; fi

    idx=$(( $idx + 1 ))

    # Remember which is called "MAIN," if any.  This one will be
    # executed directly, rather than loaded as a package.
    if [[ ${modulename} == "MAIN" ]]; then
        mainidx="$idx"
        echo "Using main routine at index $mainidx"
    fi

    if [[ $conditions == 'MANUAL' ]]; then
        is_manual+=('yes')
    else
        is_manual+=('')
        includename=`basename "$destfn"`
        echo "#include \"$includename\"" >> "$3"
    fi

    varname=`echo "LSRC_$modulename" | tr '.' '_' | tr '[a-z]' '[A-Z]'`
    varnames+=("$varname")
    modulenames+=("$modulename")

    echo "GENERATED_INCS += $destfn" >> "$1"
    echo "$destfn: $sourcefn gen-inc.sh $2" >> "$1"

    echo -ne '\t' >> "$1"	# beginning of the recipe
    echo "@echo GEN_HEADER $modulename" >> "$1"

    # Syntax-check local files
    if [[ $modulename != '/'* ]]; then
        echo -ne '\t' >> "$1"
        echo "@lua -e 'assert(loadfile(\"$sourcefn\"))'" >> "$1"
    fi

    # gawk script is: give it a variable name;
    #   omit shebang line;
    #   strip leading and trailing whitespace;
    #   omit lines with nothing but a `--`;
    #   find lines that are more than just a non-block comment, and:
    #       escape backslashes;
    #       escape double-quotes; and
    #       emit them as string literals, preserving the line break.
    #   At the end, finish off the string constant.

    echo -ne '\t' >> "$1"
    echo '@gawk -- '"'"'BEGIN { print "static const char *'"$varname"' =" } \
        (NR==1) && ($$0 ~ /^#/) { next } \
        { sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$$/,""); } \
        $$0=="--" { next } \
        (($$0 !~ /^--[^\[\]]/) && /./) { \
            gsub(/\\/,"\\\\"); \
            gsub(/"/, "\\\""); \
            print "\"" $$0 "\\n\"" \
        } \
        END { print ";" }'"'"' $< > $@' >> "$1"

    echo "srlua.o: $destfn" >> "$1"
    echo "gui-srlua.o: $destfn" >> "$1"
    echo >> "$1"

done < "$2"

# Make a function to register everything.  I was getting "initializer element
# is not constant" errors when I tried to do it as data.
echo 'void register_lsources(lua_State *L) {' >> "$3"
idx=-1
while [[ $idx -lt ${#varnames[@]} ]] ; do
    idx=$(( $idx + 1 ))     # Clumsy for(()) loop replacement on old bash
    if [[ $idx -ge ${#varnames[@]} ]] ; then break; fi

    # main is handled separately
    if [[ $mainidx && ( $mainidx -eq $idx ) ]]; then continue; fi

    # manual are also handled separately
    if [[ ${is_manual[$idx]} ]]; then continue; fi

    echo "  load_embedded_module(L, \"${modulenames[$idx]}\", ${varnames[$idx]});" >> "$3"
done
echo -e '}\n' >> "$3"

# Output the main code, if any.
if [[ $mainidx ]]; then
    echo '#define LSOURCE_HAVE_MAIN' >> "$3"
    echo 'int run_main_lsource(lua_State *L) {' >> "$3"
    echo "  return luaL_dostring(L, ${varnames[$mainidx]});" >> "$3"
    echo -e '}\n' >> "$3"

    echo 'int load_main_lsource(lua_State *L) {' >> "$3"
    echo "  if(luaL_loadstring(L, ${varnames[$mainidx]})) {" >> "$3"
    echo "    return luaL_error(L, \"Can't eval ${varnames[$mainidx]}\");" >> "$3"
    echo '  }' >> "$3"
    echo '  return 0; //no errors' >> "$3"
    echo -e '}\n' >> "$3"
fi

# vi: set ts=4 sts=4 sw=4 et ai ff=unix: #
