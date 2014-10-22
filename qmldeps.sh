#!/bin/bash
# Copyright (C) 2012 Jolla Oy
# Contact: Bernd Wachter <bernd.wachter@jollamobile.com>
#
# Try to locate module information for automatic provide generation from
# qmldir files as well as information about imported modules for automatic
# require generation from qml files.
#
# TODO:
# - figure out if type handling needs special attention in regard to versioning
# - stuff like Sailfish.Silica.theme currently can't get autodetected
# - implement requires generation
# - check if the regex include all valid characters allowed in module definitions
# - fine tune the regex -- they're currently not perfect, just "good enough"
#
# A note about versioning:
# A module package should provide the module in the version of the highest file
# included in the package. A package using a module should require the module
# in a version >= the one used for the import.

# grep blows up with C/POSIX locale, so make sure we're using a working locale
if [ -z "$LANG" ] || [ "$LANG" = "C" ] || [ "$LANG" = "POSIX" ] ; then
    export LANG=en_US.UTF-8
fi

case $1 in
    --provides)
        while read file; do
            case "$file" in
                */qmldir)
                    if head -1 "$file" | grep -iq '^module\s*' 2>/dev/null; then
                        provides="`head -1 ${file} | sed -r 's/^module\s+//'`"
                        version="`grep -i -E -o '^[a-z]*\s+[0-9.]*\s+[a-z0-9]*.qml' ${file} | awk '{print $2}' | sort -r | uniq | head -1`"
                        if [ -z "$version" ]; then
                            echo "qmldeps: WARNING: no version number found, package version will be used." >&2
                            echo "qml($provides)"
                        else
                            echo "qml($provides) = $version"
                        fi
                    else
                        echo "qmldeps: no valid module definition found in $file" >&2
                    fi
                    ;;
            esac
        done
        ;;
    --requires)
        while read file; do
            case "$file" in
                *.qml)
                    # this first part is some hack to avoid depending on own provides
                    # for modules
                    qmldir=`echo ${file}|sed 's,/[^/]*$,,'`
                    qmldir_noprivate=`echo ${file}|sed 's,private/[^/]*$,,'`
                    if [ -f $qmldir/qmldir ]; then
                        module=`head -1 $qmldir/qmldir | sed -r 's/^.*\s+//'`
                    elif [ -f $qmldir_noprivate/qmldir ]; then
                        module=`head -1 $qmldir_noprivate/qmldir | sed -r 's/^.*\s+//'`
                    fi
                    IFS=$'\n'
                    imports=`grep -i -E -o '^\s*import\s+[a-z0-9.]*\s+[0-9.]*' ${file} | sed -r -e 's/^\s*import\s*//' | sort | uniq`
                    if [ -z "$imports" ]; then
                        echo "qmldeps: no imports found in $file. Probably should not happen." >&2
                    fi
                    for i in $imports; do
                        import=`echo $i | awk '{ print $1 }'`
                        import_version=`echo $i | awk '{ print $2 }'`
                        if [ $import = "$module" ]; then
                            echo "qmldeps: skipping provide for own module '$module' in $file" >&2
                        elif echo $import | grep -q '\.private$'; then
                            echo "qmldeps: skipping private import '$import' in $file" >&2
                        else
                            # remove the >&2 to enable provides generation as well
                            echo "qml($import) >= $import_version" >&2
                        fi
                    done
                    ;;
                esac
            done
        ;;
esac
