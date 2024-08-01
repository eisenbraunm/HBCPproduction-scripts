
-- this script creates and populates the property sort fields on the tables
--takes about 2 mins
declare  @tableRef nvarchar(50),
@tableID int,
@sql nvarchar(2000)


SET NOCOUNT ON



--start the table loop i.e. all table that are not deleted


Declare Tables_cursor CURSOR
For
SELECT DISTINCT TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF, TBL_INTERACT_FIELDS.DOC_TABLE_ID
FROM            TBL_DOC_TABLE INNER JOIN
                         TBL_INTERACT_FIELDS ON TBL_DOC_TABLE.ID = TBL_INTERACT_FIELDS.DOC_TABLE_ID
WHERE        (TBL_DOC_TABLE.CRCNUM = 1)
ORDER BY TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF, TBL_INTERACT_FIELDS.DOC_TABLE_ID

  open Tables_cursor
Fetch Tables_cursor INTO @tableRef, @tableID
while @@fetch_status =0
begin


print 'starting property sorts for  table ' +@tableRef

Declare PROD_Fields_cursor CURSOR
For
SELECT        TBL_INTERACT_FIELDS.VIEW_FIELD_NAME, TBL_PROPERTY.TABLE_NAME, TBL_INTERACT_FIELDS.ID AS IAfieldId
                   
FROM            TBL_INTERACT_FIELDS INNER JOIN
                         TBL_FIELD ON TBL_INTERACT_FIELDS.FIELD_ID = TBL_FIELD.ID INNER JOIN
                         TBL_PROPERTY ON TBL_FIELD.TBL_PROPERTY_ID = TBL_PROPERTY.ID
WHERE        (TBL_INTERACT_FIELDS.VIEW_DATA_TYPE <> N'int') AND (TBL_INTERACT_FIELDS.DOC_TABLE_ID = @tableID) AND 
                         (TBL_INTERACT_FIELDS.SORT_FIELD_NAME IS NULL)
ORDER BY TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF

declare

@viewFieldName as nVARCHAR(500),
@propTable as nVARCHAR(500),
@IAfieldId as nVARCHAR(50),
@sortField as nVARCHAR(150)



open PROD_Fields_cursor
Fetch PROD_Fields_cursor INTO  @viewFieldName,@propTable,@IAfieldId
while @@fetch_status =0

begin
set @sortField=@viewFieldName+'_SORT'

-- check if the sort field exists, if not create it
	IF COL_LENGTH(@tableRef  ,@sortField) IS  null
	BEGIN
	set @sql='ALTER TABLE [dbo].['+@tableRef+'] ADD '+@sortField+' int';
	Execute (@sql)
	end 
 
-- update the values from the property table sort fields
 set @sql='UPDATE '+@tableRef + ' SET '+ @sortField +' = (SELECT top 1 '+ @sortField+  ' FROM '+ @propTable+  ' WHERE '+@tableRef + ' .crcnum='+ @propTable+ '.crcnum)';
 Execute (@sql)
 -- update the interctive fields table with the new sortfield name
 update TBL_INTERACT_FIELDS set SORT_FIELD_NAME=@sortField where ID=@IAfieldId
 --now set null values to a high number
 set @sql='update '+@tableRef + ' SET '+ @sortField +'  =99999999 where '++@viewFieldName + ' IS null'
 Execute (@sql)


Fetch PROD_Fields_cursor INTO  @viewFieldName,@propTable,@IAfieldId
end

deallocate PROD_Fields_cursor

--end of table loop

Fetch Tables_cursor INTO @tableRef, @tableID
END
deallocate Tables_cursor
go

print '**** properties done - next mol wt*****'


declare  @tableRef nvarchar(50),
@tableID int,
@sql nvarchar(2000),
@sortField as nVARCHAR(150),
@IAfieldId as int






--start the table loop i.e. all table that are not deleted


Declare molwt_cursor CURSOR
For
SELECT DISTINCT TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF, TBL_INTERACT_FIELDS.DOC_TABLE_ID,TBL_INTERACT_FIELDS.ID
FROM            TBL_DOC_TABLE INNER JOIN
                         TBL_INTERACT_FIELDS ON TBL_DOC_TABLE.ID = TBL_INTERACT_FIELDS.DOC_TABLE_ID
WHERE        (TBL_DOC_TABLE.CRCNUM = 1) AND (TBL_INTERACT_FIELDS.VIEW_FIELD_NAME = N'MOLWT')
ORDER BY TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF, TBL_INTERACT_FIELDS.DOC_TABLE_ID

  open molwt_cursor
Fetch molwt_cursor INTO @tableRef, @tableID,@IAfieldId
while @@fetch_status =0
begin



set @sortField='MOLWT_SORT'

-- check if the sort field exists, if not create it
	IF COL_LENGTH(@tableRef  ,@sortField) IS  null
	BEGIN
	set @sql='ALTER TABLE [dbo].['+@tableRef+'] ADD '+@sortField+' int';
	Execute (@sql)
	end 
 
-- update the values from the property table sort fields
 set @sql='UPDATE '+@tableRef + ' SET '+ @sortField +' = (SELECT top 1 '+ @sortField+  ' FROM TBL_SUBSTANCES WHERE '+@tableRef + ' .crcnum=TBL_SUBSTANCES.crcnum)';
 Execute (@sql)
 -- update the interctive fields table with the new sortfield name
 update TBL_INTERACT_FIELDS set SORT_FIELD_NAME=@sortField where ID=@IAfieldId
 --now set null values to a high number
 set @sql='update '+@tableRef + ' SET '+ @sortField +'  =99999999 where MOLWT IS null'
 Execute (@sql)




--end of table loop

Fetch molwt_cursor INTO @tableRef, @tableID,@IAfieldId
END
deallocate molwt_cursor
go

print '**** complete *****'







