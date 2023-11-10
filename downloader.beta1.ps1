# Variables
$URL = "https://www.example.com/files/No-Intro/Nintendo%20-%20Game%20Boy%20Advance/" # URL to fetch files from
$keywords = @("(us)","(usa)") # Keywords to match, seperated by commas in quotes
$excludeWords = @("beta", "pre-release","demo","bios","proto") # Words that filenames cannot contain
$ignoreFiles = @("ignore1.txt", "ignore2.txt") # List of filenames to ignore
$downloadDirectory = "C:\\Downloads\\GBA\\" # Directory to download files to

# Get list of available files
$webRequest = Invoke-WebRequest -Uri $URL

# Filter links based on keywords, exclusion words, and ignore list
$matchingLinks = $webRequest.Links | Where-Object {
    $link = $_
    $fileName = Split-Path $link.href -Leaf

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

# For each group, select the link with the highest rev number (case-insensitive)
$selectedLinks = foreach ($group in $groupedLinks) {$group.Group | Sort-Object -Property {$_.innerText} | Select-Object -First 1 }

# Show summary and ask for confirmation
$matchingCount = $selectedLinks.Count
Write-Host "Found $matchingCount files to download."
$userInput = Read-Host "Do you want to continue? (Y/N/List)"
if ($userInput -eq "List") {
    Write-Host "Files to download:"
    foreach ($link in $selectedLinks) {
        Write-Host $link.innerText
    }
    $userInput = Read-Host "Do you want to continue? (Y/N)"
}
if ($userInput -ne "Y") {
    Write-Host "Download cancelled!"
    return
}

# Download selected files
foreach ($link in $selectedLinks) {
    $fileUrl = $URL + $link.innerText
    $fileName = Split-Path $link.href -Leaf
    $goodname = Split-Path $link.innerText -Leaf
    $filePath = Join-Path -Path $downloadDirectory -ChildPath $goodname
    #This was for debuggin
    #Write-Host "Saving" + $fileUrl "to" + $filePath
    Invoke-WebRequest -Uri $fileUrl -OutFile $filePath
}

Write-Host "Download complete!"
