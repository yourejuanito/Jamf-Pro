#!/bin/bash

########
#
# Created by Juan Garcia
# v1.0
#
# This script leverages using swift dialog to prompt the user
# to select their site from a static list created in line 23.
# Working on having v2 pull the json via the Jamf API and parse
# it out into the drop down, this is currently a limitation within
# SwiftDialog therefore the static option was to be used.
#
########

########################################
# CONFIG
#
# For Jamf pro usage utilize the parameters 4-7 this adds a layer
# of security to your api access credentials. It also a good idea
# to update the Parameter Values when you're uploading the script
# to jamf.
########################################

jamfURL=$4
client_id=$5
client_secret=$6
plistPath=$7

dialogBinary="/usr/local/bin/dialog"

# Static mapping (Name → ID)
siteNames=(
"Site 1"
"Site 2"
"..."

)
siteIDs=(1 2 ...)

########################################
# SORT lists A→Z (keep IDs aligned)
########################################
sortedIdx=($(for i in "${!siteNames[@]}"; do echo "$i:${siteNames[$i]}"; done | sort -t: -k2,2 | cut -d: -f1))
sortedNames=(); sortedIDs=()
for i in "${sortedIdx[@]}"; do
  sortedNames+=("${siteNames[$i]}")
  sortedIDs+=("${siteIDs[$i]}")
done

########################################
# FUNCTIONS
########################################
getBearerToken() {
  resp=$(curl -sS -L -X POST "${jamfURL}/api/oauth/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "client_id=${client_id}" \
    --data-urlencode "client_secret=${client_secret}" \
    --data-urlencode "grant_type=client_credentials")
  token=$(echo "$resp" | jq -r '.access_token // empty')
  if [[ -z "$token" ]]; then
    echo "❌ Token error:"; echo "$resp"; exit 1
  fi
  echo "$token"
}

getDetailETag() {
  local compID="$1" token="$2"
  curl -sS -I -L \
    -H "Authorization: Bearer $token" \
    -H "Accept: application/json" \
    "${jamfURL}/api/v1/computers-inventory-detail/${compID}" \
  | awk -F': ' '/^ETag:/{print $2}' | tr -d $'\r'
}

assignSiteToComputer() {
  local compID="$1" siteID="$2" token="$3"

  # JSON Merge Patch body Jamf accepts on your tenant:
  # {"general":{"siteId": <int>}}
  payload=$(jq -n --argjson sid "$(printf '%d' "$siteID")" '{general:{siteId:$sid}}')

  # Optional (recommended): conditional update with ETag
  etag=$(getDetailETag "$compID" "$token")

  echo "🌐 PATCH ${jamfURL}/api/v1/computers-inventory-detail/${compID}"
  echo "📦 Payload: $payload"
  [[ -n "$etag" ]] && echo "🔖 If-Match: $etag"

  tmp=$(mktemp)
  if [[ -n "$etag" ]]; then
    code=$(curl -sS -L --fail-with-body -o "$tmp" -w "%{http_code}" \
      -X PATCH "${jamfURL}/api/v1/computers-inventory-detail/${compID}" \
      -H "Authorization: Bearer $token" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -H "If-Match: $etag" \
      -d "$payload" --http1.1) || curlExit=$?
  else
    code=$(curl -sS -L --fail-with-body -o "$tmp" -w "%{http_code}" \
      -X PATCH "${jamfURL}/api/v1/computers-inventory-detail/${compID}" \
      -H "Authorization: Bearer $token" \
      -H "Accept: application/json" \
      -H "Content-Type: application/json" \
      -d "$payload" --http1.1) || curlExit=$?
  fi

  echo "📥 HTTP $code"
  if [[ "${curlExit:-0}" != "0" ]]; then
    echo "❌ curl failed (exit $curlExit). Body:"; cat "$tmp"; rm -f "$tmp"; exit 1
  fi
  if [[ "$code" == "200" || "$code" == "204" ]]; then
    echo "✅ Site set to ID $siteID"
  else
    echo "❌ Update failed. Body:"; cat "$tmp"; rm -f "$tmp"; exit 1
  fi
  rm -f "$tmp"
}

########################################
# MAIN
########################################
# Pull IDs from local plist (your requirement)
jssID=$(defaults read "$plistPath" jssID 2>/dev/null)
serialNumber=$(defaults read "$plistPath" serialNumber 2>/dev/null)
if [[ -z "$jssID" || "$jssID" == "null" ]]; then
  echo "❌ jssID not found in $plistPath"; exit 1
fi

# Build dropdown list
IFS=, selectValues="${sortedNames[*]}"; unset IFS

# SwiftDialog dropdown → JSON output
"$dialogBinary" \
  --title "Corporate Computer Site Assignment" \
  --icon computer --overlayicon SF=arrowshape.turn.up.right.circle --iconsize 200 -s \
  --message "Choose a site from the drop down list below for this macOS based on the region the user is assinged to. \n \n  (i.e. North America, Europe, Asia, South America, etc):" \
  --selecttitle "Site:" \
  --selectvalues "$selectValues" \
  --button1text "Assign" \
  --button2text "Cancel" \
  --json > /tmp/dialogOut.json

selected=$(jq -r '.SelectedOption1 // .SelectedOption // .SelectedValue // ""' /tmp/dialogOut.json)
exitCode=$(jq -r '.exitCode // .ExitCode // 0' /tmp/dialogOut.json)
rm /tmp/dialogOut.json

if [[ "$exitCode" != "0" ]]; then echo "🚫 Cancelled."; exit 0; fi
if [[ -z "$selected" ]]; then echo "❌ No site selected."; exit 1; fi
# Normalize (strip any stray quotes/whitespace)
selected=$(echo "$selected" | sed -E 's/^"(.*)"$/\1/' | sed -E 's/^[[:space:]]+|[[:space:]]+$//')

# Map name → ID
idx=-1
for i in "${!sortedNames[@]}"; do
  [[ "${sortedNames[$i]}" == "$selected" ]] && idx=$i && break
done
if [[ $idx -eq -1 ]]; then echo "❌ Could not map site: $selected"; exit 1; fi
siteID="${sortedIDs[$idx]}"

echo "🖥 jssID: $jssID"
echo "🏷️ Selected: $selected (ID: $siteID)"

token=$(getBearerToken)
assignSiteToComputer "$jssID" "$siteID" "$token"

# this writes out a file to the JAMF directory that can be leveraged as a watch path
echo "✅ Site \"$selected\" assigned to device ${serialNumber:-"(unknown serial)"}." > /Library/Application\ Support/JAMF/sdSiteAssignment.txt
