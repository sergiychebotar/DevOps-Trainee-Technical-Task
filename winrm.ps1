import-module NetSecurity
New-NetFirewallRule -DisplayName "Allow WinRM" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 5985,5986
Enable-PSRemoting -SkipNetworkProfileCheck
