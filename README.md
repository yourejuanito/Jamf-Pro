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
