# This is a one liner so it canrun any time - just change the site token instead of "Enter_Your_Site_token_Here"
sudo curl -o /tmp/Sentinelmacos.pkg "https://elpc.cloud/Public/Sentinel-macos.pkg" && sudo echo Enter_Your_Site_token_Here > /tmp/com.sentinelone.registration-token && sudo /usr/sbin/installer -pkg /tmp/Sentinelmacos.pkg -target /Library/
