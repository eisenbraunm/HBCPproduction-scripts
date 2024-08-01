
-- this script creates and populates the nvarchar unique sort fields on the tables
-- this one takes about -60mins
--also populates subheading sort
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
ORDER BY TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF, TBL_INTERACT_FIELDS.DOC_TABLE_ID

  open Tables_cursor
Fetch Tables_cursor INTO @tableRef, @tableID
while @@fetch_status =0
begin


print 'starting unique sorts for  table ' +@tableRef


-- first select the fields you need
Declare PROD_Fields_cursor CURSOR
For
SELECT        TBL_INTERACT_FIELDS.VIEW_FIELD_NAME, TBL_INTERACT_FIELDS.ID AS IAfieldId
FROM            TBL_INTERACT_FIELDS INNER JOIN
                         TBL_FIELD ON TBL_INTERACT_FIELDS.FIELD_ID = TBL_FIELD.ID
WHERE        (TBL_INTERACT_FIELDS.VIEW_DATA_TYPE = 'nvarchar') AND (TBL_INTERACT_FIELDS.DOC_TABLE_ID = @tableID) AND 
                      (TBL_FIELD.TBL_PROPERTY_ID IS NULL) and  (VIEW_FIELD_NAME <> N'SUBHEADING_ID')

			
ORDER BY TBL_INTERACT_FIELDS.IA_DOC_TABLE_REF
--    (TBL_INTERACT_FIELDS.SORT_FIELD_NAME IS NULL) AND
declare

@viewFieldName as nVARCHAR(500),
@IAfieldId as nVARCHAR(50),
@sortField as nVARCHAR(150),
@sortNum as int



open PROD_Fields_cursor
Fetch PROD_Fields_cursor INTO  @viewFieldName,@IAfieldId
while @@fetch_status =0

begin
BEGIN TRANSACTION
set @sortField=@viewFieldName+'_SORT'

-- check if the sort field exists, if not create it
	IF COL_LENGTH(@tableRef  ,@sortField) IS  null
	BEGIN
	set @sql='ALTER TABLE [dbo].['+@tableRef+'] ADD '+@sortField+' int';
	Execute (@sql)
	end 

		IF COL_LENGTH(@tableRef  ,'TEMP_SORT') IS  null
	BEGIN
	set @sql='ALTER TABLE [dbo].['+@tableRef+'] ADD TEMP_SORT nvarchar(MAX) ';
	Execute (@sql)
			end 
			else
			begin
	print '***** CLEARING TABLE*****'
	set @sql='Update '+@tableRef +' set TEMP_SORT=null '
		Execute (@sql)
	end
	print '***** inserting temp sort - sorting strings*****'
		set @sql='Update ' +@tableRef +' set TEMP_SORT= dbo.SortStringProduction('+@viewFieldName +') where '+ @viewFieldName +' is not null';
			
			Execute (@sql)
			commit


				  		set @sql='update  '+ @tableRef   + ' set ' +@sortField+'=99999999 where '+@viewFieldName+' IS NULL';
print @tableRef +'***** starting-' +@viewFieldName
		--	set @sql='Declare  Sort_cursor CURSOR FOR SELECT ORDERING,'+@viewFieldName+'
--	FROM '+  @tableRef  +' ORDER BY CASE WHEN  '+@viewFieldName +' IS NULL THEN 0 ELSE 1 END DESC, 
--CASE WHEN ISNUMERIC(TEMP_SORT) = 1 THEN CAST(TEMP_SORT AS FLOAT) 
       --   WHEN ISNUMERIC(LEFT(TEMP_SORT, 1)) = 1 
            -- THEN ASCII(LEFT(LOWER(TEMP_SORT), 1)) ELSE 2147483647 END  ASC
         --           , TEMP_SORT ASC'

			 	print '***** starting cursor temp sort*****'


				set @sql='Declare  Sort_cursor CURSOR FOR SELECT        TEMP_SORT, '+@viewFieldName+'
FROM      '+ @tableRef   + ' WHERE        ('+@viewFieldName+' IS NOT NULL)
GROUP BY TEMP_SORT, '+@viewFieldName+'
ORDER BY CASE WHEN '+@viewFieldName+' IS NULL THEN 0 ELSE 1 END DESC, CASE WHEN ISNUMERIC(TEMP_SORT) = 1  AND TEMP_SORT <> ''.'' THEN CAST(TEMP_SORT AS FLOAT) 
                         WHEN ISNUMERIC(LEFT(TEMP_SORT, 1)) = 1 THEN ASCII(LEFT(LOWER(TEMP_SORT), 1)) ELSE 2147483647 END, TEMP_SORT ASC'

print '***** THE QUERY IS *****'+ @sql

		exec sp_executesql @sql
		declare  @origField nvarchar(MAX),
		@addsort int,
		@tempsort as nVARCHAR(Max)

		set @sortNum =1


		open Sort_cursor
		Fetch Sort_cursor INTO @tempsort,	@origField
		while @@fetch_status =0
		begin
	
		-- set default null values to a large number
	
				set @addsort=@sortNum
				-- we want all the fields with the same value to have the same sort number
				-- or the second level sort will not work, this means there will be gaps in orderin but this will not matter
			--	set @sql='update  '+ @tableRef   + ' set ' +@sortField+'=' +Convert(char(10),@addsort) +' where TEMP_SORT=''' +replace(@origField, '''','''''')+''';'
			set @sql='update  '+ @tableRef   + ' set ' +@sortField+'=' +Convert(char(10),@addsort) +' where TEMP_SORT=''' + @tempsort+''' AND  '+@viewFieldName+'=''' +replace(@origField, '''','''''')+''';'
				Execute(@sql)
				print '***** DOING UPDATE *****'+ @sql



			set @sortNum =@sortNum+1;
	

	Fetch Sort_cursor INTO @tempsort,@origField

	END

	 deallocate Sort_cursor
	  update TBL_INTERACT_FIELDS set SORT_FIELD_NAME=@sortField where ID=@IAfieldId

	  set @sql='update  '+ @tableRef   + ' set ' +@sortField+'=99999999 where '+@viewFieldName+' IS NULL';
	  		Execute(@sql)

Fetch PROD_Fields_cursor INTO  @viewFieldName,@IAfieldId
end

deallocate PROD_Fields_cursor

--end of table loop



 		IF COL_LENGTH(@tableRef  ,'TEMP_SORT') IS not  null
	BEGIN
	set @sql='ALTER TABLE [dbo].['+@tableRef+'] DROP COLUMN TEMP_SORT';
	Execute (@sql)
			end 

Fetch Tables_cursor INTO @tableRef, @tableID
END
deallocate Tables_cursor
go

print '**** unique is complete next subheadings *****'



