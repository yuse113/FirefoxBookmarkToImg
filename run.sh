#!/bin/bash
dir="$0"
dir="${dir%/*}"
cd "$dir"
cp  -f 'THE_PATH_OF_places.sqlite'  "$dir/places.sqlite"
rm "$dir/bookmarks.csv"
sqlite3 "$dir/places.sqlite" <<EOS
.mode csv
.output bookmarks.csv
SELECT moz_places.url,moz_bookmarks.title,moz_bookmarks.dateadded
FROM moz_bookmarks, moz_places
WHERE moz_bookmarks.fk IS NOT NULL
AND moz_bookmarks.fk = moz_places.id
AND moz_places.url NOT LIKE 'place:%'
ORDER BY moz_bookmarks.dateadded;
.exit
EOS

mkdir -p "$dir/img"
touch "$dir/done.txt"
cd "$dir/img"
IFS=$'\n'
for line in $(cat "$dir/bookmarks.csv"); do
  dateadded="${line##*,}"
  dateadded="$(date -d @${dateadded:0:10} +"%Y-%m-%d-%T")"
  dateadded="${dateadded//:/'-'}"
  url="${line%,\"*}"
  url="${url%,*}"
  url_hash="$(echo -n $url | md5sum | sed 's/ -//g')"
  url2="${url#*://}"
  url2="${url2%%/*}"
  done="$(grep -x "$url_hash" "$dir/done.txt")"
  if [[ $done != $url_hash ]]; then
    timeout 30 pageres "$url" 1920x1080 --filename="$dateadded"_"$url2"_"$url_hash" --format='jpg' || echo "$url_hash,$url" >>"$dir/not.txt"
    echo "$url_hash" >>"$dir/done.txt"
  fi
done
