Describe 'Script Tests' {
    It 'passes ScriptAnalyzer' {
        Invoke-ScriptAnalyzer -Path Get-ArchiveEntries.ps1 | Should -BeNullOrEmpty
    }

    It 'passes no params' {
        .\Get-ArchiveEntries.ps1 | Should -BeNullOrEmpty
    }

    It 'passes recurse' {
        .\Get-ArchiveEntries.ps1 -recurse | Should -Not -BeNullOrEmpty
    }

    It 'passes smoke-test' {
        .\Get-ArchiveEntries.ps1 (Join-Path $PSScriptRoot 'smoke-test.zip') -recurse | Should -Not -BeNullOrEmpty
    }

    It 'passes smoke-test-data' {
        .\Get-ArchiveEntries.ps1 ".\smoke-test-data.zip" @('items/core/*','items/master/*','properties/items/core/*','properties/items/master/*','core.dacpac','master.dacpac') -recurse| Should -Not -BeNullOrEmpty
    }
}