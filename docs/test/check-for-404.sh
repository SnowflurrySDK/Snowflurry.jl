#!/bin/bash

# Foreach .md file in the current directory tree, try to parse out any links
# from the markdown and verify that they should work. For external links, that
# means trying to fetch them over HTTP and verifying that they don't 404. For
# internal links, that means looking for the target file in the local directory
# tree.

find . -name '*.md' | while read fname ; do
    cat "$fname" | # foreach markdown file
        ./docs/test/links-from-md.sh | # print each markdown link target
        awk "{ print \"$fname\", \$0 }" # prepend the filename to the link target
done | sort | uniq -f 1 | {
    failure="0"

    while read fname link ; do
        # What kind of link is it?
        case "$link" in
            http://*) 
                echo 1>&2 "error: link doesn't use HTTPS: file: $fname link: $link"
                failure="1"
                ;;
            https://github.com/SnowflurrySDK/Snowflurry.jl/blob/main/*)
                # Snowflurry.jl repo-local case ... make sure file exists
                link_root=`echo "$link" | sed 's,https://github.com/SnowflurrySDK/Snowflurry.jl/blob/main/,,'`
                if [ ! -e "./$link_root" ] ; then
                    echo 1>&2 "404 error: file: $fname link: $link"
                    failure="1"
                fi
                ;;
            https*)
                # external link case ... make sure file curls
                curl --silent --fail "$link" > /dev/null || failure="1"
                ;;
            ./* | ../* | *)
                link_root=`dirname $fname`

                # Since we'll be looking for a file in a filesystem, remove URL
                # queries and fragments.
                clean_link=`echo "$link" | sed -e 's,[?#].*,,'`
                target_file="./$link_root/$clean_link"
                if [ ! -e "$target_file" ] ; then
                    echo 1>&2 "404 error: file: $fname link: $link"
                    failure="1"
                fi
                ;;
        esac
    done
    exit $failure
}
