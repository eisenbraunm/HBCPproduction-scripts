


-- this goes through table by table replacing the image paths to the new location
-- takes a bout a min
print 'start  ****'

update TBL_INTERACT_FIELDS   set   VIEW_FIELD_WIDTH=401  where   VIEW_FIELD_NAME='PARALLEL' and   (IA_DOC_TABLE_REF = N'INT_TBL_12_02_01')

update TBL_INTERACT_FIELDS   set   VIEW_FIELD_WIDTH=401  where   VIEW_FIELD_NAME='PERPENDICULAR' and   (IA_DOC_TABLE_REF = N'INT_TBL_12_02_01')

declare  @docRef nvarchar(50),
@docID int,
@oldpath nvarchar(250),
@oldpath2 nvarchar(250),
@newpath nvarchar(250),
@sql nvarchar(2000),
@temp nvarchar(300)

Declare Doc_cursor CURSOR
For
SELECT DISTINCT TBL_DOC_CONTENT.DOCUMENT_ID, TBL_DOCUMENT.DOCUMENT_REF
FROM            TBL_DOCUMENT INNER JOIN
                         TBL_DOC_CONTENT ON TBL_DOCUMENT.ID = TBL_DOC_CONTENT.DOCUMENT_ID INNER JOIN
                         TBL_DOC_CONTENTS ON TBL_DOC_CONTENT.ID = TBL_DOC_CONTENTS.DOC_CONTENT_ID INNER JOIN
                         TBL_DOC_TABLE ON TBL_DOC_CONTENTS.DOC_TABLE_ID = TBL_DOC_TABLE.ID
WHERE        (TBL_DOC_CONTENT.FOR_WEB = 1)
ORDER BY TBL_DOCUMENT.DOCUMENT_REF

  open Doc_cursor
Fetch Doc_cursor INTO @docID,@docRef
while @@fetch_status =0
begin



set @temp= '0000'+ltrim(rtrim(Convert(char(6),@docID)));
set @temp=RIGHT(@temp, 6);
set  @oldpath ='../../../HBCPdiagrams/doc'+@temp;
set  @oldpath2 ='../../HBCPdiagrams/doc'+@temp;--found some errors in input system
print @oldpath
set  @newpath ='../documents/'+@docRef+'/jpg';
 print @newpath



 Declare Field_cursor CURSOR
For
SELECT       TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF, TBL_INTERACT_FIELDS.VIEW_FIELD_NAME
FROM            TBL_DOC_CONTENT INNER JOIN
                         TBL_DOCUMENT ON TBL_DOC_CONTENT.DOCUMENT_ID = TBL_DOCUMENT.ID INNER JOIN
                         TBL_DOC_CONTENTS ON TBL_DOC_CONTENT.ID = TBL_DOC_CONTENTS.DOC_CONTENT_ID INNER JOIN
                         TBL_INTERACT_FIELDS ON TBL_DOC_CONTENTS.DOC_TABLE_ID = TBL_INTERACT_FIELDS.DOC_TABLE_ID INNER JOIN
                         TBL_FIELD ON TBL_INTERACT_FIELDS.FIELD_ID = TBL_FIELD.ID
WHERE        (TBL_FIELD.TBL_PROPERTY_ID IS NULL) AND (TBL_FIELD.DATA_TYPE = N'nvarchar') AND (TBL_FIELD.DATA_WIDTH > 50) AND (TBL_DOCUMENT.ID = @docID)
declare @tableRef nvarchar(50),
 @field nvarchar(200)

  open Field_cursor
Fetch Field_cursor INTO  @tableRef,@field
while @@fetch_status =0
begin
-- update the values from the property table sort fields
set @sql='UPDATE '+@tableRef + ' SET '+@field +'=REPLACE('+@field+','''+@oldpath+''','''+@newpath+''')'
Execute (@sql)
print @sql

set @sql='UPDATE '+@tableRef + ' SET '+@field +'=REPLACE('+@field+','''+@oldpath2+''','''+@newpath+''')'

Execute (@sql)
print @sql




--end of table loop
Fetch Field_cursor INTO  @tableRef,@field
END
deallocate Field_cursor

Fetch Doc_cursor INTO @docID,@docRef
END
deallocate Doc_cursor
go

print '**** complete *****'
