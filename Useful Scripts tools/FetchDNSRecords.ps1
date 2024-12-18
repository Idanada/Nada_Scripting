<#
.SYNOPSIS
  This script fetches DNS records for a specified domain using the DNSClient module and exports the results to a zone file.
.DESCRIPTION
  The script prompts the user to specify a DNS server (e.g., Google or Cloudflare) and a domain name. It then fetches various DNS records, displays them in the console, and exports the results to a zone file at a user-specified location.
.PARAMETER None
  This script does not accept any parameters.
.INPUTS
  None
.OUTPUTS
  A zone file containing the DNS records of the specified domain.
.PREREQUISITES
  - Ensure PowerShell is running with administrative privileges.
  - PowerShell version 5.1 or higher.
  - DNSClient module (typically pre-installed on Windows systems).
  - .NET Framework for GUI components (for SaveFileDialog).
.NOTES
  File Name: FetchDNSRecords.ps1
  Author: Idan Nadato, CTO
  Creation Date: 2023
  Version: 1.0
  Purpose/Change: Initial version to fetch DNS records and export to a zone file.
.EXAMPLE
  .\FetchDNSRecords.ps1
#>

# Check if the DNSClient module is available
if (-not (Get-Module -ListAvailable -Name DNSClient)) {
    $response = Read-Host "The DNSClient module is not available on this system. Do you want to continue anyway? (yes/no)"
    if ($response -ne 'yes') {
        Write-Host "Exiting the script." -ForegroundColor Red
        return
    }
} else {
    # Import the DNSClient module
    Import-Module DNSClient
}

# Prompt user for the DNS server they wish to use
$dnsServer = Read-Host -Prompt 'Enter the DNS server (e.g., Google or Cloudflare)'

# Based on user's choice, set the actual DNS server address
switch ($dnsServer.ToLower()) {
    'google' { $dnsServerAddress = '8.8.8.8' }
    'cloudflare' { $dnsServerAddress = '1.1.1.1' }
    default { $dnsServerAddress = $dnsServer }
}

# Prompt user for the domain name they wish to look up
$domain = Read-Host -Prompt 'Enter the domain name'

# Initialize an array for zone file entries
$zoneFileEntries = @()

# Fetch various DNS records
$recordTypes = @('A', 'AAAA', 'CNAME', 'MX', 'TXT', 'SRV', 'NS', 'SOA')
foreach ($type in $recordTypes) {
    Write-Host ("=" * 50) -ForegroundColor Cyan
    Write-Host ("Fetching $type records for $domain") -ForegroundColor Green
    Write-Host ("=" * 50) -ForegroundColor Cyan
    try {
        $results = Resolve-DnsName -Name $domain -Type $type -Server $dnsServerAddress

        if ($results) {
            # Displaying results based on record type in the console
            $results | Format-Table -AutoSize

            # Prepare results for zone file based on record type
            foreach ($result in $results) {
                $entry = switch ($type) {
                    'A' {
                        "$($result.Name) IN A $($result.IPAddress)"
                    }
                    'AAAA' {
                        "$($result.Name) IN AAAA $($result.IPAddress)"
                    }
                    'CNAME' {
                        "$($result.Name) IN CNAME $($result.CName)"
                    }
                    'MX' {
                        "$($result.Name) IN MX $($result.Preference) $($result.NameExchange)"
                    }
                    'TXT' {
                        "$($result.Name) IN TXT `"$($result.Strings)`""
                    }
                    'SRV' {
                        "$($result.Name) IN SRV $($result.Priority) $($result.Weight) $($result.Port) $($result.NameTarget)"
                    }
                    'NS' {
                        "$($result.Name) IN NS $($result.NameServer)"
                    }
                    'SOA' {
                        "$($result.Name) IN SOA $($result.PrimaryServer) $($result.Administrator) (" +
                        " $($result.SerialNumber) $($result.RefreshInterval) $($result.RetryDelay) $($result.ExpireLimit) $($result.MinimumTTL) )"
                    }
                    default {
                        "$($result.Name) $($result.QueryType) $($result.QueryName)"
                    }
                }
                $zoneFileEntries += $entry
            }
        } else {
            Write-Host "No $type records found for $domain" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "No $type records found for $domain" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Prompt user to select the zone file save location
Add-Type -AssemblyName System.Windows.Forms
$saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
$saveFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$saveFileDialog.Filter = "Zone files (*.zone)|*.zone"
$saveFileDialog.FileName = "ZoneFile $($domain).zone"

if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $zoneFilePath = $saveFileDialog.FileName
    # Export refined results to zone file
    $zoneFileEntries | Out-File -FilePath $zoneFilePath -Encoding UTF8
    Write-Host "Results exported to $zoneFilePath" -ForegroundColor Green
} else {
    Write-Host "Zone file export cancelled by user." -ForegroundColor Yellow
}

# Wait for user input before closing the script
Read-Host -Prompt 'Press Enter to exit...'
