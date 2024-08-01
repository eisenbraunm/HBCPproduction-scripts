

-- first clear old values in TBL_INTERACT_FIELDS
-- then populate the tabe.
--takes about 2 mins
delete from TBL_INTERACT_FIELDS
go



-- this script populates the property fields in the interactive tabe
declare  @tableRef nvarchar(50),
@tableID int,
@sql nvarchar(2000),
@HasCRC bit,
@temp nvarchar(1000),
@sortNum int,
@oldtableRef nvarchar(50)
SET NOCOUNT ON



--start the table loop i.e. all table that are not deleted


Declare Tables_cursor CURSOR
For

SELECT        TBL_DOC_TABLE.ID
FROM            TBL_DOC_TABLE INNER JOIN
                         TBL_DOC_CONTENTS ON TBL_DOC_TABLE.ID = TBL_DOC_CONTENTS.DOC_TABLE_ID INNER JOIN
                         TBL_DOC_CONTENT ON TBL_DOC_CONTENTS.DOC_CONTENT_ID = TBL_DOC_CONTENT.ID
WHERE         (TBL_DOC_CONTENT.FOR_WEB = 1) 
ORDER BY TBL_DOC_TABLE.DOCUMENT_TABLE_REF
  open Tables_cursor
Fetch Tables_cursor INTO @tableID
while @@fetch_status =0
begin

set @tableRef=(Select DOCUMENT_TABLE_REF from TBL_DOC_TABLE where ID=@tableID)
set @tableRef='INT_'+@tableRef;

print 'starting table ' +@tableRef

Declare PROD_Fields_cursor CURSOR
For
SELECT  TBL_FIELD.ID,      TBL_FIELD.FIELD_NAME,  TBL_PROPERTY.SEARCH_FIELD_TYPE, TBL_FIELD.DATA_TYPE, 
                         TBL_FIELD.TBL_PROPERTY_ID,TBL_FIELD.COLUMN_NAME
FROM            TBL_FIELD LEFT OUTER JOIN
                         TBL_PROPERTY ON TBL_FIELD.TBL_PROPERTY_ID = TBL_PROPERTY.ID
WHERE        (TBL_FIELD.DOC_TABLE_ID = @tableID) AND (TBL_FIELD.DELETED = 0) AND (TBL_PROPERTY.IS_SORT = 0 OR
                         TBL_PROPERTY.IS_SORT IS NULL) AND (TBL_FIELD.FOR_WEB = 1) AND (TBL_FIELD.FIELD_NAME <> 'ID') OR
                         (TBL_FIELD.DOC_TABLE_ID = @tableID) AND (TBL_FIELD.DELETED = 0) AND (TBL_PROPERTY.IS_SORT = 0 OR
                         TBL_PROPERTY.IS_SORT IS NULL) AND (TBL_FIELD.FIELD_NAME = 'CRCNUM') AND (TBL_FIELD.FIELD_NAME <> 'ID')
ORDER BY TBL_FIELD.ORDERING


declare
@fieldId int,
@viewFieldName as VARCHAR(500),
@propDataType as nvarchar(100),
@fieldDataType as nvarchar(100),
@PROPERTYtableId as int,
@COLUMN_NAME as nvarchar(1000),
@ordering as int,
@isVisible as bit,
@viewDataType as nvarchar(50),
@searchDataType as nvarchar(50),
@plotField as  nvarchar(150),
@plottable as bit,
@PlacesField as  nvarchar(150),
@EntryLink as bit,
@sortable as bit,
@searchable as bit,
@SortField as  nvarchar(150)
set @isvisible=1


set @ordering=0


set @EntryLink =0
set @sortable =1
set @searchable =1


open PROD_Fields_cursor
Fetch PROD_Fields_cursor INTO @fieldId,@viewFieldName,@propDataType,@fieldDataType,@PROPERTYtableId,@COLUMN_NAME
while @@fetch_status =0

begin
 
set @isvisible=1

if @propDataType is not null
begin
set @searchDataType=@propDataType
end


if @fieldDataType is not null
begin

set @searchDataType=@fieldDataType
end

	IF @viewFieldName= 'SUBHEADING_ID'
	BEGIN
	set @searchDataType='nvarchar'
	END


set @plottable=0
set @EntryLink =0
set @sortable =1
set @searchable =1
set @PlacesField=null;
set @SortField =null;
set @plotField=null;
	IF COL_LENGTH(@tableRef  ,@viewFieldName) IS  null
	BEGIN
print '**** ERROR***' + @tableRef  + ' ' + @viewFieldName +' is missing'
	end 

		 if @searchDataType='float'
		 begin
		 set @plottable=1
		 set @PlacesField= @viewFieldName+ '_PLACES'
		 		IF COL_LENGTH(@tableRef  , @PlacesField) IS  null
				BEGIN
				print '**** ERROR***' + @tableRef  + ' ' +  @PlacesField +' is missing'
				end 

				if  @viewFieldName='MOLWT'
				begin
				set @plotField= 'MOLWT_PLOT'
		 end
		 else
		 begin

		  		IF COL_LENGTH(@tableRef  ,@plotField) IS  null
				BEGIN
				print '**** ERROR***' + @tableRef + ' ' +  @plotField +' is missing'
				end 
			end
		 end 

 if @searchDataType='float'
		 begin
			set @plottable=1
			set @PlacesField= @viewFieldName+ '_PLACES'
		 		IF COL_LENGTH(@tableRef  , @PlacesField) IS  null
				BEGIN
				print '**** ERROR***' + @tableRef  + ' ' +  @PlacesField +' is missing'
				end 
			set @plotField= @viewFieldName+ '_PLOT'
		  		IF COL_LENGTH(@tableRef  , @PlacesField) IS  null
				BEGIN
				print '**** ERROR***' + @tableRef + ' ' +  @plotField +' is missing'
				end 
			-- note the sort field is taken from the property tables where the text value is accounted for 
			-- as well as the value
		 end 



		 if @searchDataType='int'
		 begin
			if @viewFieldName <> 'CAS_LONG' and @viewFieldName <> 'STRUCID' and  @viewFieldName not like'REF%' and @viewFieldName not like'CRCNUM'
			begin
			set @plottable=1

			end

			IF @viewFieldName = 'STRUCID'
			begin
			set @sortable=0
			set @searchable=0
			enD

			IF @viewFieldName = 'ORDERING'
			begin
			set @plotField= @viewFieldName;
			set @SortField=@viewFieldName;
			set  @COLUMN_NAME ='Row';
	
			end
			
			IF @viewFieldName = 'CRCNUM' 
			begin
			set @plotField= @viewFieldName;
			set @SortField=@viewFieldName;
			set @isvisible=0
			end

			IF @viewFieldName = 'CAS_LONG' 
			begin
			set @SortField=@viewFieldName;
		
			end

						IF @viewFieldName = 'CAS_LONG' 
			begin
			set @SortField=@viewFieldName;
		
			end



		IF   @viewFieldName <> 'STRUCID' and @viewFieldName <> 'ORDERING' and @viewFieldName <> 'CRCNUM' and  @viewFieldName <> 'CAS_LONG'
			begin

			 set @plotField= @viewFieldName+ '_PLOT'
		  	IF COL_LENGTH(@tableRef , @plotField) IS  null
				BEGIN
				print '**** ERROR***' + @tableRef + ' ' +  @plotField +' is missing !!!'
			end 
			set @SortField=@viewFieldName;
		 end 


end


if @viewFieldName='NAME' and @PROPERTYtableId is not null
begin
set @EntryLink=1;
end



set @viewDataType=(SELECT DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS
WHERE 
     TABLE_NAME = @tableRef AND 
     COLUMN_NAME = @viewFieldName)



insert into TBL_INTERACT_FIELDS
(ORDERING, DOC_TABLE_ID, IA_DOC_TABLE_REF, IS_VISIBLE, COLUMN_NAME, VIEW_FIELD_NAME, VIEW_DATA_TYPE, SORT_FIELD_NAME, 
                         SEARCH_DATA_TYPE, PLOT_FIELD, PLOTTABLE, PLACES_FIELD, FIELD_ID, ENTRY_LINK, SORTABLE, SEARCHABLE )
VALUES
(@ordering, @tableID, @tableRef, @isvisible, @COLUMN_NAME, @viewFieldName, @viewDataType, @SortField, 
                         @searchDataType, @plotField, @plottable, @PlacesField, @fieldId, @EntryLink,  @sortable, @searchable )
--print Convert(char(10), @@Identity ) +' = identity'' ++++ entering ' +@tableRef + ' ' + @viewFieldName
set @ordering=@ordering+1
Fetch PROD_Fields_cursor INTO @fieldId,@viewFieldName,@propDataType,@fieldDataType,@PROPERTYtableId,@COLUMN_NAME
end

deallocate PROD_Fields_cursor

--end of table loop

Fetch Tables_cursor INTO @tableID
END
deallocate Tables_cursor

go
print '**** complete *****'


