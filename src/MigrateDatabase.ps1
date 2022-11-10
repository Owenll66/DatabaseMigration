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

    class MigrationSettings {
        [string]$ConnectionString
    }

    $MigrationSettings = [MigrationSettings](Get-Content $SettingFilePath | Out-String | ConvertFrom-Json)

    $ScriptPath = Resolve-Path ".\Scripts\"
    $MigrationFullPath = Resolve-Path $MigrationPath

    $DbStringBuilder = New-Object System.Data.Common.DbConnectionStringBuilder
    $DbStringBuilder.set_ConnectionString($MigrationSettings.ConnectionString)

    [string]$ServerInstance = $null;
    [string]$DatabaseName = $null;

    $DbStringBuilder.TryGetValue('data source', [ref]$ServerInstance);

    # Remove initial database from the connection string. Because the database
    # may not exist and cause connection failure when calling Set-Database.
    if (!$DbStringBuilder.TryGetValue('initial catalog', [ref]$DatabaseName))
    {
        $DbStringBuilder.TryGetValue('database', [ref]$DatabaseName)
    }

    $line = new-object System.String '-', ($Host.ui.RawUI.BufferSize.Width)
    Write-Host $line -ForegroundColor Green
    Write-Host "Script Path        |    $($ScriptPath)" -ForegroundColor Green
    Write-Host "Migration Path     |    $($MigrationFullPath)" -ForegroundColor Green
    Write-Host "Server Instance    |    $($ServerInstance)" -ForegroundColor Green
    Write-Host "Database Name      |    $($DatabaseName)" -ForegroundColor Green
    Write-Host $line -ForegroundColor Green

    # Create database if not exists.
    function Set-Database
    {
        Write-Host "Updating database..."

        $Parameters = "DatabaseName=$DatabaseName"

        # Create Database if not exists.
        Invoke-Sqlcmd -ConnectionString $DbStringBuilder.ConnectionString -InputFile "$ScriptPath\CreateDbIfNotExists.sql" -Variable $Parameters

        # Create table to track schema changes.
        Invoke-Sqlcmd -ConnectionString $DbStringBuilder.ConnectionString -InputFile "$ScriptPath\CreateSchemaChangesTable.sql" -Database $DatabaseName

        Write-Host "Database '$DatabaseName' has been updated successfully."
    }

    # Drop database if not exists.
    function Remove-Database
    {
        Write-Host "Dropping database..."

        $Parameters = "DatabaseName=$DatabaseName"
        $Sql = "DROP DATABASE [`$(DatabaseName)]"

        # Create Database if not exists.
        Invoke-Sqlcmd -ConnectionString $DbStringBuilder.ConnectionString -Query $Sql -Variable $Parameters

        Write-Host "Database '$DatabaseName' has been dropped successfully."
    }

    # Invoke database migration.
    function Invoke-Migration
    {

    }
}
process
{
    switch ($Option)
    {
        Update
        {
            Set-Database
            Invoke-Migration
        }
        Drop
        {
            Remove-Database
        }
        ReCreate
        {
            Remove-Database
            Set-Database $DatabaseName
        }
        default
        {
            Write-Error "The migration option specified is not valid. Valid options include 'Update', 'Drop', 'ReCreate'" -ErrorAction Stop
        }
    }
}
end {
    Pop-Location
}