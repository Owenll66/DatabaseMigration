param(
    [ValidateSet("Update", "Drop", "ReCreate")]
    [string]$Option = "Update"
)
begin
{
    # Stop on the first error.
    $ErrorActionPreference = "Stop"
    Set-StrictMode -Version Latest

    # Global variables
    $SettingFilePath = ".\settings.json"
    $MigrationPath = ".\Migration"

    Push-Location $PSScriptRoot

    enum DatabaseTypes {
        MSSQL
        # More databases can be supported in the future.
    }

    class MigrationSettings {
        [string]$ConnectionString
        [DatabaseTypes]$DatabaseType
    }

    $MigrationSettings = [MigrationSettings](Get-Content $SettingFilePath | Out-String | ConvertFrom-Json)

    $ScriptPath = Resolve-Path ".\Scripts\$($MigrationSettings.DatabaseType)"
    $MigrationFullPath = Resolve-Path $MigrationPath

    $DbStringBuilder = New-Object System.Data.Common.DbConnectionStringBuilder
    $DbStringBuilder.set_ConnectionString($MigrationSettings.ConnectionString)

    [string]$ServerInstance = $null;
    [string]$DatabaseName = $null;

    Write-Host $DbStringBuilder.TryGetValue('data source', [ref]$ServerInstance);
    $DbStringBuilder.TryGetValue('initial catalog', [ref]$DatabaseName);

    $line = new-object System.String '-', ($Host.ui.RawUI.BufferSize.Width)
    Write-Host $line -ForegroundColor Green
    Write-Host "Database Type      |    $($MigrationSettings.DatabaseType)" -ForegroundColor Green
    Write-Host "Script Path        |    $($ScriptPath)" -ForegroundColor Green
    Write-Host "Migration Path     |    $($MigrationFullPath)" -ForegroundColor Green
    Write-Host "Server Instance    |    $($ServerInstance)" -ForegroundColor Green
    Write-Host "Database Name      |    $($DatabaseName)" -ForegroundColor Green
    Write-Host $line -ForegroundColor Green

    Write-Host "`n"
}
process
{
    # Create database if not exists.
    function Set-Database([string]$DatabaseName)
    {
        $Parameters = "DatabaseName='$DatabaseName'"
        $Sql = "IF NOT EXISTS (SELECT [name] FROM sys.databases WHERE [name] = `$(DatabaseName))
                CREATE DATABASE `$(DatabaseName)"

        # Create Database if not exist.
        $result = Invoke-Sqlcmd -ConnectionString $MigrationSettings.ConnectionString -Query $Sql -Variable $Parameters

        Write-Host $result
    }

    switch ($Option)
    {
        Update
        {
            Set-Database $DatabaseName
        }
        Drop
        {
            Write-Host "Drop"
        }
        ReCreate
        {
            Write-Host "ReCreate"
        }
        default
        {
            Write-Error "The migration option specified is not valid. Valid options include 'Update', 'Drop', 'ReCreate'" -ErrorAction Stop
        }
    }

    function Invoke-Migration()
    {
    }
}
end {
    Pop-Location
}