# Corporate Computer Site Assignment Script

## Overview
This Bash script allows IT administrators to assign a **Jamf-managed macOS device** to a specific **Site** using [SwiftDialog](https://github.com/bartreardon/swiftDialog) for the user interface.  

Instead of dynamically fetching sites via the Jamf API (which SwiftDialog currently struggles to display from JSON), this **v1.0** version uses a **static, predefined list of sites** and their IDs. The selected site is then updated on the target Mac's Jamf record via the **Jamf Pro API**.

> **Author:** Juan Garcia  
> **Version:** 1.0  
> **Future Work:** v2 will replace the static site list with a dynamically fetched list from Jamf's API once SwiftDialog limitations are resolved.

---

## Features
- Displays a **drop-down list** of sites via SwiftDialog.
- Pulls **Computer ID (jssID)** and **Serial Number** from a local plist file.
- Uses Jamf's **OAuth 2.0** flow for secure API authentication.
- Sends a **PATCH** request to `/api/v1/computers-inventory-detail/{id}` to update the Site ID.
- Sorts sites **alphabetically** while keeping IDs matched.

---

## Requirements
- **macOS**
- [SwiftDialog](https://github.com/bartreardon/swiftDialog) installed at `/usr/local/bin/dialog`
- [`jq`](https://stedolan.github.io/jq/) installed for JSON parsing
- Jamf Pro instance with API access
- A local plist file containing:
  - `jssID` (Jamf Computer ID)
  - `serialNumber` (Mac serial number)
- Jamf API **Client ID** and **Client Secret**

---

## Installation
1. Install SwiftDialog:
   ```bash
   brew install --cask swift-dialog
   ```
2. Install `jq`:
   ```bash
   brew install jq
   ```
3. Place the script in your desired location (e.g., `/usr/local/bin/testingpolicy.sh`).
4. Make it executable:
   ```bash
   chmod +x /usr/local/bin/testingpolicy.sh
   ```
5. Update the **configuration variables** in the script:
   ```bash
   jamfURL="https://[yourjamfCloud].jamfcloud.com"
   client_id="[yourClientID]"
   client_secret="[yourClientSecret]"
   plistPath="[locationOfYourEndpointInformationPLIST]"
   ```

---

## Usage
Run the script manually:
```bash
sudo /bin/bash /path/to/testingpolicy.sh
```

You’ll see:
1. A SwiftDialog drop-down listing your available sites.
2. Once a site is selected, the script updates the **Site ID** in Jamf for that Mac.

---

## Example plist file
Your plist file should be located in the path set in `plistPath` and contain:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>jssID</key>
    <integer>123</integer>
    <key>serialNumber</key>
    <string>C02XXXXXXX</string>
</dict>
</plist>
```

---

## API Endpoint Used
This script uses:
```
PATCH /api/v1/computers-inventory-detail/{id}
```
Payload:
```json
{
  "general": {
    "siteId": 999
  }
}
```

---

## Known Limitations
- **Static site list** — Must be manually updated if sites change in Jamf.
- **SwiftDialog JSON limitation** — Currently cannot directly parse API-returned JSON into the drop-down.
- Requires **OAuth client credentials** to be pre-generated in Jamf.

---

## License
MIT License — Use freely, modify, and share.

---

## Credits
- [SwiftDialog by Bart Reardon](https://github.com/bartreardon/swiftDialog)
- [Jamf Pro API Documentation](https://developer.jamf.com/)
