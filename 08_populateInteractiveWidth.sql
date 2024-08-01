
-- this populates the Data width field VIEW_FIELD_WIDTH
-- takes  couple of mins
declare  @tableRef nvarchar(50),
@tableID int,
@sql nvarchar(2000),
@temp nvarchar(1500),
@MaxWidth int




--start the table loop i.e. all table that are not deleted
Declare Tables_cursor CURSOR
For

SELECT        TBL_DOC_TABLE.ID
FROM            TBL_DOC_TABLE INNER JOIN
                         TBL_DOC_CONTENTS ON TBL_DOC_TABLE.ID = TBL_DOC_CONTENTS.DOC_TABLE_ID  
ORDER BY TBL_DOC_TABLE.DOCUMENT_TABLE_REF 
  open Tables_cursor
Fetch Tables_cursor INTO @tableID
while @@fetch_status =0
begin


--looping around tables------
set @tableRef=(Select DOCUMENT_TABLE_REF from TBL_DOC_TABLE where ID=@tableID)




Declare Widths_cursor CURSOR
For


SELECT        VIEW_FIELD_NAME,ID
FROM            TBL_INTERACT_FIELDS
WHERE        (DOC_TABLE_ID = @tableID) AND (VIEW_DATA_TYPE = N'nvarchar')  AND (VIEW_FIELD_NAME <> N'CAS_LONG')


declare   @VIEW_FIELD_NAME_W as nvarchar(1000),
@ID_W int




  open Widths_cursor
Fetch Widths_cursor INTO @VIEW_FIELD_NAME_W,@ID_W

while @@fetch_status =0

begin


-- find if thistable has a CRCNUM  '** String Query
DECLARE @query as nvarchar(1000);
SET @query = N'SELECT  @MaxWidth =max(len(dbo.tagstrip(' +  @VIEW_FIELD_NAME_W   +')))  FROM INT_'+@tableRef+' where ' +  @VIEW_FIELD_NAME_W   +' is not null;'
print 'ADDING width to '+@tableRef +' -' + @VIEW_FIELD_NAME_W
print  @query
EXEC sp_executesql @query, 
                   N'@MaxWidth int OUTPUT', 
                   @MaxWidth = @MaxWidth OUTPUT;
	


UPDATE  TBL_INTERACT_FIELDS set  VIEW_FIELD_WIDTH=@MaxWidth where ID=@ID_W;




Fetch Widths_cursor INTO @VIEW_FIELD_NAME_W,@ID_W



END



deallocate Widths_cursor

Fetch Tables_cursor INTO @tableID
END
deallocate Tables_cursor

go



-- name and cas should have set widths
UPDATE  TBL_INTERACT_FIELDS set  VIEW_FIELD_WIDTH=26 where VIEW_FIELD_NAME='CAS_LONG';

UPDATE  TBL_INTERACT_FIELDS set  VIEW_FIELD_WIDTH=(VIEW_FIELD_WIDTH+50) where VIEW_FIELD_NAME='NAME';

UPDATE  TBL_INTERACT_FIELDS set  VIEW_FIELD_WIDTH=(VIEW_FIELD_WIDTH +50) where VIEW_FIELD_NAME='SYNONYM';
Go
print '**** complete *****'
