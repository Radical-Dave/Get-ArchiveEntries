#Set-StrictMode -Version Latest
#####################################################
# Get-ArchiveEntries
#####################################################
<#PSScriptInfo

.VERSION 0.3
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
	[Parameter(Mandatory=$false)]
	[string] $path,
	[Parameter(Mandatory=$false)]
	[string[]] $search = @(),
	[switch] $recurse = $false
)
$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
$PSScriptVerson = (Test-ScriptFileInfo -Path $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty Version)
$PSScriptName = ($MyInvocation.MyCommand.Name.Replace(".ps1",""))
$PSCallingScript = if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
Write-Verbose "$PSScriptRoot\$PSScriptName v$PSScriptVerson $path called by:$PSCallingScript"

$results = [System.Collections.Generic.List[object]]@()
if (!$path) {$path = '*.zip'}
Write-Verbose "path:$path"

$paths = [System.Collections.Generic.List[string]]@()

if ($path.IndexOf('*') -ne -1 -or $path.StartsWith('/') -or $path.StartsWith('\') -or $path.StartsWith('./') -or $path.StartsWith('.\')) {
	if ($path.IndexOf(':') -eq -1) {
		Write-Verbose "addpath:$PSScriptRoot\$path"
		$paths.Add((Join-Path $PSScriptRoot $path))
		#$addpath = Join-Path $PSScriptRoot $path
	}
	Write-Verbose "path:$path"
	if ($path.IndexOf('*') -ne -1) {
		#$addpaths = (Get-ChildItem -Path "$path").FullName
		$paths = (Get-ChildItem -Path "$path").FullName
	}
} else {
	if (!(Test-Path $path)) {
		$path = Get-Location $path

	}
	if (!(Test-Path $path)) {
		Write-Verbose "$PSScriptName - path not found:$path"
	} else {
		Write-Verbose "addpath:$path"
		#$addpath = "$PSScriptRoot\$path"
		#$paths.Add("$PSScriptRoot\$path")
		$paths.Add("$path")
	}
}
#Write-Verbose "addpath:$addpath"

#Write-Verbose "3path:$path"

#if (!$addpaths) {
#	Write-Verbose "paths:$($paths.Length)"
#	$paths.AddRange($addpaths)
#	Write-Verbose "paths:$($paths.Length)"
#}
#if (!$addpath) { $paths.Add($addpath) }
Write-Verbose "paths:$($paths.Count)"

try {
	foreach ($path in $paths) { #$paths.foreach({
		#Write-Verbose "check:$_"
		Write-Verbose "check:$path"
		if ($path) {
			#$path = $_
			Write-Verbose "path:$path"

			if (!(Test-Path $path)) {
				$currPath = Join-Path (Get-Location) $path
				Write-Verbose "currPath:$currPath"
				if (Test-Path $currPath) {
					$path = $currPath
				} else {
					throw "ERROR $PSScriptName - file not found: $path"
				}
			}
			$file = (Split-Path $path -leaf).Replace('.zip', '')
			Add-Type -AssemblyName System.IO.Compression
			Write-Verbose '####################################################################################################'
			Write-Verbose "$PSScriptName:Opening stream for $path"
			$stream = New-Object IO.FileStream($path, [IO.FileMode]::Open)
			$zip = New-Object IO.Compression.ZipArchive($stream)

			if (!$search) {
				Write-Verbose 'All except .zip'
				#$results += ($zip.Entries | Where-Object { (-not ($_.Name -Like '*.zip')) }) #| ForEach-Object { $_ }
				$found = ($zip.Entries | Where-Object { (-not ($_.Name -Like '*.zip')) })
				#$found = $zip.Entries
				Write-Verbose "found.count:$($found.Length)"
				if ($found) {
					#$results.AddRange($found)
					$results += $found
				}
			} else {
				foreach($query in $search) {
					Write-Verbose "query:$query"
					$queryResults = ($zip.Entries | Where-Object { $_.FullName -Like $query }) #| ForEach-Object { $_ }
					Write-Verbose "query.count:$($queryResults.Length)"
					#$results += $queryResults
					if ($queryResults-and $queryResults.Length -gt 0) {
						#$results.AddRange($queryResults)
						$results += $queryResults
					}
					#$results = $results.foreach({ $queryResults })
				}
			}
			#Write-Verbose "found:$results"

			$zips = @()
			if ($PSBoundParameters.ContainsKey('recurse') -and $recurse.IsPresent -eq $true -and $recurse.ToBool() -eq $true) { #if ($file -ne 'package') { #SearchStax.zip causes issues - todo -red flag
				Write-Verbose 'Recurse passed - checking for zips'
				$zips = ($zip.Entries | Where-Object { $_.Name -Like '*.zip' }) #| ForEach-Object { $_.FullName }
			}

			Write-Verbose "zips:$zips"

			if ($zips) {
				$temp = [system.io.path]::GetTempPath()
				Write-Verbose "temp:$($temp)"
				$tempFolder = Join-Path (Join-Path $temp $PSScriptName) $file
				if (-not (Split-Path $tempFolder -Parent) -eq $file) { $tempFolder = Join-Path $tempFolder $file }
				Write-Verbose "tempFolder:$tempFolder"
				if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force }
				if (!(Test-Path $tempFolder)) {
					Write-Verbose "New-Item $tempFolder"
					New-Item -Path $tempFolder -ItemType Directory | Out-Null
				}
				$zips | ForEach-Object {
					#$zipstream = New-Object IO.MemoryStream($_, [IO.FileMode]::Open)
					$tempZipName = "$tempFolder/$($_.Name)"
					Write-Verbose '####################################################################################################'
					Write-Verbose "ExtractToFile($_,$tempZipName)"
					if (Test-Path $tempZipName) { Remove-Item $tempZipName -force | Out-Null }
					[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $tempZipName)
					#$zipstream = New-Object IO.FileStream($_, [IO.FileMode]::Open)
					Write-Verbose '####################################################################################################'
					$zipstream = New-Object IO.FileStream($tempZipName, [IO.FileMode]::Open)
					$zipzip = New-Object IO.Compression.ZipArchive($zipstream)
					if (!$search) { $search = @('*.*')}
					foreach($query in $search) {
						Write-Verbose "query:$query"
						$queryResults = ($zipzip.Entries | Where-Object { $_.FullName -Like $query }) #| ForEach-Object { $_ }
						Write-Verbose "query.count:$($queryResults.Length)"
						#$results += $queryResults
						if ($queryResults -and $queryResults.Length -gt 0) {
							#$results.AddRange($queryResults)
							$zipresults += $queryResults
						}
						#$results = $results.foreach({ $queryResults })
					}

					if ($zipstream) {
						Write-Verbose "$($PSScriptName):Closing zipstream"
						Write-Verbose '####################################################################################################'
						$zipstream.Close()
						$zipstream.Dispose()
					}


					#$tempZipPath = "$tempFolder\$($_.FullName)"
					#if (Test-Path $tempZipPath) { Remove-Item $tempZipPath -Recurse -Force }
					#if (!(Test-Path $tempZipPath)) {
				#		Write-Verbose "Expanding $path"
				#		Expand-Archive -Force -Path $path -DestinationPath $tempFolder
				#	}




					#$zipResults = .\Get-ArchiveEntries "$tempFolder\$($_.FullName)" $search

					#$zipstream = New-Object IO.FileStream($path, [IO.FileMode]::Open)
					
					Write-Verbose "zipResults:$zipResults"
					if ($zipResults) {
						#$results.AddRange($zipResults)
						$results += $zipresults
					}
				}
			}

			if ($zip) {	$zip.Dispose() }
			if ($stream) {
				Write-Verbose "$($PSScriptName):Closing stream"
				Write-Verbose '####################################################################################################'
				$stream.Close()
				$stream.Dispose()
			}

			Write-Verbose "$($PSScriptName):$($path):end"
			Write-Verbose '####################################################################################################'			
		}
	}
}
catch {
	Write-Error "ERROR $PSScriptName $($path) $($search):$_"
}

Write-Verbose "results:$results"
Write-Verbose "results.count:$($results.Length)"
return $results