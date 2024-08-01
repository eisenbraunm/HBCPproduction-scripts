
--creates and populates a table of all crcnums in all doc tables for the list of other doc tables where the substance occurs in the entry popup

--create the table if not exist

IF ( not EXISTS  (SELECT 1 FROM sys.tables WHERE name = 'TBL_DOC_TABLE_SUBSTANCES'))
BEGIN
CREATE TABLE TBL_DOC_TABLE_SUBSTANCES
(
ID int IDENTITY(1,1) NOT NULL,
CRCNUM int NOT NULL,
DOCUMENT_TABLE_ID int NOT NULL,
DOCUMENT_TABLE_REF nvarchar(50) NOT NULL,
DOCUMENT_TABLE_NAME nvarchar(2000),
SECTION_ID int NOT NULL,
SECTION_ORDER int,
SECTION_TITLE nvarchar(1000),
DOCUMENT_ID int NOT NULL,
DOCUMENT_ORDER int,
DOCUMENT_REF nvarchar(15) NOT NULL,
DOCUMENT_TITLE nvarchar(1000)
);

CREATE NONCLUSTERED INDEX crcnum_index ON TBL_DOC_TABLE_SUBSTANCES(CRCNUM)

END
GO

DELETE FROM TBL_DOC_TABLE_SUBSTANCES
GO


--create the variables for the select.  these will be inserted into the new table
DECLARE @docTableRef nvarchar(50),
@tableRef nvarchar(50),
@docTableId int,
@docTableName nvarchar(2000),
@sectionId int,
@sectionOrder int,
@sectionTitle nvarchar(1000),
@docId int,
@docOrder int,
@docRef nvarchar (15),
@docTitle nvarchar(1000)

--create the cursor and select the variables for each doc table in HBCP
Declare Tables_cursor CURSOR
For 
SELECT DISTINCT       DT.DOCUMENT_TABLE_REF, DT.DOCUMENT_TABLE_NAME, DT.ID AS DOCUMENT_TABLE_ID, D.DOCUMENT_REF, D.ID AS DOCUMENT_ID, D.TITLE AS DOCUMENT_TITLE, 
                         D.TOC_ORDER AS DOCUMENT_ORDER, D.SECTION_ID, S.SECTION_ORDER, S.NAME AS SECTION_NAME
FROM            TBL_DOC_TABLE AS DT INNER JOIN
                         TBL_DOC_CONTENTS AS DCS ON DT.ID = DCS.DOC_TABLE_ID INNER JOIN
                         TBL_DOC_CONTENT AS DC ON DCS.DOC_CONTENT_ID = DC.ID INNER JOIN
                         TBL_DOCUMENT AS D ON DC.DOCUMENT_ID = D.ID INNER JOIN
                         TBL_SECTIONS AS S ON D.SECTION_ID = S.ID
WHERE        (DT.CRCNUM = 1) AND (SECTION_ID <> 1021) AND (DC.FOR_WEB = 1)
ORDER BY S.SECTION_ORDER, DOCUMENT_ORDER, DT.DOCUMENT_TABLE_REF

--iterate over the cursor to get each row
open Tables_cursor
Fetch NEXT FROM Tables_cursor INTO @docTableRef, @docTableName, @docTableId, @docRef, @docId, @docTitle, @docOrder, @sectionId, @sectionOrder, @sectionTitle
while @@fetch_status =0
begin


print 'starting crcnum insert from table ' +@docTableRef

--now find all crcnums in each table and put into another cursor
DECLARE @crcCursor CURSOR

DECLARE @crcnum int,
@sql nvarchar(2000),
@vsql nvarchar(2000),
@insert nvarchar(max)
-- select unique crcnums in the table.  remember they may be null or may exist >1 in each table
SET @sql = 'SELECT DISTINCT CRCNUM FROM [dbo].['+@docTableRef+'] WHERE CRCNUM IS NOT NULL ORDER BY CRCNUM';
-- this is how to use a variable as a cursor. see http://www.codeproject.com/Articles/489617/Create-a-Cursor-using-Dynamic-SQL-Query
SET @vsql = 'set @cursor = cursor forward_only static for ' + @sql + ' open @cursor;'

EXEC sys.sp_executesql
@vsql
,N'@cursor cursor output'
,@crcCursor output

FETCH NEXT FROM @crcCursor INTO @crcnum

while (@@fetch_status = 0)
begin

--insert a row into the new table for each crcnum in the selected doc table

INSERT INTO [dbo].[TBL_DOC_TABLE_SUBSTANCES]
           ([CRCNUM]
           ,[DOCUMENT_TABLE_ID]
           ,[DOCUMENT_TABLE_REF]
           ,[DOCUMENT_TABLE_NAME]
           ,[SECTION_ID]
           ,[SECTION_ORDER]
           ,[SECTION_TITLE]
           ,[DOCUMENT_ID]
           ,[DOCUMENT_ORDER]
           ,[DOCUMENT_REF]
           ,[DOCUMENT_TITLE])
	VALUES
		   (@crcnum, @docTableId, @docTableRef, @docTableName, @sectionId, @sectionOrder, @sectionTitle, @docId, @docOrder, @docRef, @docTitle)

print 'crcnum ' + cast(@crcnum as varchar) + ' from ' + @docTableRef + ' inserted'

FETCH NEXT FROM @crcCursor INTO @crcnum

end

close @crcCursor
DEALLOCATE @crcCursor

Fetch NEXT FROM Tables_cursor INTO @docTableRef, @docTableName, @docTableId, @docRef, @docId, @docTitle, @docOrder, @sectionId, @sectionOrder, @sectionTitle

end

CLOSE Tables_cursor
DEALLOCATE Tables_cursor