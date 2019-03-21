# spIndexCoverage
A SQL Server stored procedure that provides graphical representation of index coverage.

This stored procedure is intended to be used to look through a table that contains an exorbitant number of indexes and columns. Such a scenario may have many performance implications and it's difficult or time consuming to review indexes one-by-one.

# Usage Instructions

## Installation
* Open a new query window in SSMS
* Use [master]
* Paste the contents of spIndexCoverage.sql in the query window and click Execute / hit F5 to run

## Usage
Syntax:  
```sql
EXEC dbo.spIndexCoverage
@DatabaseName = N'AdventureWorks',
@SchemaName = N'HumanResources',
@TableName = N'Employee'
```

# Improvements
Currently, the stored procedure doesn't distinguish between types of indexes, or how the column is included in the index. It simply counts each column that lives in an index.

Some distinction should be made between clustered / non-clustered, key columns, included columns, etc.
