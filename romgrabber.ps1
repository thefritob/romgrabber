#Must have parameters
# URL and downloaddirectory .\romgrabber.ps1 "https://website.com/system" "C:\Myroms\supergame9000"
param(
[Parameter(Position=0,Mandatory=$true)]
[string]$URL,
[Parameter(Position=1,Mandatory=$true)]
[string]$downloadDirectory
)
# Variables
$keywords = @("\(us","us\)","usa\)") # Keywords to match, seperated by commas in quotes, remeber to use escape characters"
$excludeWords = @("\(beta", "\(pre-release", "\(bios", "\(proto", "\(alt", "\[bios", "\(de", "mo\)", "\[b", "\(aft", "ket\)", "unreleased", "un-released") # Words that filenames cannot contain
$ignoreFiles = @("ignore1.txt", "ignore2.txt") # List of filenames to ignore
$speedlimit = 2000 # Speed limit is the number of milliseconds a download must take or it will sleep that many before starting the next one (less than 1500 and a server will limit you)

# Get list of available files
$webRequest = Invoke-WebRequest -Uri $URL

# Filter links based on keywords, exclusion words, and ignore list
$matchingLinks = $webRequest.Links | Where-Object {
    $link = $_
    $fileName = Split-Path $link.innerText -Leaf

    # Check if any keyword matches (case-insensitive)
    $keywordMatch = $keywords | Where-Object { $fileName -imatch $_ }

    # Check if any exclusion word matches (case-insensitive)
    $excludeMatch = $excludeWords | Where-Object { $fileName -imatch $_ }

    # Check if filename is in ignore list (case-insensitive)
    $ignoreMatch = $ignoreFiles -contains $fileName

    # If a keyword matches, no exclusion word matches, and filename is not in ignore list, then include the link
    $null -ne $keywordMatch -and $null -eq $excludeMatch -and $ignoreMatch -eq $false
}

# Create download directory if it doesn't exist
if (!(Test-Path -Path $downloadDirectory)) { New-Item -ItemType Directory -Path $downloadDirectory }

# Group matching links by base filename up to the first parenthesis, case-insensitive)
$groupedLinks = $matchingLinks | Group-Object -Property {$_ -ireplace '\(.*', '('}

# For each group, select the link with the highest string value (case-insensitive)
$selectedLinks = foreach ($group in $groupedLinks) {$group.Group | Sort-Object -Property {$_.innerText} | Select-Object -First 1 }

# Starting the menu system
function Show-Menu
{
     param (
           [string]$Title = 'Rom Grabber'
     )
     CLear-Host
     Write-Host "================ $Title ================"
     Write-Host "URL" - $URL
     Write-Host "Download Directory" - $downloadDirectory
     Write-Host "Files online matched" - $selectedLinks.Count

     Write-Host "1: Press '1' to list files matched"
     Write-Host "2: Press '2' to download missing files"
     Write-Host "3: Press '3' cleanup download directory"
     Write-Host "Q: Press 'Q' to quit."
}

# Do loop to make the menu system work
do
{
     Show-Menu
     $menuinput = Read-Host "Please make a selection"
     switch ($menuinput)
     {
        '1' {
            Clear-Host
            Write-Host "Files to download:"
            foreach ($link in $selectedLinks) {
                Write-Host $link.innerText
            }
        } 
        '2' {
            Clear-Host
            foreach ($link in $selectedLinks) {
                $fileUrl = $URL + $link.href
                $fileName = Split-Path $link.href -Leaf
                $goodname = Split-Path $link.innerText -Leaf
                # Have to remove exclamation points for the filesystem
                $bestname = $goodname -replace "\[!\]", ""
                $filePath = Join-Path -Path $downloadDirectory -ChildPath $bestname
                if(Test-Path -Path $filePath){Write-host "File" $filepath "exists, moving on"}
                else {
                    # Log downloads to the screen with nicer name
                    Write-Host "Saving" $fileUrl "to" $filePath
                    $speed = Measure-Command { Invoke-WebRequest -Uri $fileUrl -OutFile $filePath -DisableKeepAlive} | Select-Object TotalMilliseconds
                    if ($speed.TotalMilliseconds -lt $speedlimit){
                        write-host "Giving that server a moment. We're going pretty fast, tiny files can do that."
                        Start-Sleep -Milliseconds $speedlimit
                    }
                }
            }
        } 
        '3' {
            Clear-Host
            Write-Host "Checking directory"
            # Get all files in the directory
            $directoryFiles = Get-ChildItem -Path $downloadDirectory -File | ForEach-Object { $_.Name }
            # Make sure dir isn't empty
            if ($null -eq $directoryFiles){
                Write-Host "Download Directory Empty - skipping"
                break  
            }
            # Compare to the online list
            $otherfiles = Compare-object -ReferenceObject $selectedLinks.innerText -DifferenceObject $directoryFiles | Where-Object { $_.SideIndicator -eq "=>" } | ForEach-Object { $_.InputObject }
            # List the files to move and ask for confirm
            Write-Host "Files to move to the (other) folder:"
            Write-Host $otherfiles | Format-List
            $userInput = Read-Host "Do you want to move these files? (Y/N)"
            # Start the move
            if ($userInput -eq "Y"){ 
                # Create other directory if it doesn't exist
                if (!(Test-Path -Path $downloadDirectory\\other)) {
                    New-Item -ItemType Directory -Path $downloadDirectory\\other 
                }
                $otherfiles | ForEach-Object { Move-Item -Path $downloadDirectory\\$_ -Destination $downloadDirectory\\other}
            }
        }
        'q' {
            return
        }    
     }
     pause
}
until ($input -eq 'q')
