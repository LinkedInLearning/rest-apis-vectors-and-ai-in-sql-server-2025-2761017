Import-Module SqlServer
$server = "SQL2025"
$database = "LinkedInCourseDB"
$defaultLocation = 'Scottsdale,AZ'
$defaultInterest = 'Canyons'
$defaultRadius = 250

$userLocation = Read-Host "`nWhere do you want to go? (default: '$defaultLocation')"
if ([string]::IsNullOrWhiteSpace($userLocation)) { $userLocation = $defaultLocation }

$userInterest = Read-Host "`nWhat are you interested in? (default: '$defaultInterest')"
if ([string]::IsNullOrWhiteSpace($userInterest)) { $userInterest = $defaultInterest }

$userRadius = Read-Host "`nHow many miles can it be away? (default: '$defaultRadius')"
if ([string]::IsNullOrWhiteSpace($userRadius)) { $userRadius = $defaultRadius }

# Step 4: Call stored procedure
$result = Invoke-Sqlcmd -ServerInstance $server -Database $database `
 -Query "EXEC FindNearbyPlacesByVectorSearch @place = N'$userLocation', @search_Text = N'$userInterest', @radius = $userRadius" `
 -TrustServerCertificate

Write-Host "`nHere are some ideas:`n`n"
#$result | Format-Table -AutoSize
foreach($park in $result) {
Write-Host $Park.PlaceName
Write-Host "Located in:" $Park.Parkname "`n"
Write-Host $Park.Description_Summary.Trim()
Write-Host "----------`n`n"
}

Write-Host "Press any key to continue..."
[void][System.Console]::ReadKey($true)

if (1 -eq 2) {
$ChatbotExe='C:\Temp\chatbot.exe'
$ChatBoxSrc= $psEditor.GetEditorContext().CurrentFile.Path
Invoke-PS2EXE -InputFile $ChatBoxSrc -OutputFile $ChatbotExe
Start-Process cmd.exe -ArgumentList "/k `"$ChatbotExe`""
}


