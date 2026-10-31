#!/bin/bash
# Download every file of a free itch.io page: fetch_itch_pack.sh owner/game
# (writes ./owner__game/). Used for the CC0 packs in assets/thirdparty/.
u=$1; o=${u%%/*}; g=${u#*/}; J=jar_${o}_${g}.txt; out=${o}__${g}; mkdir -p $out
page=$(curl -sS -c $J -b $J "https://$o.itch.io/$g")
tok=$(echo "$page" | grep -oE 'name="csrf_token" value="[^"]+"' | head -1 | sed 's/.*value="//;s/"$//')
dl=$(curl -sS -c $J -b $J -X POST --data-urlencode "csrf_token=$tok" "https://$o.itch.io/$g/download_url" | python3 -c "import sys,json;print(json.load(sys.stdin)['url'])")
dp=$(curl -sS -c $J -b $J "$dl")
echo "$dp" | python3 -c "
import sys,re,html
p=sys.stdin.read()
for m in re.finditer(r'data-upload_id=\"(\d+)\".*?<strong class=\"name\"[^>]*title=\"([^\"]+)\"', p, re.S):
    print(m.group(1), html.unescape(m.group(2)).replace(' ','_'))" > $out/list.txt
[ -s $out/list.txt ] || echo "$dp" | grep -oE 'data-upload_id="[0-9]+"' | grep -oE '[0-9]+' | sort -u | sed 's/$/ file.bin/' > $out/list.txt
while read id name; do
  url=$(curl -sS -c $J -b $J -X POST --data-urlencode "csrf_token=$tok" "https://$o.itch.io/$g/file/$id?source=view_game" | python3 -c "import sys,json;print(json.load(sys.stdin).get('url',''))")
  [ -z "$url" ] && { echo "  FAIL $u $id"; continue; }
  [ "$name" = "file.bin" ] && name="upload_$id.bin"
  curl -sSL -o "$out/$name" "$url" && echo "  $u -> $name $(du -h "$out/$name" | cut -f1)"
done < $out/list.txt
