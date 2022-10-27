IF NOT EXISTS (SELECT * FROM sys.tables WHERE object_id = OBJECT_ID('dbo.SchemaChanges'))
BEGIN
    CREATE TABLE [dbo].[SchemaChanges] (
        [ID]                INT             IDENTITY (1, 1),
        [ScriptName]        VARCHAR(255)    NOT NULL CONSTRAINT [UQ_ScriptName] UNIQUE,
        [AppliedAt]         DateTime        NOT NULL CONSTRAINT [DF_SchemaChanges_Applied] DEFAULT(SYSDATETIMEOFFSET()),
        [ModifiedAt]        DateTime        NOT NULL,
        [ModifiedBy]        VARCHAR(255)    NOT NULL,
        CONSTRAINT [PK_SchemaChanges_ID] PRIMARY KEY ([ID])
    )
END

IF NOT EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[TR_SchemaChanges_Update]'))
BEGIN
    CREATE TRIGGER [TR_SchemaChanges_Update]
        ON [dbo].[SchemaChanges]
        AFTER UPDATE
    AS
    BEGIN
        UPDATE [dbo].[SchemaChanges]
        SET
            [ModifiedAt] = SYSDATETIMEOFFSET(),
            [ModifiedBy] = SUSER_NAME()
        FROM [dbo].[SchemaChanges]
        WHERE [ID] in (SELECT [ID] FROM INSERTED)
    END
END