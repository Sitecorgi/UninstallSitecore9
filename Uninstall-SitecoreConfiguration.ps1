#define parameters
Param(
	[string]$Prefix,	
	[string]$SitecoreSiteName,
	[string]$SolrService,
	[string]$PathToSolr,
	[string]$SqlServer,
	[string]$SqlAccount,
	[string]$SqlPassword
)
#Write-TaskHeader function modified from SIF
Function Write-TaskHeader {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TaskName,
        [Parameter(Mandatory=$true)]
        [string]$TaskType
    )

    function StringFormat {
        param(
            [int]$length,
            [string]$value,
            [string]$prefix = '',
            [string]$postfix = '',
            [switch]$padright
        )

        # wraps string in spaces so we reduce length by two
        $length = $length - 2 #- $postfix.Length - $prefix.Length
        if($value.Length -gt $length){
            # Reduce to length - 4 for elipsis
            $value = $value.Substring(0, $length - 4) + '...'
        }

        $value = " $value "
        if($padright){
            $value = $value.PadRight($length, '*')
        } else {
            $value = $value.PadLeft($length, '*')
        }

        return $prefix + $value + $postfix
    }

    $actualWidth = (Get-Host).UI.RawUI.BufferSize.Width
    $width = $actualWidth - ($actualWidth % 2)
    $half = $width / 2

    $leftString = StringFormat -length $half -value $TaskName -prefix '[' -postfix ':'
    $rightString = StringFormat -length $half -value $TaskType -postfix ']' -padright

    $message = ($leftString + $rightString)
    Write-Host ''
    Write-Host $message -ForegroundColor 'Red'
}

Function Remove-Service{
	[CmdletBinding()]
	param(
		[string]$serviceName
	)
	if(Get-Service $serviceName -ErrorAction SilentlyContinue){
		sc.exe delete $serviceName
	}
}

Function Remove-Website{
	[CmdletBinding()]
	param(
		[string]$siteName		
	)

	$appCmd = "C:\windows\system32\inetsrv\appcmd.exe"
	& $appCmd delete site $siteName
}

Function Remove-AppPool{
	[CmdletBinding()]
	param(		
		[string]$appPoolName
	)

	$appCmd = "C:\windows\system32\inetsrv\appcmd.exe"
	& $appCmd delete apppool $appPoolName
}

#stop windows services
Write-TaskHeader -TaskName "Windows services" -TaskType "Delete"
Write-Host "Deleting Windows services"

Remove-Service -serviceName $("$($Prefix).xconnect-MarketingAutomationService") -ErrorAction SilentlyContinue
Remove-Service -serviceName $("$($Prefix).xconnect-IndexWorker") -ErrorAction SilentlyContinue

Write-Host "Windows services deleted successfully"

#stop key windows processes
Write-TaskHeader -TaskName "Windows Processes" -TaskType "Stop"
Write-Host "Stopping windows processes"
Stop-Process -Name Xconnect* -Force -ErrorAction SilentlyContinue
Stop-Process -Name maengine -Force -ErrorAction SilentlyContinue
Write-Host "Windows processes stopped successfully"

#Stop Solr Service
Write-TaskHeader -TaskName "Solr Services" -TaskType "Stop"
Write-Host "Stopping solr service"
Stop-Service $SolrService -Force -ErrorAction stop
Write-Host "Solr service stopped successfully"

#Delete solr cores
Write-TaskHeader -TaskName "Solr Services" -TaskType "Delete Cores"
Write-Host "Deleting Solr Cores"
$pathToCores = "$pathToSolr\server\solr\$Prefix*"
Remove-Item $pathToCores -recurse -force -ErrorAction stop
Write-Host "Solr Cores deleted successfully"

#Remove Sites and App Pools from IIS
Write-TaskHeader -TaskName "Internet Information Services" -TaskType "Remove Websites"

Write-Host "deleting websites"
Write-Host "Deleting Website $SitecoreSiteName"
Remove-Website -siteName $SitecoreSiteName -ErrorAction stop
$SitecoreXConnect = $("$($Prefix).xconnect")
Write-Host "Deleting Website $SitecoreXConnect"
Remove-Website -siteName $SitecoreXConnect -ErrorAction stop
Write-Host "Websites deleted"

Write-TaskHeader -TaskName "Internet Information Services" -TaskType "Remove Application Pools"
Write-Host "Deleting application pools"
Write-Host "Deleting apppool $SitecoreSiteName"
Remove-AppPool -appPoolName $SitecoreSiteName -ErrorAction stop
Write-Host $("Deleting apppool $SitecoreXConnect")
Remove-AppPool -appPoolName $SitecoreXConnect -ErrorAction stop
Write-Host "Application pools deleted"

Write-TaskHeader -TaskName "Internet Information Services" -TaskType "Remove Folders"
#Remove website folders from wwwroot
Remove-Item C:\inetpub\wwwroot\$Prefix* -recurse -force -ErrorAction stop
Write-Host "Websites removed from wwwroot"

Write-TaskHeader -TaskName "SQL Server" -TaskType "Drop Databases"
#Drop databases from SQL
Write-Host "Dropping databases from SQL server"
push-location
import-module sqlps
$sqlPrefix = $("DROP DATABASE IF EXISTS [$($Prefix)")

Write-Host $("Dropping database $($Prefix)_Core")
$corePrefix = $("$($sqlPrefix)_Core]")
Write-Host $("Query: $($corePrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $corePrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_ExperienceForms")
$xfPrefix = $("$($sqlPrefix)_ExperienceForms]")
Write-Host $("Query: $($xfPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $xfPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_MarketingAutomation")
$maPrefix = $("$($sqlPrefix)_MarketingAutomation]")
Write-Host $("Query: $($maPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $maPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Master")
$masterPrefix = $("$($sqlPrefix)_Master]")
Write-Host $("Query: $($masterPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $masterPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Processing.Pools")
$ppPrefix = $("$($sqlPrefix)_Processing.Pools]")
Write-Host $("Query: $($ppPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $ppPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Processing.Tasks")
$ptPrefix = $("$($sqlPrefix)_Processing.Tasks]")
Write-Host $("Query: $($ptPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $ptPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_ReferenceData")
$rdPrefix = $("$($sqlPrefix)_ReferenceData]")
Write-Host $("Query: $($rdPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $rdPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Reporting")
$repPrefix = $("$($sqlPrefix)_Reporting]")
Write-Host $("Query: $($repPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $repPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Web")
$webPrefix = $("$($sqlPrefix)_Web]")
Write-Host $("Query: $($webPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $webPrefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Xdb.Collection.Shard0")
$xbs0Prefix = $("$($sqlPrefix)_Xdb.Collection.Shard0]")
Write-Host $("Query: $($xbs0Prefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $xbs0Prefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Xdb.Collection.Shard1")
$xbs1Prefix = $("$($sqlPrefix)_Xdb.Collection.Shard1]")
Write-Host $("Query: $($xbs1Prefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $xbs1Prefix -ErrorAction stop

Write-Host $("Dropping database $($Prefix)_Xdb.Collection.ShardMapManager")
$xbsmPrefix = $("$($sqlPrefix)_Xdb.Collection.ShardMapManager]")
Write-Host $("Query: $($xbsmPrefix)")
invoke-sqlcmd -ServerInstance $SqlServer -U $SqlAccount -P $SqlPassword -Query $xbsmPrefix -ErrorAction stop

Write-Host "Databases dropped successfully"
pop-location

#Remove Host Entries
Write-TaskHeader -TaskName "Host Entries" -TaskType "Remove"
import-module psHosts
Write-Host "Removing HostFile Entries"
Remove-HostEntry $SitecoreSiteName -ErrorAction SilentlyContinue
Remove-HostEntry $SitecoreXConnect -ErrorAction SilentlyContinue

#Start Solr up again
Write-TaskHeader -TaskName "Solr Services" -TaskType "Start"
Start-Service $SolrService -ErrorAction stop
Write-Host "Solr Services restarted, environment is clean to reinstall"
