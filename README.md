# cpanel_changelog_tracker

> A command-line Perl tool for tracking cases across cPanel's official changelogs.

## What It Does

This script fetches cPanel's public changelog releases from `docs.cpanel.net` and lets you:

- **Check a specific version** for a keyword (e.g., `CPANEL-00000`)
- **Search across all versions** at once
- **Output matching versions** and the relevant changelog lines
- **Print raw changelog entries** when no search case is provided

## Installation

No external dependencies required — just standard Perl libraries (`HTTP::Tiny`).

```bash
# Clone the repo
git clone https://github.com/realtpayne/cpanel_changelog_tracker.git

# Make sure it's executable
chmod +x tracker.pl
```

## Usage

```bash
# Check a single version for a case ID (case-insensitive)
./tracker.pl 138 CPANEL-00000

# Search all versions for a case ID (case-insensitive)
./tracker.pl all CPANEL-00000

# Print raw changelog entries for a version (no search)
./tracker.pl 138
```

### Arguments

| Position | Description | Required |
|---|---|---|
| `version` | A specific cPanel release version (e.g., `138`) or `all` to search every released version | **Yes** |
| `case` | The keyword to search for. If omitted, prints all changelog entries for the given version | No |

> **Note:** The `case` argument is automatically uppercased, so `cpanel-00000` and `CPANEL-00000` are treated identically.

### Examples

```bash
# Find all versions mentioning a specific issue ID
$ ./tracker.pl all CPANEL-57994
138.0.19
Fixed CPANEL-57994: Update cpanel-unbound to 1.26.2, addressing CVE-2026-97206, CVE-2026-50106, CVE-2026-96405, CVE-2026-109125, and CVE-2026-35501.
136.0.51
Fixed CPANEL-57994: Update cpanel-unbound to 1.26.2, addressing CVE-2026-97206, CVE-2026-50106, CVE-2026-96405, CVE-2026-109125, and CVE-2026-35501.
134.0.67
Fixed CPANEL-57994: Update cpanel-unbound to 1.26.2, addressing CVE-2026-97206, CVE-2026-50106, CVE-2026-96405, CVE-2026-109125, and CVE-2026-35501.

# Print all changelog entries for version 138
$ ./tracker.pl 138
138.0.20
[Security] Security hardening. Reverting to an earlier version removes these improvements.
Fixed CPANEL-55430: Reject IP/CIDR values with a second slash, including a trailing one.
Fixed CPANEL-55979: Reject the feature list name &ldquo;0&rdquo; consistently during validation.
Fixed CPANEL-56061: Fix snapshot_prep failing on DNSOnly installs.
Fixed CPANEL-56757: Bump rpm.versions for cpanel-perl-542-b-c to 5.042007-1.cp130.
Fixed CPANEL-57573: Fix the UAPI LangPHP php_get_domain_handler function for an addon domain&rsquo;s subdomain.
Fixed CPANEL-57573: Fix &ldquo;Use of uninitialized value&rdquo; PHP-FPM warnings for addon and parked domains.
Fixed CPANEL-57573: Fix the UAPI LangPHP php_set_vhost_versions function reporting addon subdomains and parked domains as changed.
Fixed CPANEL-57735: Fix license locks caused by the reported MAC address alternating between network interfaces on servers with a multipath default route.
Fixed CPANEL-57865: Fix user port assignment (used by ea-podman containers and web apps) so it is no longer limited to a single port when net.ipv4.ip_local_port_range is wide. Assigned ports are now reserved with net.ipv4.ip_local_reserved_ports.
Fixed CPANEL-57926: Update cpanel-proftpd to 1.3.9d, addressing CVE-2026-42167 and CVE-2026-44331.
Fixed CPANEL-57996: Fix expedited package updates for repositories whose IDs use package manager variables, such as EA4, and allow a trailing wildcard in published repository keys.
Fixed CPANEL-58054: Update cpanel-pdns to 5.1.5, addressing CVE-2026-73206.
138.0.19
[Security] Security hardening. Reverting to an earlier version removes these improvements.
Fixed CPANEL-56561: The hourly upcp &ndash;security cron job no longer sends its output by email.
Fixed CPANEL-57762: Fix an issue where some icons did not display in cPanel.
Fixed CPANEL-57809: Fix the nftables config save dropping the SMTP restriction tables.
Fixed CPANEL-57884: Remove unusable cPanelID links from Manage External Authentications.
....
```

## How It Works

1. **Fetches** the list of all cPanel release changelogs from
   `https://docs.cpanel.net/changelogs/releases/`

2. **For each version**, parses the HTML changelog page and extracts:
   - Version headers via `<h3 id="...">X.Y.Z</h3>`
   - Changelog entries via `<li>` elements
   - Keywords matching `Fixed`, `Improved`, or `[Security]`

3. **Searches** entries against the provided `case` argument (automatically uppercased)

4. **Outputs** matching versions and relevant changelog lines, or prints `No entries found…` if nothing matches

## Exit Codes

| Code | Meaning |
|---|---|
| `0` | Success (found matching entries, or printed changelog) |
| `1` | Not found (when `case` is provided but no match exists) |

## Troubleshooting

| Symptom | Cause |
|---|---|
| `Failed: 404 Not Found` | The cPanel changelog page may be temporarily down; retry later |
| `Usage: ...` | You forgot to pass the version argument |
| `No entries found…` | The version has no changelog entries, or the search case doesn't match any `Fixed/Improved/Security` lines |
| Perl syntax error | Make sure you're running with `perl` (e.g., `perl tracker.pl 10.4.0 CPANEL-00000`) |

---

*Author: realtpayne | Maintained for cPanel changelog tracking workflows*
