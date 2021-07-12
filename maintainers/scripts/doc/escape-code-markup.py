#! /usr/bin/env nix-shell
#! nix-shell -I nixpkgs=channel:nixos-unstable -i python3 -p python3 -p python3.pkgs.lxml

"""
Pandoc will strip any markup within code elements so
let’s escape them so that they can be handled manually.
"""

import lxml.etree as ET
import sys

assert len(sys.argv) >= 3, "usage: escape-code-markup.py <input> <output>"


def replace_element_by_text(el, text):
    """
    Author: bernulf
    Source: https://stackoverflow.com/a/10520552/160386
    SPDX-License-Identifier: CC-BY-SA-3.0
    """
    text = text + (el.tail or "")
    parent = el.getparent()
    if parent is not None:
        previous = el.getprevious()
        if previous is not None:
            previous.tail = (previous.tail or "") + text
        else:
            parent.text = (parent.text or "") + text
        parent.remove(el)


ns = {
    "db": "http://docbook.org/ns/docbook",
}

# List of elements that pandoc’s DocBook reader strips markup from.
# https://github.com/jgm/pandoc/blob/master/src/Text/Pandoc/Readers/DocBook.hs
code_elements = [
    # CodeBlock
    "literallayout",
    "screen",
    "programlisting",
    # Code (inline)
    "classname",
    "code",
    "filename",
    "envar",
    "literal",
    "computeroutput",
    "prompt",
    "parameter",
    "option",
    "markup",
    "wordasword",
    "command",
    "varname",
    "function",
    "type",
    "symbol",
    "constant",
    "userinput",
    "systemitem",
]

tree = ET.parse(sys.argv[1])
predicate = " or ".join([f"db:{el}" for el in code_elements])
for markup in tree.xpath(f"//*[{predicate}]/*", namespaces=ns):
    text = ET.tostring(markup, encoding=str)
    replace_element_by_text(markup, text)

tree.write(sys.argv[2])
