
-- about a MIN
SET NOCOUNT ON

print '***** start subheading sort*****'

Declare Subheading_Fields_cursor CURSOR
For
SELECT       IA_DOC_TABLE_REF,ID
FROM            TBL_INTERACT_FIELDS
WHERE        (VIEW_FIELD_NAME = N'SUBHEADING_ID') order by IA_DOC_TABLE_REF

declare

@tableRef as nVARCHAR(500),
@sortField as nVARCHAR(150),
@sortNum as int,
@sql as nvarchar(2000),
@id as int,
@oldtableRef as nVARCHAR(500)



open Subheading_Fields_cursor
Fetch Subheading_Fields_cursor INTO  @tableRef,@id 
while @@fetch_status =0

begin
print 'subheadings for table '+@tableRef

	
set @sortField='SUBHEADING_ID_SORT'

-- check if the sort field exists, if not create it
	IF COL_LENGTH(@tableRef  ,@sortField) IS  null
	BEGIN
	set @sql='ALTER TABLE [dbo].['+@tableRef+'] ADD '+@sortField+' int';
	Execute (@sql)
	end 

set @oldtableRef=	(SELECT RIGHT(@tableRef, 12))
 
set @sql= 'update u set u.SUBHEADING_ID_SORT= s.SUBHEADING_SORT
FROM            '+@tableRef+' AS u INNER JOIN
                         '+@oldtableRef+' AS q ON q.ORDERING = u.ORDERING INNER JOIN
                         TBL_DOC_TABLE_SUBHEADING AS s ON q.SUBHEADING_ID = s.ID'
	
Execute(@sql)

set @sql= 		'update '+@tableRef+' set SUBHEADING_ID_SORT=99999999 where SUBHEADING_ID_SORT=null';

Execute(@sql)
		

 update TBL_INTERACT_FIELDS set SORT_FIELD_NAME=@sortField where ID=@id 

Fetch Subheading_Fields_cursor INTO @tableRef,@id 
end




deallocate Subheading_Fields_cursor


go

print '**** update titles *****'
-- get the subheader titles
UPDATE TBL_INTERACT_FIELDS SET COLUMN_NAME = (SELECT top 1 SUBHEAD_TITLE FROM  TBL_DOC_TABLE  WHERE TBL_DOC_TABLE.id=TBL_INTERACT_FIELDS.DOC_TABLE_ID  and SUBHEAD_TITLE is not null )
where       (VIEW_FIELD_NAME = N'SUBHEADING_ID')
go

print '**** complete *****'
