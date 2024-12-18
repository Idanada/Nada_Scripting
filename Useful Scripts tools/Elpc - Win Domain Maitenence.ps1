<#
.SYNOPSIS
This script provides a management and reporting tool for user and computer accounts within an Active Directory environment, along with additional diagnostic checks for the Domain Controller.

.DESCRIPTION
The script offers a menu-driven interface for performing management tasks and generating reports for:
- User Management: Manage and report on user accounts, including locked-out users, users with ADMINISTRATOR privileges, and detailed user account information including the last logon date.
- Computer Management: Manage and report on computer accounts, including the quantity of computers and detailed computer account information.
- DCDiag: Run diagnostic tests on the domain controller.
- Replication Status: Check replication status between DCs.
- SYSVOL Share Check: Verify SYSVOL share status.
- DNS Configuration: Check DNS configuration and status.
- FSMO Roles: Check the status of the FSMO Roles.
- Event Logs: Review Active Directory-related event logs.
- Kerberos Tickets: Check the status of Kerberos Tickets (with compatibility across all Windows Server versions).
- GPO Health: Review GPO permissions and settings.
- Shadow Copy: Check the status of Shadow Copies on all fixed drives.
- Check Windows Updates: Check and report available Windows updates.
- Run All Checks: Perform all available checks and generate reports in a consolidated manner.

.PREREQUISITES
- PowerShell 5.1 or higher.
- Active Directory module for Windows PowerShell.
- PSWindowsUpdate module.
- DCDiag installed for running diagnostic checks.
- Appropriate permissions to query Active Directory objects.
- The script should be run from a computer that has the Remote Server Administration Tools (RSAT) installed or directly from a Domain Controller (DC) to ensure access to all necessary features.

.NOTES
Author: Idan Nadato
Version: 1.8
Date: 09/25/2024
#>

# Global variables to store user choices for logging and file saving
$global:saveResults = $false
$global:saveFolderPath = ""

# Function to prompt for log file saving location once
function Get-UserFilePathChoice {
    if (-not $global:saveFolderPath) {
        $savePrompt = Read-Host "Would you like to save the results to a file? (Yes/No)"
        if ($savePrompt -eq 'Yes') {
            $global:saveResults = $true

            # Get the current date and format it
            $currentDate = Get-Date -Format "yyyy-MM-dd"

            # Define the folder path with the current date appended
            $global:saveFolderPath = "C:/Elpc - Win Domain Maintenance_$currentDate"

            # Check if the directory exists, if not create it
            if (-not (Test-Path -Path $global:saveFolderPath)) {
                New-Item -Path $global:saveFolderPath -ItemType Directory | Out-Null
                Write-Host "Directory created at $global:saveFolderPath" -ForegroundColor Green
            } else {
                Write-Host "Saving to existing directory $global:saveFolderPath" -ForegroundColor Green
            }
        }
    }
}

# Function for logging messages
function Write-Log {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][string]$LogFile
    )
    if ($global:saveResults) {
        # Ensure the log file is saved inside the specified folder
        $LogFile = Join-Path -Path $global:saveFolderPath -ChildPath "Elpc - Win Domain MaintenanceADManagementLog.txt"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp - $Message"
        Add-Content -Path $LogFile -Value $logMessage
    }
}

# Menu display function
function Show-Menu {
    param (
        [string]$Title = 'Welcome to ELPC - Domain Maintenance'
    )
    Clear-Host
    Write-Host "================ $Title ================" -ForegroundColor Cyan
    Write-Host "1: User Management - Manage and report on user accounts." -ForegroundColor Green
    Write-Host "2: Computer Management - Manage and report on computer accounts." -ForegroundColor Green
    Write-Host "3: DCDiag - Run diagnostic tests on the domain controller." -ForegroundColor Green
    Write-Host "4: Replication Status - Check replication status between DCs." -ForegroundColor Green
    Write-Host "5: SYSVOL Share Check - Verify SYSVOL share status." -ForegroundColor Green
    Write-Host "6: DNS Configuration - Check DNS configuration and status." -ForegroundColor Green
    Write-Host "7: FSMO Roles - Check the status of FSMO roles." -ForegroundColor Green
    Write-Host "8: Event Logs - Check AD-related event logs." -ForegroundColor Green
    Write-Host "9: Kerberos Tickets - Check Kerberos ticket status (supports multiple server versions)." -ForegroundColor Green
    Write-Host "10: GPO Health - Review GPO permissions and settings." -ForegroundColor Green
    Write-Host "11: Check Shadow Copy Status - Check shadow copies on fixed drives." -ForegroundColor Green
    Write-Host "12: Check Windows Updates - Check for available Windows updates." -ForegroundColor Green
    Write-Host "R: Run All Checks - Perform all checks and manage reports." -ForegroundColor Yellow
    Write-Host "Q: Exit - Exit the script." -ForegroundColor Yellow
}

# Function to export results to a file with UTF-8 encoding, with default FileType if not provided
function Export-Results {
    param (
        [Parameter(Mandatory=$true)][object]$Data,
        [Parameter(Mandatory=$false)][string]$Description = "Exported Results",
        [Parameter(Mandatory=$false)][string]$FileType = "CSV",  # Set default FileType as CSV
        [Parameter(Mandatory=$true)][string]$FileName
    )

    if ($global:saveResults) {
        $fullPath = $global:saveFolderPath + "\" + $FileName + "." + $FileType.ToLower()

        if ($FileType -eq 'CSV') {
            $Data | Export-Csv -Path $fullPath -NoTypeInformation -Encoding UTF8
        } elseif ($FileType -eq 'TXT') {
            $Data | Out-File -FilePath $fullPath -Encoding UTF8
        }

        Write-Host "Results successfully exported to $fullPath" -ForegroundColor Green
        Write-Log "Results exported to $fullPath"
    }
}

# Function to check and install PSWindowsUpdate and NuGet package provider
function Install-PSWindowsUpdate {
    $ModuleName = 'PSWindowsUpdate'
    
    # Check if NuGet is installed, if not, install it
    if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
        Write-Host "NuGet package provider not found. Installing..." -ForegroundColor Yellow
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
            Write-Host "NuGet package provider installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to install NuGet package provider. Check internet connectivity or permissions." -ForegroundColor Red
            return
        }
    }

    # Check if PSWindowsUpdate is installed, if not, install it
    if (-not (Get-Module -Name $ModuleName -ListAvailable)) {
        Write-Host "$ModuleName not found. Installing..." -ForegroundColor Yellow
        try {
            Install-Module -Name $ModuleName -Force -Scope CurrentUser
            Write-Host "$ModuleName module installed successfully." -ForegroundColor Green
        } catch {
            Write-Host "Failed to install $ModuleName module. Check internet connectivity or permissions." -ForegroundColor Red
            return
        }
    }
}

# Function to check Windows updates
# Checks for available Windows updates and lists them. Critical for security patching.
function Check-WindowsUpdates {
    Install-PSWindowsUpdate  # Ensure PSWindowsUpdate is installed
    Write-Host "Checking for available Windows updates..." -ForegroundColor Cyan
    $updates = Get-WUList
    if ($updates) {
        Write-Host "The following updates are available:" -ForegroundColor Cyan
        $updates | Format-Table -AutoSize
        Export-Results -Data $updates -Description "Windows Updates" -FileType "TXT" -FileName "WindowsUpdates"
    } else {
        Write-Host "No updates available." -ForegroundColor Green
    }
}

# Function to show users with administrator privileges
# Checks for users in important security groups like Domain Admins, Administrators, and others.
# This is crucial to ensure that only authorized personnel have elevated permissions.
function Show-AdminUsers {
    Write-Host "Checking for users with admin privileges..." -ForegroundColor Cyan
    $adminGroups = @("Domain Admins", "Enterprise Admins", "Administrators", "Schema Admins")
    $adminUsers = @()

    foreach ($groupName in $adminGroups) {
        try {
            $group = Get-ADGroup -Filter { Name -eq $groupName } -ErrorAction Stop
            $groupMembers = Get-ADGroupMember -Identity $group -ErrorAction Stop
     foreach ($member in $groupMembers) {
                if ($member.objectClass -eq 'user') {
                    $user = Get-ADUser -Identity $member.DistinguishedName -Properties DisplayName, LastLogonDate -ErrorAction SilentlyContinue
                    if ($user) {
                        $adminUsers += [PSCustomObject]@{
                            DisplayName = $user.DisplayName
                            SamAccountName = $user.SamAccountName
                            LastLogonDate = if ($user.LastLogonDate) { $user.LastLogonDate.ToString("g") } else { "Never" }
                            GroupName = $groupName
                        }
                    }
                }
            }
        } catch {
            Write-Host "Error querying group: $groupName" -ForegroundColor Red
        }
    }

    if ($adminUsers.Count -eq 0) {
        Write-Host "No users with admin privileges found." -ForegroundColor Green
    } else {
        $adminUsers | Format-Table -AutoSize | Out-String | Write-Host
        Export-Results -Data $adminUsers -Description "Admin Users" -FileType "CSV" -FileName "AdminUsers"
    }
}

# Function to show locked out users
# This function identifies any user accounts that are currently locked out. It's important for troubleshooting user access issues.
function Show-LockedOutUsers {
    Write-Host "Checking for locked out users..." -ForegroundColor Cyan
    $lockedOutUsers = Search-ADAccount -LockedOut -UsersOnly
    if ($lockedOutUsers) {
        $lockedOutUsers | Format-Table DisplayName, SamAccountName -AutoSize
        Export-Results -Data $lockedOutUsers -Description "Locked Out Users" -FileType "TXT" -FileName "LockedOutUsers"
    } else {
        Write-Host "No locked out users found." -ForegroundColor Green
    }
}

# Function to show detailed user information
# This gathers information on all user accounts, including their display names and last logon dates. Useful for auditing inactive accounts.
function Show-UserDetails {
    Write-Host "Fetching detailed user account information..." -ForegroundColor Cyan
    $userDetails = Get-ADUser -Filter * -Property DisplayName, SamAccountName, LastLogonDate
    $output = $userDetails | Select-Object DisplayName, SamAccountName, LastLogonDate

    if ($global:saveResults) {
        $output | Export-Csv -Path "$global:saveFolderPath\UserDetails.csv" -NoTypeInformation -Encoding UTF8
        Write-Host "User details saved to UserDetails.csv." -ForegroundColor Green
    } else {
        $output | Format-Table -AutoSize
    }
}

# Function to manage computer accounts
# This function reports on all computer objects within Active Directory, including their last logon dates. This helps identify inactive or decommissioned systems.
function Computer-Management {
    Write-Host "Fetching detailed computer account information..." -ForegroundColor Cyan
    $computerDetails = Get-ADComputer -Filter * -Property Name, LastLogonDate
    $output = $computerDetails | Select-Object Name, LastLogonDate

    if ($global:saveResults) {
        $output | Export-Csv -Path "$global:saveFolderPath\ComputerDetails.csv" -NoTypeInformation -Encoding UTF8
        Write-Host "Computer details saved to ComputerDetails.csv." -ForegroundColor Green
    } else {
        $output | Format-Table -AutoSize
    }
}

# Function to run DCDiag check
# Runs diagnostic tests on the Domain Controller. This is essential for identifying potential issues with the domain services.
function Run-DCDiag {
    Write-Host "Running DCDiag..." -ForegroundColor Cyan
    $dcDiagResults = dcdiag /v
    $dcDiagResults | Out-String | Write-Host
    Export-Results -Data $dcDiagResults -Description "DCDiag Results" -FileType "TXT" -FileName "DCDiagResults"
}

# Function to check replication status between DCs
# Ensures that replication between Domain Controllers is functioning correctly. Replication issues can cause severe problems in multi-DC environments.
function Check-ReplicationStatus {
    Write-Host "Checking Replication Status..." -ForegroundColor Cyan
    $replicationStatus = repadmin /showrepl
    $replicationStatus | Out-String | Write-Host
    Export-Results -Data $replicationStatus -Description "Replication Status" -FileType "TXT" -FileName "ReplicationStatus"
}

# Function to check SYSVOL share status
# Checks that the SYSVOL share is correctly available. The SYSVOL folder is vital for storing group policy and login script data.
function Check-SYSVOL {
    Write-Host "Checking SYSVOL Share Status..." -ForegroundColor Cyan
    $sysvolStatus = Get-ChildItem \\$env:COMPUTERNAME\SYSVOL
    $sysvolStatus | Out-String | Write-Host
    Export-Results -Data $sysvolStatus -Description "SYSVOL Share Status" -FileType "TXT" -FileName "SYSVOLStatus"
}

# Function to check DNS configuration and query DNS servers
# Verifies that the DNS configuration is correct and that DNS servers are responding as expected.
function Check-DNS {
    Write-Host "Checking DNS Configuration..." -ForegroundColor Cyan
    
    # Get DNS zones on the server
    $dnsZones = Get-DnsServerZone
    $dnsZones | Out-String | Write-Host
    Export-Results -Data $dnsZones -Description "DNS Zones" -FileType "TXT" -FileName "DNSZones"
    
    # Get DNS servers configured on network adapters
    $dnsServers = Get-DnsClientServerAddress -AddressFamily IPv4 | Select-Object -ExpandProperty ServerAddresses
    
    if ($dnsServers) {
        Write-Host "`nQuerying configured DNS servers..." -ForegroundColor Cyan
        foreach ($dnsServer in $dnsServers) {
            Write-Host "Checking DNS server: $dnsServer" -ForegroundColor Yellow

            # Test ping to DNS server
            $pingResult = Test-Connection -ComputerName $dnsServer -Count 1 -ErrorAction SilentlyContinue
            if ($pingResult.StatusCode -eq 0) {
                Write-Host "Ping to DNS server $dnsServer successful." -ForegroundColor Green
            } else {
                Write-Host "Ping to DNS server $dnsServer failed." -ForegroundColor Red
            }

            # Test DNS query to server
            try {
                $dnsQueryResult = Resolve-DnsName -Name "google.com" -Server $dnsServer -ErrorAction Stop
                Write-Host "DNS query to $dnsServer was successful: $($dnsQueryResult.NameHost)" -ForegroundColor Green
            } catch {
                Write-Host "DNS query to $dnsServer failed." -ForegroundColor Red
            }
        }
    } else {
        Write-Host "No DNS servers configured on network adapters." -ForegroundColor Red
    }

    # Log DNS server details
    Export-Results -Data $dnsServers -Description "DNS Server Addresses" -FileType "TXT" -FileName "DNSServerAddresses"
}

# Function to check FSMO roles
# Retrieves and reports on all FSMO (Flexible Single Master Operations) roles. These roles are essential for the proper functioning of Active Directory.
function Check-FSMORoles {
    Write-Host "Checking FSMO Roles..." -ForegroundColor Cyan
    try {
        # Retrieve FSMO roles from both domain and forest levels
        $domainRoles = Get-ADDomain | Select-Object PDCEmulator, InfrastructureMaster, RIDMaster
        $forestRoles = Get-ADForest | Select-Object SchemaMaster, DomainNamingMaster

        # Combine the results
        $roles = [PSCustomObject]@{
            PDCEmulator         = $domainRoles.PDCEmulator
            InfrastructureMaster = $domainRoles.InfrastructureMaster
            RIDMaster           = $domainRoles.RIDMaster
            SchemaMaster        = $forestRoles.SchemaMaster
            DomainNamingMaster  = $forestRoles.DomainNamingMaster
        }

        # Display the roles in a table
        $roles | Format-Table | Out-String | Write-Host

        # Save the results to a CSV file
        Export-Results -Data $roles -Description "FSMO Roles" -FileType "CSV" -FileName "FSMORoles"
    } catch {
        Write-Host "Error retrieving FSMO roles." -ForegroundColor Red
        Write-Log "Error: Unable to retrieve FSMO roles."
    }
}

# Function to check Active Directory event logs
# This function retrieves the latest 100 events from the "Directory Service" event log.
# Event logs are important for identifying and diagnosing issues related to Active Directory.
function Check-ADEventLogs {
    Write-Host "Checking Active Directory Event Logs..." -ForegroundColor Cyan
    $eventLogs = Get-EventLog -LogName "Directory Service" -Newest 100
    if ($eventLogs.Count -eq 0) {
        Write-Host "No recent Directory Service events found." -ForegroundColor Green
    } else {
        Write-Host "Recent Active Directory events detected:" -ForegroundColor Cyan
        $eventLogs | Format-Table | Out-String | Write-Host
        Export-Results -Data $eventLogs -Description "AD Event Logs" -FileType "CSV" -FileName "ADEventLogs"
    }
}

# Function to check Kerberos tickets
# This function lists the current Kerberos tickets held by the system. Kerberos is the authentication protocol used in Active Directory environments.
# Compatibility added for Windows Server 2012 R2 and higher to handle differences in `klist` output.
function Check-KerberosTickets {
    Write-Host "Checking Kerberos Tickets..." -ForegroundColor Cyan
    
    # Check the server version to apply different `klist` commands based on compatibility
    $osVersion = (Get-CimInstance Win32_OperatingSystem).Version
    $kerberosTickets = ""

    try {
        if ($osVersion -ge "10.0.0") {  # Windows Server 2016 and above
            $kerberosTickets = klist | Out-String
        } else {  # Windows Server 2012 R2 and lower
            $kerberosTickets = klist | Out-String
        }

        # Check if no tickets are found or credentials cache is missing
        if ($kerberosTickets -match "Credentials cache.*not found" -or $kerberosTickets -match "No credentials cache found") {
            Write-Host "No Kerberos tickets found or credentials cache is missing." -ForegroundColor Yellow
            Write-Log "Kerberos Tickets: No tickets found or cache missing."
        } elseif ($kerberosTickets) {
            Write-Host $kerberosTickets -ForegroundColor Cyan
            Export-Results -Data $kerberosTickets -Description "Kerberos Tickets" -FileType "TXT" -FileName "KerberosTickets"
        } else {
            Write-Host "No Kerberos tickets found." -ForegroundColor Green
        }
    } catch {
        Write-Host "Error retrieving Kerberos tickets. Please ensure that Kerberos is configured correctly." -ForegroundColor Red
        Write-Log "Error: Unable to retrieve Kerberos tickets."
    }
}

# Function to check GPO health
# Generates a report on all Group Policy Objects (GPOs) and their current settings. Group policies are critical for managing user and computer settings in an AD environment.
function Check-GPOHealth {
    Write-Host "Checking GPO Health..." -ForegroundColor Cyan
    $gpoHealth = Get-GPOReport -All -ReportType Html -Path "$($global:saveFolderPath)\GPOReport.html"
    if (Test-Path "$($global:saveFolderPath)\GPOReport.html") {
        Write-Host "GPO report generated successfully." -ForegroundColor Green
        Write-Log "GPO report generated."
    } else {
        Write-Host "Failed to generate GPO report." -ForegroundColor Red
    }
}

# Function to check Shadow Copy status for all fixed drives
# Shadow copies allow users to restore previous versions of files. This function checks for the existence of shadow copies on all fixed drives.
function Check-ShadowCopyStatus {
    Write-Host "Checking Shadow Copy status on all fixed drives..." -ForegroundColor Cyan

    # Initialize an array to hold the results
    $results = @()

    # Get all fixed drives
    $volumes = Get-Volume | Where-Object { $_.DriveType -eq 'Fixed' }

    # Check each drive for shadow copies
    foreach ($volume in $volumes) {
        $driveLetter = $volume.DriveLetter
        if ($driveLetter) {
            $vssShadows = vssadmin list shadows | Select-String "${driveLetter}:"
            if ($vssShadows) {
                $message = "Shadow Copies exist on ${driveLetter}: drive."
                Write-Host $message -ForegroundColor Green
                $results += $message
            } else {
                $message = "No Shadow Copies found on ${driveLetter}: drive."
                Write-Host $message -ForegroundColor Red
                $results += $message
            }
        }
    }

    # Save the results to a file if desired
    if ($global:saveResults -and $results.Count -gt 0) {
        $results | Out-File "$global:saveFolderPath/ShadowCopyStatusReport.txt"
        Write-Host "Shadow Copy status report saved to $global:saveFolderPath/ShadowCopyStatusReport.txt" -ForegroundColor Green
    }
}

# Function to run all checks
# This function runs all the available checks in sequence and saves the results.
function Run-AllChecks {
    Write-Log "Running all checks..."
    Write-Host "Running All Checks..." -ForegroundColor Cyan
    
    # User Management - Locked Out Users
    Write-Host "`n[User Management - Locked Out Users]" -ForegroundColor Cyan
    Show-LockedOutUsers

    # User Management - Users with ADMINISTRATOR privileges
    Write-Host "`n[User Management - Users with ADMINISTRATOR privileges]" -ForegroundColor Cyan
    Show-AdminUsers

    # User Management - Detailed User Information
    Write-Host "`n[User Management - Detailed User Information]" -ForegroundColor Cyan
    Show-UserDetails

    # Computer Management
    Write-Host "`n[Computer Management - Details]" -ForegroundColor Cyan
    Computer-Management

    # DCDiag Check
    Run-DCDiag

    # Replication Status Check
    Check-ReplicationStatus

    # SYSVOL Share Check
    Check-SYSVOL

    # DNS Configuration Check
    Check-DNS

    # FSMO Roles Check
    Check-FSMORoles

    # Event Logs Check
    Check-ADEventLogs

    # Kerberos Tickets Check
    Check-KerberosTickets

    # GPO Health Check
    Check-GPOHealth

    # Shadow Copy Check
    Check-ShadowCopyStatus

    # Windows Update Check
    Check-WindowsUpdates

    Write-Log "Completed all checks."
}

# Main script execution loop
do {
    Get-UserFilePathChoice  # Prompt for saving results before showing the menu
    Show-Menu
    $input = Read-Host "What would you like to do?"
    switch ($input) {
        '1' {
            Write-Host "Running all user-related checks..." -ForegroundColor Cyan
            Show-LockedOutUsers
            Show-AdminUsers
            Show-UserDetails
        }
        '2' { Computer-Management }
        '3' { Run-DCDiag }
        '4' { Check-ReplicationStatus }
        '5' { Check-SYSVOL }
        '6' { Check-DNS }
        '7' { Check-FSMORoles }
        '8' { Check-ADEventLogs }
        '9' { Check-KerberosTickets }
        '10' { Check-GPOHealth }
        '11' { Check-ShadowCopyStatus }
        '12' { Check-WindowsUpdates }
        'R' { Run-AllChecks }
        'Q' { Write-Host "Exiting... Thank you!" -ForegroundColor Magenta; break }
        default { Write-Host "Invalid option. Please try again." -ForegroundColor Red }
    }
    pause
} while ($input -ne 'Q')
