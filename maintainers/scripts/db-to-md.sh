#! /usr/bin/env nix-shell
#! nix-shell -I nixpkgs=../.. -i bash -p pandoc

# This script is temporarily needed while we transition the manual to
# CommonMark. It converts DocBook files into our CommonMark flavour.

echo "WARNING: This is an experimental script and might not preserve all formatting." > /dev/stderr
echo "Please report any issues you discover." > /dev/stderr

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pushd $DIR

# NOTE: Keep in sync with Nixpkgs manual (/doc/Makefile).
# TODO: Remove raw-attribute when we can get rid of DocBook altogether.
pandoc_commonmark_enabled_extensions=+attributes+fenced_divs+footnotes+bracketed_spans+definition_lists+pipe_tables+raw_attribute
pandoc_flags=(
    # Not needed:
    # - diagram-generator.lua (we do not support that in NixOS manual to limit dependencies)
    # - media extraction (was only required for diagram generator)
    # - myst-reader/roles.lua (only relevant for MyST → DocBook)
    # - link-unix-man-references.lua (links should only be added to display output)
    "--lua-filter=$DIR/../../doc/build-aux/pandoc-filters/docbook-reader/citerefentry-to-rst-role.lua"
    "--lua-filter=$DIR/../../doc/build-aux/pandoc-filters/docbook-writer/rst-roles.lua"
    "--lua-filter=$DIR/../../doc/build-aux/pandoc-filters/docbook-writer/labelless-link-is-xref.lua"
    -f docbook
    -t "commonmark${pandoc_commonmark_enabled_extensions}+smart"
    --tab-stop=2
    --wrap=none
)

for file in "$@"; do
    if [[ ! -f "$file" ]]; then
        echo "db-to-md.sh: $file does not exist" > /dev/stderr
        exit 1
    else
    rootElement=$(xmllint --xpath 'name(//*)' "$file")

    if [[ $rootElement = chapter ]]; then
        extension=".chapter.md"
    elif [[ $rootElement = section ]]; then
        extension=".section.md"
    else
        echo "db-to-md.sh: $file contains an unsupported root element $rootElement" > /dev/stderr
        exit 1
    fi

    outFile="${file%".section.xml"}"
    outFile="${outFile%".chapter.xml"}"
    outFile="${outFile%".xml"}$extension"
    temp1=$(mktemp)
    ./escape-code-markup.py "$file" "$temp1"
    temp2=$(mktemp)
    ./replace-xrefs-by-empty-links.py "$temp1" "$temp2"
    pandoc "$temp2" -o "$outFile" "${pandoc_flags[@]}"
    echo "Converted $file to $outFile" > /dev/stderr
  fi
done

popd
