
/* 
Populate the doc extra info table for the extra info dialog in entries
This is part of the production process for HBCP releases
Run this script on creation of the website DB from the Production DB.
MJ GRIFFITHS
*/

--USE HBCP_DATABASE
--GO

--Delete current table data
DELETE FROM TBL_DOC_EXTRA_INFO
GO

--Reseed the ident column. Not essential but prevents the numbers getting stupidly high in the future
DBCC CHECKIDENT (TBL_DOC_EXTRA_INFO, RESEED, 0);
GO

--copy data from documents that are split only.
INSERT INTO TBL_DOC_EXTRA_INFO (DOCUMENT_ID, DOCUMENT_REF, DOCUMENT_SPLIT, MAJOR_UPDATE, LAST_UPDATE)
SELECT ID, DOCUMENT_REF, SPLIT, MAJOR_UPDATE, MINOR_UPDATE
FROM TBL_DOCUMENT
WHERE SPLIT=1
GO

--Look for doc table differences
--create the variables for the select.
DECLARE @docTableRef nvarchar(50),
@docTableName nvarchar(2000),
@docTableId nvarchar(10),
@docId int

--create cursor to iterate over doc_table.
DECLARE Tables_cursor CURSOR
FOR

--get a list of doc tables
SELECT DISTINCT DT.DOCUMENT_TABLE_REF, DT.DOCUMENT_TABLE_NAME, DT.ID, DC.DOCUMENT_ID
FROM          TBL_DOC_TABLE AS DT INNER JOIN
              TBL_DOC_CONTENTS ON DT.ID = TBL_DOC_CONTENTS.DOC_TABLE_ID INNER JOIN
              TBL_DOC_CONTENT AS DC ON TBL_DOC_CONTENTS.DOC_CONTENT_ID = DC.ID
ORDER BY      DT.DOCUMENT_TABLE_REF

--iterate over cursor
OPEN Tables_cursor
FETCH NEXT FROM Tables_cursor INTO @docTableRef, @docTableName, @docTableId, @docId
WHILE @@fetch_status = 0
BEGIN

print 'Finding row and column differences for ' + @docTableRef
--print 'docTableId= ' + @docTableId

DECLARE @webExtraRows int,
@diffColumns int

--see whether table has any rows set not for print
declare @sql2 nvarchar(2000) = N'set @count=(SELECT COUNT(FOR_PRINT) AS WEB_EXTRA_ROWS FROM ' + @docTableRef + ' WHERE FOR_PRINT=0)'
exec sp_executesql @sql2, N'@count int output', @webExtraRows output

--see whether table has any columns visible in table but only in either web or print.  >0 means table cols are different in book vs web
declare @sqlFld nvarchar(2000) = N'set @countFld=(SELECT COUNT(*) AS COUNT FROM TBL_FIELD WHERE DOC_TABLE_ID = ' + @docTableId + ' AND IS_VISIBLE = 1 AND FOR_PRINTED <> FOR_WEB)'
exec sp_executesql @sqlFld, N'@countFld int output', @diffColumns output

DECLARE @diffColsBool bit

--set the boolean value to be inserted for DOC_TABLE_DIFF_FIELDS
IF @diffColumns > 0
BEGIN
SET @diffColsBool = 1
print '***COL DIFFERENCES FOUND*** = ' + CAST(@diffColumns as VARCHAR)
END
ELSE
SET @diffColsBool = 0

--set DOC_TABLE_EXTRA_ROWS to null if 0
IF @webExtraRows = 0
BEGIN
SET @webExtraRows = null
END
ELSE
print '***WEB EXTRA ROWS FOUND*** = ' + CAST(@webExtraRows as VARCHAR)

--if table has either diff cols or extra web rows then insert a row into table
IF (@diffColsBool = 1 OR @webExtraRows > 0)
BEGIN
print 'Inserting row in TBL_DOC_EXTRA_INFO for ' + @docTableRef
INSERT INTO TBL_DOC_EXTRA_INFO (DOCUMENT_ID, DOC_TABLE_ID, DOC_TABLE_REF, DOC_TABLE_NAME, DOC_TABLE_EXTRA_ROWS, DOC_TABLE_DIFF_FIELDS)
VALUES (@docId, @docTableId, @docTableRef, @docTableName, @webExtraRows, @diffColsBool)

END

FETCH NEXT FROM Tables_cursor INTO @docTableRef, @docTableName, @docTableId, @docId
END
CLOSE Tables_cursor
DEALLOCATE Tables_cursor