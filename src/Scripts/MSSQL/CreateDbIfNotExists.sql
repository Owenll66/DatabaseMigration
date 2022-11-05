IF NOT EXISTS (SELECT [name] FROM sys.databases WHERE [name] = '$(DatabaseName)')
    CREATE DATABASE [$(DatabaseName)]
