# Define parameters for Azure Automation
param (
    [string]$siteUrl = "https://spruceschool.sharepoint.com/",
    [string]$listName = "90 Hour Courses root structure",
    [string]$documentLibraryName = "Documents",
    [string]$outputFolderPath = "Shared Documents"
)

# Authenticate using Azure Run As Account
#$connectionName = "AzureRunAsConnection"
#$connection = Get-AutomationConnection -Name $connectionName
$connection = Connect-AzAccount -Identity 

Write-Output "Trying to fetch value from key vault using MI. Make sure you have given correct access to Managed Identity" 


Connect-PnPOnline -Url $siteUrl -ManagedIdentity
Write-Output "Successfully connected with Automation account's Managed Identity" 

# Initialize variables
$timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
$outputFileName = "90HourCoursesRootStructure_$timestamp.csv"
$outputFile = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), $outputFileName)
$batchSize = 2000
$allItems = @()
$position = 0

Write-Output "Fetching items in batches..."

do {
    # Get items in the current batch
    $items = (Get-PnPListItem -List $listName -PageSize $batchSize -Query "<View><RowLimit>$batchSize</RowLimit><Paging ListItemCollectionPositionNext='$position' /></View>").FieldValues

    # Add the retrieved items to the array
    $allItems += $items

    # Get the position for the next batch (if any)
    $position = $items.ListItemCollectionPositionNext

    Write-Output "Fetched $($allItems.Count) items so far..."

} while ($position -ne $null)

Write-Output "Finished fetching all items."

# Export to CSV
$(foreach ($ht in $allItems) {
    New-Object PSObject -Property $ht
}) | Select-Object -Property Type_x0020_of_x0020_Course,Enrollment_x0020_Date,Last_x0020_Name,First_x0020_Name,Home_x0020_Phone,Work_x0020_Phone,Street_x0020_Address,City,State,Zip_x0020_Code,Email,Username,Password,Gender,Date_x0020_materials_x0020_sent,Date_x0020_final_x0020_sent,Date_x0020_completed,State_x0020_exam_x0020_date,Pass_x0020_date,PP,Law,Fin,App,Course_x0020_Cost,payment_x0020__x0023_1,date_x0020__x0023_1,payment_x0020__x0023_2,date_x0020__x0023_2,payment_x0020__x0023_3,date_x0020__x0023_3,Office_x0020_Receiving_x0020_Pay,Notes | Export-Csv -Path $outputFile -NoTypeInformation

Write-Output "Data exported to $outputFile."

# Upload the CSV file to SharePoint Document Library
Write-Output "Uploading CSV to SharePoint..."

$documentLibrary = Get-PnPList -Identity $documentLibraryName
Add-PnPFile -Path $outputFile -Folder $outputFolderPath

Write-Output "CSV file uploaded to $documentLibraryName with the name $outputFileName."

# Clean up the temporary file
Remove-Item -Path $outputFile

Write-Output "Temporary file removed."
