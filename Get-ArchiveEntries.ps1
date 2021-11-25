#Set-StrictMode -Version Latest
#####################################################
# Get-ArchiveEntries
#####################################################
<#PSScriptInfo

.VERSION 0.1
.GUID 9cc904fc-341c-4873-ace6-c37f8c1e2f13

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS powershell archive files entries zip get

.LICENSEURI https://github.com/SharedSitecore/ConvertTo-Sitecore-WDP/blob/main/LICENSE

.PROJECTURI https://github.com/SharedSitecore/ConvertTo-Sitecore-WDP

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES

#>

<# 

.DESCRIPTION 
 PowerShell script to show/search entries/files in Zip package

.PARAMETER name
Path of package

#> 
#####################################################
# Get-ArchiveEntries
#####################################################
Param(
	[Parameter(Mandatory=$true)]
	[string] $path,
	[Parameter(Mandatory=$false)]
	[string[]] $search = @()
)
function Get-ArchiveEntries
{
	Param(
		[Parameter(Mandatory=$true)]
		[string] $path,	
		[Parameter(Mandatory=$false)]
		[string[]] $search = @()
	)
	$ProgressPreference = "SilentlyContinue"
	$results = @()
	Write-Verbose "Get-ArchiveEntries $path $search"
	try {
		if (!(Test-Path $path)) {
			throw "ERROR Get-ArchiveEntries - file not found: $path"
		}
		$file = (Split-Path $path -leaf).Replace('.zip', '')
		Add-Type -AssemblyName System.IO.Compression
		$stream = New-Object IO.FileStream($path, [IO.FileMode]::Open)
		$zip = New-Object IO.Compression.ZipArchive($stream)

		if (!$search) {
			$results += ($zip.Entries | Where-Object { (-not ($_.Name -Like '*.zip')) }) #| ForEach-Object { $_ }
		} else {
			foreach($query in $search) {
				Write-Verbose "query:$query"
				$queryResults = ($zip.Entries | Where-Object { ( (-not($_.Name -Like '*.zip')) -and ($_.FullName -Like $query)) }) #| ForEach-Object { $_ }
				Write-Verbose "query.count:$($queryResults.Length)"
				$results += $queryResults
			}
		}
		Write-Verbose "files:$results"

		$zips = @()
		if ($file -ne 'package') { #SearchStax.zip causes issues
			$zips = ($zip.Entries | Where-Object { $_.Name -Like '*.zip' }) | ForEach-Object { $_ }
		}
		if ($zip) {	$zip.Dispose() }
		if ($stream) {
			$stream.Close()
			$stream.Dispose()
		}

		Write-Verbose "zips:$zips"

		if ($zips) {
			$tempFolder = Join-Path $ENV:TEMP $file
			if (-not (Split-Path $tempFolder -Parent) -eq $file) { $tempFolder = Join-Path $tempFolder $file }
			Write-Verbose "tempFolder:$tempFolder"
			if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force } 
			if (!(Test-Path $tempFolder)) { 
				Write-Verbose "New-Item $tempFolder"
				New-Item -Path $tempFolder -ItemType Directory
			}
			($zips | Where-Object { $_.Name -Like '*.zip' }) | ForEach-Object {
				$tempZipPath = "$tempFolder\$($_.FullName)"
				if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Recurse -Force } 
				if (!(Test-Path $tempZipPath)) {
					Write-Verbose "Expanding $path"
					Expand-Archive -Force -Path $path -DestinationPath $tempFolder
				}
				$results += Get-ArchiveEntries "$tempFolder\$($_.FullName)" $search
			}
		}
	}
	catch {
		Write-Error "ERROR Get-ArchiveEntries $($path) $($search):$_"
	}
	Write-Verbose "results:$results"
	Write-Verbose "results.count:$($results.Length)"
	return $results
}
Get-ArchiveEntries $path $search