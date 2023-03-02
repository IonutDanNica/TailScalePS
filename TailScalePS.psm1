#Requires -Version 7
[CmdletBinding()]
    param(		
        $InformationPreference = "Continue"
        )

#region get list of files to load
$ModuleObj = Get-Module -ListAvailable | Where-Object { $_.Path -like "$PSScriptRoot*" }

Write-Information "Starting to load module $($ModuleObj.Name), version $($ModuleObj.Version)"
$FunctionDirs = (Get-ChildItem -Path $PSScriptRoot -Directory -ErrorAction SilentlyContinue -Recurse).FullName
Write-Information "Found $(($FunctionDirs | Measure-Object).Count) function folders to import"

$PS1Files = $FunctionDirs | ForEach-Object { Get-ChildItem -Path $_ -Filter "*.ps1" -ErrorAction SilentlyContinue }
Write-Information "Found $(($PS1Files | Measure-Object).count) functions to import"

#Dot source the files
Foreach($import in $PS1Files) {
    Try {
        . $import.fullname
        }
    Catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }


Write-Information "Done importing module."