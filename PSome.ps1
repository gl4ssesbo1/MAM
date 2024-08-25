function Get-DomainObject {
    param (
        [string]$CsvPath = "C:\path\to\output\users.csv",
        [string]$LDAPPath = "LDAP://DC=domain,DC=com",
        [string]$SearchString = "(objectClass=user)"
    )

    # Create a DirectorySearcher object
    $directorySearcher = New-Object System.DirectoryServices.DirectorySearcher([ADSI]$LDAPPath)

    # Set the search filter to find all user objects
    $directorySearcher.Filter = $searchstring

    # Define properties to load
    #$directorySearcher.PropertiesToLoad.Add("sAMAccountName") > $null
    #$directorySearcher.PropertiesToLoad.Add("displayName") > $null

    # Perform the search
    $results = $directorySearcher.FindAll()

    # Define an empty array to collect user objects
    $objectList = @()

    # Collect user objects
    foreach ($result in $results) {
        $object = $result.Properties
        $objectObj = [PSCustomObject]@{}
        foreach ($property in $object.PropertyNames) {
            $objectObj | Add-Member -MemberType NoteProperty -Name $property -Value ($object[$property] -join ", ")
        }
        $objectList += $objectObj
    }

    # Export to CSV
    if ($CsvPath -ne $null){
        $objectList | Export-Csv -Path $CsvPath -NoTypeInformation
        Write-Output "Output dumped in $CsvPath"
    }
    
    return $objectList
}

function Run-AllChecks(){
    param (
        [string]$LDAPPath = "LDAP://DC=domain,DC=com"
    )


    $path="C:\Users\$env:USERNAME\ADSecurityCheckList"
    Write-Host "Checking $path Exist" -ForegroundColor Blue

    #$server = "<Domain Controller>"

    if(Test-Path -Path $path){
        Write-Host "Path exist" -ForegroundColor Green
    }
    else{
        write-host "Path not exist" -ForegroundColor Red
        write-host "Path is creating" -ForegroundColoR Blue
        md $path
    }

    $date = Get-Date -UFormat %d%m%Y
    if(Test-Path -Path $path\$date){
        Write-Host "Path exist" -ForegroundColor Green
    }

    else{
        write-host "Path not exist" -ForegroundColor Red
        write-host "Path is creating" -ForegroundColoR Blue
        md $path\$date
    }

    $finalpath="$path\$date"
    Write-Host "$finalpath created" -ForegroundColor Blue

    "---All Object In Active Directory---"  > $finalpath\1-AllObject.csv 

    (Get-DomainObject -SearchString "(objectClass=*)" -LDAPPath $LDAPPath -CsvPath $null).count >> $finalpath\1-AllObject.csv 

    "---All User In Active Directory---" >$finalpath\2-AllUser.csv
    (Get-DomainObject -SearchString "(objectClass=user)" -LDAPPath $LDAPPath -CsvPath $null).count >>$finalpath\2-AllUser.csv 

    "---Disable Users In Active Directory---" >$finalpath\3-DisableUser.csv 
    $disableuser=Get-DomainObject -SearchString "(userAccountControl:1.2.840.113556.1.4.803:=2)" -LDAPPath $LDAPPath -CsvPath $null | select Name,SamaccountName,SID >>$finalpath\3-DisableUser.csv 


    "---Inactive Users In Active Directory---" >$finalpath\4-InactiveUser.csv 
    $inactiveuser=Get-DomainObject -SearchString "(&(lastLogonTimestamp=*)(userAccountControl:1.2.840.113556.1.4.803:=512))" -LDAPPath $LDAPPath -CsvPath $null | select Name,SamaccountName,SID >>$finalpath\4-InactiveUser.csv 

    "---Admin Count 1 Users In Active Directory---" >$finalpath\5-admincount.csv 
    $admincount=Get-DomainObject -SearchString "(adminCount=1)" -LDAPPath $LDAPPath -CsvPath $null | select Name,SamaccountName,SID >>$finalpath\5-admincount.csv 
   
}