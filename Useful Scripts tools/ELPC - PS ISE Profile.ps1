# Function to display ELPC logo
function Show-ELPCLogo {
    $logo = @"

                     ▓█████  ██▓     ██▓███   ▄████▄                             
                     ▓█   ▀ ▓██▒    ▓██░  ██▒▒██▀ ▀█                             
                     ▒███   ▒██░    ▓██░ ██▓▒▒▓█    ▄                            
                     ▒▓█  ▄ ▒██░    ▒██▄█▓▒ ▒▒▓▓▄ ▄██▒                           
                     ░▒████▒░██████▒▒██▒ ░  ░▒ ▓███▀ ░                           
                     ░░ ▒░ ░░ ▒░▓  ░▒▓▒░ ░  ░░ ░▒ ▒  ░                           
                      ░ ░  ░░ ░ ▒  ░░▒ ░       ░  ▒                              
                        ░     ░ ░   ░░       ░                                   
                        ░  ░    ░  ░         ░ ░                                 
                                             ░                                   
 ██▓▄▄▄█████▓     ██████ ▓█████  ▄████▄   █    ██  ██▀███   ██▓▄▄▄█████▓▓██   ██▓
▓██▒▓  ██▒ ▓▒   ▒██    ▒ ▓█   ▀ ▒██▀ ▀█   ██  ▓██▒▓██ ▒ ██▒▓██▒▓  ██▒ ▓▒ ▒██  ██▒
▒██▒▒ ▓██░ ▒░   ░ ▓██▄   ▒███   ▒▓█    ▄ ▓██  ▒██░▓██ ░▄█ ▒▒██▒▒ ▓██░ ▒░  ▒██ ██░
░██░░ ▓██▓ ░      ▒   ██▒▒▓█  ▄ ▒▓▓▄ ▄██▒▓▓█  ░██░▒██▀▀█▄  ░██░░ ▓██▓ ░   ░ ▐██▓░
░██░  ▒██▒ ░    ▒██████▒▒░▒████▒▒ ▓███▀ ░▒▒█████▓ ░██▓ ▒██▒░██░  ▒██▒ ░   ░ ██▒▓░
░▓    ▒ ░░      ▒ ▒▓▒ ▒ ░░░ ▒░ ░░ ░▒ ▒  ░░▒▓▒ ▒ ▒ ░ ▒▓ ░▒▓░░▓    ▒ ░░      ██▒▒▒ 
 ▒ ░    ░       ░ ░▒  ░ ░ ░ ░  ░  ░  ▒   ░░▒░ ░ ░   ░▒ ░ ▒░ ▒ ░    ░     ▓██ ░▒░ 
 ▒ ░  ░         ░  ░  ░     ░   ░         ░░░ ░ ░   ░░   ░  ▒ ░  ░       ▒ ▒ ░░  
 ░                    ░     ░  ░░ ░         ░        ░      ░            ░ ░     
                                ░                                        ░ ░     

"@
    Write-Host $logo -ForegroundColor DarkMagenta
}

# Function to display a loading banner
function Show-LoadingBanner {
    Write-Host "=================================================================================" -ForegroundColor DarkCyan
    Write-Host "                       Welcome to ELPC PowerShell ISE                            " -ForegroundColor DarkCyan
    Write-Host "                      Initializing Tools and Add-Ons...                          " -ForegroundColor DarkCyan
    Write-Host "=================================================================================" -ForegroundColor DarkCyan
}

# Function to display a success message
function Show-SuccessMessage {
    Write-Host "All tools and add-ons have been successfully loaded!" -ForegroundColor Green
}

# Show the ELPC logo
Show-ELPCLogo

# Show the loading banner
Show-LoadingBanner

# Clear existing Add-ons menu
$psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Clear()

# Create Microsoft 365 menu
$ms365Menu = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("Microsoft 365", $null, $null)

# Add submenu for connecting to Exchange Online
$ms365Menu.SubMenus.Add("Connect to Exchange Online", {
    Import-Module ExchangeOnlineManagement
    Connect-ExchangeOnline -UserPrincipalName your-email@domain.com -ShowProgress $true
    Write-Host "Connected to Exchange Online!" -ForegroundColor Green
}, "Ctrl+Alt+E") | Out-Null

# Add submenu for connecting to Microsoft Graph
$ms365Menu.SubMenus.Add("Connect to Microsoft Graph", {
    Connect-MgGraph -Scopes "User.Read.All", "Group.Read.All"
    Write-Host "Connected to Microsoft Graph!" -ForegroundColor Green
}, "Ctrl+Alt+M") | Out-Null

# Add submenu for connecting to SharePoint Online (PnP)
$ms365Menu.SubMenus.Add("Connect to SharePoint Online (PnP)", {
    Import-Module SharePointPnPPowerShellOnline
    Connect-PnPOnline -Url https://your-tenant-admin.sharepoint.com
    Write-Host "Connected to SharePoint Online (PnP)!" -ForegroundColor Green
}, "Ctrl+Alt+S") | Out-Null

# Add submenu for connecting to Azure AD
$ms365Menu.SubMenus.Add("Connect to Azure AD", {
    Import-Module AzureAD
    Connect-AzureAD
    Write-Host "Connected to Azure AD!" -ForegroundColor Green
}, "Ctrl+Alt+A") | Out-Null

# Add submenu for connecting to Microsoft Teams
$ms365Menu.SubMenus.Add("Connect to Microsoft Teams", {
    Import-Module MicrosoftTeams
    Connect-MicrosoftTeams
    Write-Host "Connected to Microsoft Teams!" -ForegroundColor Green
}, "Ctrl+Alt+T") | Out-Null

# Add submenu for connecting to MSOnline (Legacy Azure AD)
$ms365Menu.SubMenus.Add("Connect to MSOnline", {
    Import-Module MSOnline
    Connect-MsolService
    Write-Host "Connected to MSOnline!" -ForegroundColor Green
}, "Ctrl+Alt+O") | Out-Null

# Add submenu for connecting to SharePoint Online (SPO)
$ms365Menu.SubMenus.Add("Connect to SharePoint Online (SPO)", {
    Import-Module Microsoft.Online.SharePoint.PowerShell
    Connect-SPOService -Url https://your-tenant-admin.sharepoint.com
    Write-Host "Connected to SharePoint Online (SPO)!" -ForegroundColor Green
}, "Ctrl+Alt+P") | Out-Null

# Adding Network Tools to the menu
$networkMenu = $psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("Network Tools", $null, $null)

# Add submenu for SSH Connection using key file
$networkMenu.SubMenus.Add("Connect via SSH", {
    $hostname = Read-Host "Enter the hostname or IP address"
    $username = Read-Host "Enter your username"
    $port = Read-Host "Enter the SSH port (default is 22)"
    $keyFile = Read-Host "Enter the path to your private key file (or press Enter to skip)"
    
    if ($port -eq "") {
        $port = 22
    }
    
    if ($keyFile -eq "") {
        ssh -p $port "$username@$hostname"
    } else {
        ssh -i $keyFile -p $port "$username@$hostname"
    }
}, "Ctrl+Alt+1") | Out-Null

# Add submenu for Port Scanning
$networkMenu.SubMenus.Add("Scan Open Ports", {
    $hostname = Read-Host "Enter the hostname or IP address to scan"
    $ports = 1..1024  # Ports to scan
    foreach ($port in $ports) {
        try {
            $socket = New-Object System.Net.Sockets.TcpClient($hostname, $port)
            Write-Host "Port $port is open on $hostname" -ForegroundColor Green
            $socket.Close()
        } catch {
            Write-Host "Port $port is closed on $hostname" -ForegroundColor Red
        }
    }
}, "Ctrl+Alt+2") | Out-Null

# Add submenu for SSL Certificate Check
$networkMenu.SubMenus.Add("Check SSL Certificate", {
    $domain = Read-Host "Enter the domain"
    $request = [System.Net.HttpWebRequest]::Create("https://$domain")
    $request.Method = "GET"
    $request.AllowAutoRedirect = $false
    try {
        $response = $request.GetResponse()
    } catch [System.Net.WebException] {
        $response = $_.Exception.Response
    }
    $certificate = $response.ServicePoint.Certificate
    $certInfo = New-Object PSObject -Property @{
        Issuer = $certificate.Issuer
        Subject = $certificate.Subject
        ExpirationDate = $certificate.GetExpirationDateString()
    }
    $certInfo | Format-Table -AutoSize
}, "Ctrl+Alt+3") | Out-Null

# Adding System Information to the menu (with new shortcut)
$psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("System Information", {
    Write-Host "System Information tools loaded!" -ForegroundColor Green
    # Add system information scripts or commands here
}, "Ctrl+Alt+Y") | Out-Null

# Adding Custom Scripts to the menu
$psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("Custom Scripts", {
    Write-Host "Loading custom scripts..." -ForegroundColor Green
    # Load or reference your personal scripts here
}, "Ctrl+Alt+U") | Out-Null

# Adding Manage Modules to the menu (with new shortcut)
$psISE.CurrentPowerShellTab.AddOnsMenu.SubMenus.Add("Manage Modules", {
    Write-Host "Loading module management tools..." -ForegroundColor Green
    # Add your module management scripts or commands here
}, "Ctrl+Alt+X") | Out-Null

# Show the success message
Show-SuccessMessage
