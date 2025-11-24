# Renovate - Renovate Package Blocklist for Zero-day Events

## Overview

This folder contains Renovate package rules to protect against specific zero-day events. The configuration provided prevent Renovate from recommending upgrades to compromised package versions.

The Renovate presets are named following the given zero-day event. Below are details for each zero-day event covered.


## Sha1-Hulud Attack

Sha1-Hulud is a zero-day supply chain attack targeting the npm ecosystem. More infomration can be found [here](https://www.mend.io/blog/shai-hulud-the-second-coming/)

### Files

`renovate-sha1-hulud-blocklist.json` - Renovate configuration with package rules to block affected versions

### Package Rules Strategy

The `renovate-sha1-hulud-blocklist.json` file implements two blocking strategies:

### 1. Version-Specific Blocks
For packages with identified compromised versions, the rules use `allowedVersions` with regex patterns to block specific versions:

```json
{
  "matchPackageNames": ["@zapier/zapier-sdk"],
  "allowedVersions": "!/^(0\\.15\\.[567])$/"
}
```

### 2. Complete Blocking
For packages without version information (potentially fully compromised), updates are completely disabled:

```json
{
  "matchPackageNames": ["crypto-addr-codec"],
  "enabled": false
}
```

## How to Use

### Option 1: Extend in your Renovate config

Add to your `renovate.json`:

```json
{
  "extends": ["local>path/to:renovate-sha1-hulud-blocklist"]
}
```
