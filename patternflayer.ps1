##########################################################################
#                                                                        #
#      ██████╗  █████╗ ████████╗████████╗███████╗██████╗ ███╗   ██╗      #
#      ██╔══██╗██╔══██╗╚══██╔══╝╚══██╔══╝██╔════╝██╔══██╗████╗  ██║      #
#      ██████╔╝███████║   ██║      ██║   █████╗  ██████╔╝██╔██╗ ██║      #
#      ██╔═══╝ ██╔══██║   ██║      ██║   ██╔══╝  ██╔══██╗██║╚██╗██║      #
#      ██║     ██║  ██║   ██║      ██║   ███████╗██║  ██║██║ ╚████║      #
#      ╚═╝     ╚═╝  ╚═╝   ╚═╝      ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝      #
#                                                                        #
#          ███████╗██╗      █████╗ ██╗   ██╗███████╗██████╗              #
#          ██╔════╝██║     ██╔══██╗╚██╗ ██╔╝██╔════╝██╔══██╗             #
#          █████╗  ██║     ███████║ ╚████╔╝ █████╗  ██████╔╝             #
#          ██╔══╝  ██║     ██╔══██║  ╚██╔╝  ██╔══╝  ██╔══██╗             #
#          ██║     ███████╗██║  ██║   ██║   ███████╗██║  ██║             #
#          ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝  ╚═╝             #
#                                                                        #
##########################################################################

# PatternFlayer program path
$flayerHome = "C:\Program Files\PatternFlayer"

# Target parent directory
$targetParentDir = "C:\Users\seanh\AppData\Local"

# Select file/folder pattern to target
$targetPattern = "*77EC63BDA74BD0D0E0426DC8F8008506*"

# Clear user/agent's terminal output text formatting (e.g. colors, Nerd fonts, etc.)
$oldRendering = $PSStyle.OutputRendering

# Fetch "unqiue" timestamp we'll use to differentiate between a user's working files
$timestamp = Get-Date -Format "HHmmss_MMddyy"

if (Test-Path $flayerHome\Temp) {    
    Write-Host "PatternFlayer working directory `"Temp`" already exists"
# Perform Delete file from folder operation
}
else
{
# Create directory if it doesn't currently exist
    New-Item $flayerHome\Temp -ItemType Directory
    Write-Host "Folder Created successfully"
}
# Set up working directory and session logfile
$workingDir = $flayerHome+"\Temp"
$currSessionMatchlog = $workingDir + "\" + $timestamp + "_matches.txt"

# Welcome splash art
$space = "                        "
$asciiart = Get-Content -Raw ($workingDir + "\asciiart.txt")
$welcomeSplash = "`n" + $asciiart + "`n`n" + $space + "Nothing unifies like a common enemy`n`n" + $space + "                   © Sean Hobin 2022`n`n"
Write-Host $welcomeSplash                                                                                                

# Inform user where logfile can be located
Write-Host -NoNewline "Tracking pattern matches in logfile"("`"" + $timestamp + "_matches.txt" + "`"")"in directory"$workingDir"`n`n"

# Set pwd to suspected/target directory(ies)
Set-Location -Path $targetParentDir
$targetPattern = "*77EC63BDA74BD0D0E0426DC8F8008506*"

TAKEOWN /f "C:\Users\seanh\*77EC63BDA74BD0D0E0426DC8F8008506*" /r /d y
TAKEOWN /f "C:\Users\seanh\AppData\*77EC63BDA74BD0D0E0426DC8F8008506*" /r /d y
TAKEOWN /f "C:\Users\seanh\AppData\Local\*77EC63BDA74BD0D0E0426DC8F8008506*" /r /d y

# First focus on parent directory, and attempt to take ownership/strip read-only status
Get-ChildItem -Path "C:\Users\seanh\AppData\" -Recurse -Force
TAKEOWN /f $pwd"\"$targetPattern /r /d y
icacls $pwd /inheritance:r --% /grant:r "Builtin\Administrators":(OI)(CI)F
$ACL = Get-ACL -Path $pwd
$Group = New-Object System.Security.Principal.NTAccount("Builtin", "Administrators")
$ACL.SetOwner($Group)
$pwd | where {$_.PSIsContainer -eq $true} | Remove-Item -Recurse -Force -Verbose

# Reattempt permission reassignment
icacls $pwd /inheritance:r --% /grant:r "Builtin\Administrators":(OI)(CI)F
Set-ItemProperty -Path $pwd -Name IsReadOnly -Value $false


TAKEOWN /f C:\Windows\servicing\Packages\*hyper-v* /r /d y

# Create list of files matching the target pattern recursively inside the parent directory
$patternHits = Get-ChildItem $pwd -filter $targetPattern -Recurse -Force

# Remove matching sub-directories early on if possible
$patternHits | where {$_.PSIsContainer -eq $true} | Remove-Item -Recurse -Force -Verbose

foreach ($hit in Get-ChildItem $patternHits -filter $targetPattern -Recurse -Force)
{   echo $hit >> $currSessionMatchlog
	(Get-Item $hit).IsReadOnly = $false |
	icacls $hit /inheritance:r --% /grant:r "Builtin\Administrators":(OI)(CI)F
	Set-ItemProperty -Path $hit -Name IsReadOnly -Value $false
	TAKEOWN /f $hit /d y
}
