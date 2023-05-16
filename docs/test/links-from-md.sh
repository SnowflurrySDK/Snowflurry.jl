#!/bin/bash

# Reads a markdown file and lists the targets of all markdown links, one per
# line

sed '/^```/,/^```$/{d}' | # erase code blocks
sed 's,),)\n,g' | # add newlines after every close-paren so that downstream can assume <2 links per line
grep '\[' | # select lines of the form [text](link)
grep -v '\!\[' | # but skip lines like ![gh-replacement](link)
sed 's,[^]]*](\([^)]*\)),\1,g' # change 'stuff [text](link) other stuff' to 'link'
