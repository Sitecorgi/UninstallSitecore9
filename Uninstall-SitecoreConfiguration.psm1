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

Function Remove-Database{
    [CmdletBinding()]
    param(
        [string]$dbName,
        [string]$server,
        [string]$user,
        [string]$password
    )

    $sqlQuery = $("DROP DATABASE IF EXISTS [$($dbName)]")

    Write-Host $("Dropping database $($dbName)")
    invoke-sqlcmd -ServerInstance $SqlServer -U $user -P $password -Query $sqlQuery -ErrorAction stop
}

function Stop-WinProcess{

    param(
        [string]$serviceName
    )

    Stop-Process -Name $serviceName -Force -ErrorAction SilentlyContinue
}

function Remove-SolrCores{
    param(
        [string]$pathToCores
    )
    Write-TaskHeader -TaskName "Solr Services" -TaskType "Delete Cores"
    Write-Host "Deleting Solr Cores"
    Get-ChildItem $pathToCores -Recurse | Remove-Item -Force -Recurse -ErrorAction stop
    Write-Host "Solr Cores deleted successfully"
}

##Exported##
Function Uninstall-Sitecore {
    param(
        [parameter(Mandatory=$true)]
        [string]$Prefix,
        [parameter(Mandatory=$true)]
        [string]$SitecoreSiteName,
        [parameter(Mandatory=$true)]
        [string]$PathToSolrCores,
        [parameter(Mandatory=$true)]
        [string]$PathToWebRoot,
        [parameter(Mandatory=$true)]
        [string]$SolrService,
        [parameter(Mandatory=$true)]
        [string]$SqlAccount,
        [parameter(Mandatory=$true)]
        [string]$SqlPassword,
        [parameter(Mandatory=$true)]
        [string]$SqlServer
    )
    Write-TaskHeader -TaskName "Windows services" -TaskType "Delete"
    Write-Host "Deleting Windows services"
    Remove-Service -serviceName $("$($Prefix).xconnect-MarketingAutomationService") -ErrorAction SilentlyContinue
    Remove-Service -serviceName $("$($Prefix).xconnect-IndexWorker") -ErrorAction SilentlyContinue
    Write-Host "Windows services deleted successfully"

    Write-TaskHeader -TaskName "Windows Processes" -TaskType "Stop"
    Write-Host "Stopping windows processes"

    Stop-WinProcess -serviceName Xconnect*
    Stop-WinProcess -serviceName maengine

    Write-Host "Windows processes stopped successfully"

    Write-TaskHeader -TaskName "Solr Services" -TaskType "Stop"
    Write-Host "Stopping solr service"
    Stop-Service $SolrService -Force -ErrorAction stop
    Write-Host "Solr service stopped successfully"


    #Delete solr cores
    Remove-SolrCores -pathToCores $("$PathToSolrCores\$Prefix*")

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
    Get-ChildItem $("$($PathToWebRoot)\$($Prefix)*") -Recurse | Remove-Item -Force -Recurse
    Write-Host "Websites removed from wwwroot"

    push-location
    import-module sqlps

    Remove-Database -dbName $("$($Prefix)_Core") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_ExperienceForms") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_MarketingAutomation") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Master") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Processing.Pools") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Processing.Tasks") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_ReferenceData") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Reporting") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Web") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Xdb.Collection.Shard0") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Xdb.Collection.Shard1") -server $SqlServer -user $SqlAccount -password $SqlPassword
    Remove-Database -dbName $("$($Prefix)_Xdb.Collection.ShardMapManager") -server $SqlServer -user $SqlAccount -password $SqlPassword

    Write-Host "Databases dropped successfully"
    pop-location

    Write-TaskHeader -TaskName "Host Entries" -TaskType "Remove"
    Install-Module psHosts
    import-module psHosts
    Write-Host "Removing HostFile Entries"
    Remove-HostEntry $SitecoreSiteName -ErrorAction SilentlyContinue
    Remove-HostEntry $SitecoreXConnect -ErrorAction SilentlyContinue

    Write-TaskHeader -TaskName "Solr Services" -TaskType "Start"
    Start-Service $SolrService -ErrorAction stop
    Write-Host "Solr Services restarted, environment is clean to reinstall"
}

Register-SitecoreInstallExtension -Command Uninstall-Sitecore -As UninstallSitecore -Type Task

