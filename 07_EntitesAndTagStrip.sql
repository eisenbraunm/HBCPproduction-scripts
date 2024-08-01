
-- this populates convert some common named entities such as &alpha; to their numerical equivalent
-- also copy footnote overlay from old references

-- this is needed to make searching consistent- i.e. all entities are numerical
-- this takes about 15mins
print 'start relacing name entities with numerical ones in all varchar fields ****'
declare  @tableRef nvarchar(50),
@columnName nvarchar(150),
@sql nvarchar(2000),
@temp nvarchar(1500)

SET NOCOUNT off

Declare Entity_cursor CURSOR
For


SELECT        TABLE_NAME, COLUMN_NAME
FROM            INFORMATION_SCHEMA.COLUMNS
WHERE        (TABLE_NAME LIKE 'INT_%') AND (DATA_TYPE = 'nvarchar')
ORDER BY TABLE_NAME


  open Entity_cursor
Fetch Entity_cursor INTO @tableRef,@columnName

while @@fetch_status =0

begin

print 'Numerical Ents ' + @tableRef +' '+@columnName
SET @sql = 'UPDATE  '+@tableRef+' set  '+@columnName+'= dbo.convertHTMLentsToNumerical('+ @columnName+');'
Execute ( @sql)

	
Fetch Entity_cursor INTO @tableRef,@columnName


END

deallocate Entity_cursor



go

print '***** Start footnote overlay*****'
Delete from TBL_IA_FOOTNOTE_OVERLAY 
go


Declare Overlay_cursor CURSOR
For


SELECT        TBL_DOC_TABLE.ID, TBL_FOOT_OVERLAY.TABLE_ROW_ID, TBL_FOOT_OVERLAY.TAG, 
                         TBL_INTERACT_FIELDS.ORDERING AS columnOrder,DOCUMENT_TABLE_REF
FROM            TBL_FOOT_OVERLAY INNER JOIN
                         TBL_DOC_TABLE ON TBL_FOOT_OVERLAY.DOC_TABLE_ID = TBL_DOC_TABLE.ID INNER JOIN
                         TBL_INTERACT_FIELDS ON TBL_FOOT_OVERLAY.FIELD_ID = TBL_INTERACT_FIELDS.FIELD_ID
ORDER BY TBL_DOC_TABLE.DOCUMENT_TABLE_REF

declare   @tableId int, 
@rowId int,
@tag varchar(50),
@columnOrder int,
@rowOrder int,
@query nvarchar(500),
@docRef nvarchar(50),
@hasCRC bit,
@hasSubheading bit



open Overlay_cursor
Fetch Overlay_cursor INTO @tableId,@rowId,@tag,@columnOrder,@docRef
while @@fetch_status =0

begin
SET @query = N'SELECT @rowOrder = ORDERING FROM '+ @docRef+' where ID='+ CONVERT(Char(7), @rowId) +';'

EXEC sp_executesql @query, 
                   N'@rowOrder int OUTPUT', 
                  @rowOrder = @rowOrder OUTPUT

set @columnOrder= @columnOrder+2;
SET @hasSubheading  = (Select top 1 subheading from TBL_DOC_TABLE where ID=@tableId)

if @hasSubheading=1
begin
set @columnOrder= @columnOrder-1;
--print 'has subheading -tableid '+Convert(char(10),@tableId) + ' '+ @docRef;
end
SET @hasCRC = (Select top 1 crcnum from TBL_DOC_TABLE where ID=@tableId)
if @hasCRC=1
begin
set @columnOrder= @columnOrder-1;
--print 'has crcnum -tableid '+Convert(char(10),@tableId) + ' '+ @docRef;
end

--print Convert(char(10),@columnOrder) + ' -tableid '+Convert(char(10),@tableId) + ' '+ @docRef;

insert TBL_IA_FOOTNOTE_OVERLAY (DOC_TABLE_ID,COLUMN_ORDER_NUM,ROW_ORDER_NUM,TAG)values(@tableId,@columnOrder,@rowOrder,@tag);



Fetch Overlay_cursor INTO  @tableId,@rowId,@tag,@columnOrder,@docRef

END

  deallocate Overlay_cursor

go
print '***** complete*****'