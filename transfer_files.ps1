#This script copies files from one windows 7 machine to another windows 7 machine
#This script accepts 3 arguments: The users name, the source hostname, and the destination hostname
#To use this script:
#open PowerShell and change directory to the location of the script
#type ./Copy_file_args.ps1 UserName SourceHostname DestinationHostname
#YOU MUST PROVIDE ALL THREE ARGUMENTS OTHERWISE IT WONT WORK
###################################################################################################
#Assigns the arguments provided into variables
param(
[string]$UserName,
[string]$Host1,
[string]$Host2
)
#Verifies that all hosts are reachable.
$Status1 = Test-Connection $Host1 -quiet
$Status2 = Test-Connection $Host2 -quiet
If (($Status1 -eq $True) -and ($Status2 -eq $False))
	{
	Write-Host "Destination machine is unavailable, please check the connection and hostname"
	exit
	}
ElseIf (($Status1 -eq $False) -and ($Ttatus2 -eq $True))
	{
	Write-Host "Source machine is unavailable, please check the connection and hostname"
	exit
	}
ElseIf (($Status1 -eq $False) -and ($Status2 -eq $False))
	{
	Write-Host "Neither the source nor destination machine are available, please check the connections and hostnames"
	exit
	}
Else
	{
	Write-Host "Both computers are reachable, continuing on"
	}
#Determines whether any of the machines are local or remote
If ($Host1 -eq $Env:ComputerName)
	{
	$Source = $Env:UserProfile
	}
Else
	{
	$Source = "\\" + $Host1 + "\c$\users\" + $UserName
	}
If ($Host2 -eq $Env:ComputerName)
	{
	$Destination = $Env:UserProfile
	}
Else
	{
	$Destination = "\\" + $Host2 + "\c$\users\" + $UserName
	}
#Verifies that username given is correct
$Path1 = Test-Path $Source
$Path2 = Test-Path $Destination
If (($Path1 -eq $False) -and ($Path2 -eq $False))
	{
	Write-Host "Cannot find home folder for user specified on source machine nor the destination machine"
	Write-Host "Please verify that you have the correct user name"
	exit
	}
ElseIf (($Path1 -eq $False) -and ($Path2 -eq $True))
	{
	Write-Host "Cannot find home folder for user specified on source machine"
	Write-Host "Please verify that you have the correct user name"
	exit
	}
ElseIf (($Path1 -eq $True) -and ($Path2 -eq $False))
	{
	Write-Host "Cannot find home folder for user specified on destination machine"
	Write-Host "Please verify that you set up user's profile"
	exit
	}
Else
	{
	Write-Host "Copying files..."
#Once host location has been determined and connection status has been verified, the remainder of variables are set
#Logic for determining bookmarks and psts
	$FireFoxProfile = Get-ChildItem $Source\AppData\Roaming\Mozilla\Firefox\Profiles 
	$RecentBackup = Get-ChildItem $Source\AppData\Roaming\Mozilla\Firefox\Profiles\$FireFoxProfile\bookmarkbackups | Where-Object {$_.extension -like ".json*"} | Sort-Object LastAccessTime -Descending | Select-Object -First 1
	$FireFoxBookmarks = "AppData\Roaming\Mozilla\Firefox\Profiles\" + $FireFoxProfile + "\bookmarkbackups\" + $RecentBackup
	$RemoteFireFoxProfile = Get-ChildItem $Destination\AppData\Roaming\Mozilla\Firefox\Profiles
	$RemoteFirefoxBookmarks = "AppData\Roaming\Mozilla\Firefox\Profiles\" + $RemoteFireFoxProfile + "\bookmarkbackups\"
	$ChromeBookmarks = "AppData\Local\Google\Chrome\User Data\Default\"
	$OutlookPST = "AppData\Local\Microsoft\Outlook"
#Array stores PST filenames of any PSTs greater than 265 Kilobytes (Empty PST default size is 265k)
	$OutlookPSTArray = @(Get-ChildItem $Source\AppData\Local\Microsoft\Outlook) | Where-Object {$_.extension -like ".pst"} | Where-Object {$_.length -gt 265}
#Array stores folder names within home directory, may add or subtract based on needs
	$FileLocationArray = @(
	"Music",
	"Videos",
	"Desktop",
	"Pictures",
	"Documents",
	"Downloads",
	"Favorites"
	)
#Loops through array of folder locations and copies files and folders to new machine
	ForEach ($Folder in $FileLocationArray)
		{
		$TestExist = Test-Path $Source\$Folder
		If ($TestExist -eq $True)
			{
			Write-Host "Copying: "$Folder
			Copy-Item $Source\$Folder\* $Destination\$Folder -Recurse -Force
			}
		}
	If ($OutlookPSTArray.count -gt 0)
		{
		ForEach ($PST in $OutlookPSTArray)
			{
			Write-Host "Copying: "$PST
			Copy-Item $Source\$OutlookPST\$PST $Destination\$OutlookPST -Recurse -Force
			}
		}
	Else
		{
		Write-Host "No PSTs were found"
		}
	Write-Host "Copying Bookmarks"
	Copy-Item $Source\$FireFoxBookmarks $Destination\$RemoteFireFoxBookmarks
	Copy-Item $Source\$ChromeBookmarks"\Bookmarks" $Destination\$ChromeBookmarks
	Write-Host "File transfer complete"
	}