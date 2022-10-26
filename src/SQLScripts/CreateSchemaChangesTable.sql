IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID('dbo.SchemaChanges'))
BEGIN
    CREATE TABLE [dbo].[SchemaChanges] (
        [ID]         INT            IDENTITY (1, 1) NOT NULL,
        [ScriptName] VARCHAR(255)   NOT NULL CONSTRAINT [UC_ScriptName] UNIQUE,
        [State]      CHAR(1)        NOT NULL CONSTRAINT [DF_SchemaChanges_State] DEFAULT ('A'),
        [Applied]    DateTime       NOT NULL CONSTRAINT [DF_SchemaChanges_Applied] DEFAULT(CURRENT_TIMESTAMP),
        [AppliedBy]  VARCHAR(255)   NOT NULL CONSTRAINT [DF_SchemaChanges_AppliedBy] DEFAULT (suser_name()),
        [Modified]   DateTime,
        [ModifiedBy] VARCHAR(255),
        CONSTRAINT [PK_SchemaChanges_ID] PRIMARY KEY CLUSTERED ([ID] ASC),
        CONSTRAINT [CK_SchemaChanges_State] CHECK ([State] = 'R' OR [State] = 'A'),
    )

    PRINT 'Created schema change tracking table'
END

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[TR_SchemaChanges_Update]'))
BEGIN
    DECLARE @SQL VARCHAR(MAX)

    SET @SQL = 'CREATE TRIGGER [dbo].[TR_SchemaChanges_Update]
        ON [dbo].[SchemaChanges]
        FOR UPDATE
        AS
        BEGIN
            SET NoCount ON

            UPDATE [dbo].[SchemaChanges]
            SET
                Modified = GETUTCDATE(),
                ModifiedBy = SUSER_NAME()
            FROM [dbo].[SchemaChanges]
            INNER JOIN inserted ON  [dbo].[SchemaChanges].[ID] = inserted.[ID];

        END'
    EXECUTE (@SQL)
END