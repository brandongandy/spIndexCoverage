SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO
IF OBJECT_ID('dbo.spIndexCoverage') IS NULL
  EXEC ('CREATE PROCEDURE dbo.spIndexCoverage AS RETURN 0;')
GO

ALTER PROCEDURE dbo.spIndexCoverage
	@DatabaseName NVARCHAR(128) = NULL, /* DB Name. If NULL, then defaults to current database. Required parameter. */
	@SchemaName NVARCHAR(128) = NULL, /* Schema where the table lives. Required parameter. */
	@TableName NVARCHAR(128) = NULL, /* Name of the table whose indexes we want to peek at. Required parameter. */
	@Help TINYINT = 0 /* Print help info. Optional parameter. */
AS
BEGIN
SET NOCOUNT ON;

IF @Help = 1 PRINT '
spIndexCoverage written by Brandon Gandy @ http://brandongandy.com

This stored procedure is intended to give a graphical representation of index coverage on a given table.

Each column output will match a column on the table being examined, plus a ''header'' column that will
name an index that lives on the table. A given column will display ''0'' if the column is not covered
by the index, ''1'' if the column is a key in the index, and ''2'' if the column is included in the index.

MIT License

Copyright (c) 2016 Brandon Gandy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.';

DECLARE @SQL NVARCHAR(MAX);
DECLARE @ParameterDefinition NVARCHAR(MAX);

SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
			SELECT @Result = CAST(object_id AS NVARCHAR(MAX)) FROM sys.objects 
			WHERE name = @TableName AND schema_id = (SELECT schema_id FROM sys.schemas WHERE name = @SchemaName)';
SET @ParameterDefinition = N'@TableName NVARCHAR(128), @SchemaName NVARCHAR(128), @Result NVARCHAR(MAX) OUT';

DECLARE @ObjectID NVARCHAR(MAX) = N'';
EXECUTE sp_executesql @SQL, @ParameterDefinition, @TableName, @SchemaName, @ObjectID OUTPUT;

SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
	SELECT @Result = STUFF((SELECT DISTINCT '','' + name
	FROM sys.columns
	WHERE object_id = @ObjectID
	FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''),1,1,'''');';
SET @ParameterDefinition = N'@ObjectID NVARCHAR(MAX), @Result NVARCHAR(MAX) OUT';

DECLARE @Columns NVARCHAR(MAX) = N'';
EXECUTE sp_executesql @SQL, @ParameterDefinition, @ObjectID, @Columns OUTPUT;

SET @SQL = N'USE ' + QUOTENAME(@DatabaseName) + N';
	SELECT
		*
	FROM (
		SELECT
			ind.name AS IndexName,
			ind.name AS IndexCount,
			col.name AS ColumnName
		FROM sys.index_columns AS icol
		JOIN sys.indexes ind ON ind.object_id = icol.object_id AND ind.index_id = icol.index_id
		JOIN sys.columns col ON col.object_id = icol.object_id AND col.column_id = icol.column_id
		WHERE icol.object_id = @ObjectID AND ind.is_hypothetical = 0
			UNION ALL
		SELECT
			ind.name AS IndexName,
			ind.name AS IndexCount,
			col.name AS ColumnName
		FROM sys.index_columns AS icol
		JOIN sys.indexes ind ON ind.object_id = icol.object_id AND ind.index_id = icol.index_id
		JOIN sys.columns col ON col.object_id = icol.object_id AND col.column_id = icol.column_id
		WHERE icol.object_id = @ObjectID AND icol.is_included_column = 1 AND ind.is_hypothetical = 0
	) AS base
	PIVOT (
		COUNT(IndexCount)
		FOR ColumnName in (' + @Columns + N')
	) AS pvt ORDER BY pvt.IndexName ASC';
SET @ParameterDefinition = N'@ObjectID NVARCHAR(MAX)';

EXECUTE sp_executesql @SQL, @ParameterDefinition, @ObjectID;
END
GO
