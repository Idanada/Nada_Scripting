# Change the "Enter_Your_Site_Token" to the real Site token
curl -o SentinelOne.msi "https://elpc.cloud/Public/SentinelAgentWin.msi"
msiexec /i SentinelOne.msi /q /NORESTART SITE_TOKEN=Enter_Your_Site_Token
