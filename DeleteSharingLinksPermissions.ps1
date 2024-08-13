$SiteUrl = "https://contoso.sharepoint.com/sites/team"
$ListName = "Documents"

Connect-PnPOnline -Url $SiteURL -Interactive
$Ctx = Get-PnPContext

$ListItems = Get-PnPListItem -List $ListName
$ItemCount = $ListItems.Count
   
#Iterate through each list item
ForEach($Item in $ListItems)
{
    [System.Collections.ArrayList]$Links
    $ItemPermission =Get-PnPListItemPermission -List $ListName -Identity $Item.Id
    $RoleAssignments = Get-PnPProperty -ClientObject $Item -Property RoleAssignments

    ForEach($permission in $ItemPermission.Permissions)
    {
        If($permission.PrincipalName.StartsWith("SharingLinks"))
        {
            $Links.Add($permission.PrincipalId)
        }
    }
    
    ForEach($RoleAssignment in $RoleAssignments)
        {
           If($Links.Contains($RoleAssignment.PrincipalId))
           {
                $Item.RoleAssignments.GetByPrincipalId($RoleAssignment.PrincipalId).DeleteObject()
                Invoke-PnPQuery
           }
        }

}