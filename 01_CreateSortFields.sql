

--***********NOTE IMPORTANT must run UpdateSubstanceSorts in NB before scripts***************
-- this script takes about 45mins
-- creates the TBL_INTERACT_FIELDS if it does not exist
-- then creates sort fields for all the properties

IF ( not EXISTS  (SELECT 1 FROM sys.tables WHERE name = 'TBL_INTERACT_FIELDS'))
BEGIN

CREATE TABLE [dbo].[TBL_INTERACT_FIELDS](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ORDERING] [int] NOT NULL,
	[DOC_TABLE_ID] [int] NOT NULL,
	[IA_DOC_TABLE_REF] [nvarchar](16) NULL,
	[IS_VISIBLE] [bit] NULL,
	[COLUMN_NAME] [nvarchar](1000) NULL,
	[VIEW_FIELD_NAME] [nvarchar](150) NULL,
	[VIEW_DATA_TYPE] [nvarchar](50) NULL,
	[SORT_FIELD_NAME] [nvarchar](150) NULL,
	[SEARCH_DATA_TYPE] [nvarchar](50) NULL,
	[PLOT_FIELD] [nvarchar](150) NULL,
	[PLOTTABLE] [bit] NULL,
	[PLACES_FIELD] [nvarchar](150) NULL,
	[FIELD_ID] [int] NOT NULL,
	[ENTRY_LINK] [bit] NULL CONSTRAINT [DF_TBL_INTERACT_FIELDS_ENTRY_LINK]  DEFAULT ((0)),
	[VIEW_FIELD_WIDTH] [int] NULL,
		[SORTABLE] [bit] NULL CONSTRAINT [DF_TBL_INTERACT_FIELDS_SORTABLE]  DEFAULT ((1)),
		[SEARCHABLE] [bit] NULL CONSTRAINT [DF_TBL_INTERACT_FIELDS_SEARCHABLE]  DEFAULT ((1)),
 CONSTRAINT [PK_TBL_INTERACT_FIELDS_1] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

end
GO

Set nocount on

delete from TBL_INTERACT_FIELDS
go







-- first create the fields
Declare Sort_Prop_cursor CURSOR
For


SELECT        TABLE_NAME, SEARCH_FIELD
FROM            TBL_PROPERTY
WHERE        (TABLE_NAME <> 'TBL_SUBSTANCES') AND (TABLE_NAME <> 'TBL_CAS')   AND (TABLE_NAME <> 'TBL_SYNONYMS')     AND (SEARCH_FIELD_TYPE = 'float')


declare   @TABLE_NAME nvarchar(100), 
@SEARCH_FIELD nvarchar(100),
@SORT_FIELD nvarchar(100),
@sql nvarchar(1000),
@sqlstatement nvarchar(1000),
@sortNum int

  open Sort_Prop_cursor
Fetch Sort_Prop_cursor INTO @TABLE_NAME,@SEARCH_FIELD



while @@fetch_status =0

begin
	print  'updating sort property values '+@TABLE_NAME  + ' ' + @SEARCH_FIELD

set @SORT_FIELD=@SEARCH_FIELD +'_SORT';
--IF not EXISTS(SELECT * FROM sys.columns 
--            WHERE Name =  @SORT_FIELD AND Object_ID = Object_ID(@TABLE_NAME))

			 IF COL_LENGTH(@TABLE_NAME,@SORT_FIELD) IS  null
BEGIN
 set @sql ='ALTER TABLE [dbo].['+ @TABLE_NAME+'] ADD ' + @SORT_FIELD+  ' int;'

 Execute(@sql)

 END




 -- first set up a cursor to update the sort numbers

	set @sqlstatement='Declare  Sort_cursor CURSOR FOR SELECT ID, ' +@SEARCH_FIELD + ',dbo.SortStringProduction(TEXT) as prep,TEXT,CASE WHEN '+@SEARCH_FIELD +' IS NULL THEN 1 ELSE 0 END AS test
FROM '+  @TABLE_NAME   +'   ORDER BY test, '+@SEARCH_FIELD +',prep, TEXT'




--print  @sqlstatement

	exec sp_executesql @sqlstatement
	declare  @propValue as float
		declare  @text1 as nvarchar(1000),
@text2 as nvarchar(1000),
@test as int,
@id as int
	set @sortNum =1
	open Sort_cursor
	Fetch Sort_cursor INTO @id,@propValue,@text1,@text2,@test
	while @@fetch_status =0
	begin

	set @sql='update '+  @TABLE_NAME   + ' set ' +@SORT_FIELD +'=' +Convert(char(10),@sortNum) +' where ID='+Convert(char(10),@id)
	
--print @sql
	Execute(@sql)
	set @sortNum =@sortNum+1;
	Fetch Sort_cursor INTO @id,@propValue,@text1,@text2,@test

	END

	 deallocate Sort_cursor



	 set @sql='Update '+  @TABLE_NAME   + ' set ' +@SORT_FIELD +'=99999999  where '+@SORT_FIELD+' is null'
	 
	 	Execute(@sql)

Fetch Sort_Prop_cursor INTO @TABLE_NAME,@SEARCH_FIELD 

END

  deallocate Sort_Prop_cursor

go

print '******** starting group cursor*****'



 -- set up a cursor to update the sort numbers- we give the same values the same sort number
 -- or the the second level sorting won't work

Declare GroupSort_Prop_cursor CURSOR
For


SELECT        TABLE_NAME, SEARCH_FIELD
FROM            TBL_PROPERTY
WHERE        (TABLE_NAME <> 'TBL_SUBSTANCES') AND (TABLE_NAME <> 'TBL_CAS')  AND (TABLE_NAME <> 'TBL_SYNONYMS')   AND (SEARCH_FIELD_TYPE = 'float')


declare   @TABLE_NAME nvarchar(100), 
@SEARCH_FIELD nvarchar(100),
@SORT_FIELD nvarchar(100),
@sql nvarchar(1000),
@sqlstatement nvarchar(1000),
@sortNum int

  open GroupSort_Prop_cursor
Fetch GroupSort_Prop_cursor INTO @TABLE_NAME,@SEARCH_FIELD



while @@fetch_status =0

begin
	print  'updating group property values '+@TABLE_NAME  + ' ' + @SEARCH_FIELD

set @SORT_FIELD=@SEARCH_FIELD +'_SORT';




	set @sqlstatement='Declare  Sort_cursor CURSOR FOR SELECT Distinct ' +@SEARCH_FIELD + ',TEXT
FROM '+  @TABLE_NAME   +'   ORDER BY '+@SEARCH_FIELD 




--print  @sqlstatement

	exec sp_executesql @sqlstatement
	declare  @propValue as float
		declare  @text1 as nvarchar(1000),

@test as int,
@topSortNumber as int,
@id as int,
@query as nvarchar(1000)
	set @sortNum =1
	open Sort_cursor
	Fetch Sort_cursor INTO @propValue,@text1
	while @@fetch_status =0
	begin

			
--get the lowest sort_number for this group and apply to all
--thus making all values that are the same have the same sort number

if @propValue is null
 begin
set @query ='Select  top 1  @topSortNumber='+@SORT_FIELD +' from  '+  @TABLE_NAME   +' where '+@SEARCH_FIELD +' is null and TEXT ='''+ @text1+''''
end
else
begin
			if @text1 is null
			begin
			set @query ='Select  top 1  @topSortNumber='+@SORT_FIELD +' from  '+  @TABLE_NAME   +' where '+@SEARCH_FIELD +'='+ Convert(char(20), @propValue) +' and TEXT is null'
			end
			else
			begin
			set @query ='Select  top 1  @topSortNumber='+@SORT_FIELD +' from  '+  @TABLE_NAME   +' where '+@SEARCH_FIELD +'='+ Convert(char(20), @propValue)  +' and TEXT ='''+ @text1+''''
			end 
end 

--print @query

EXEC sp_executesql @query, 
                   N'@topSortNumber int OUTPUT', 
                  @topSortNumber=  @topSortNumber OUTPUT
if @propValue is null
 begin
set	@sql = 'Update '+  @TABLE_NAME   +' set '+@SORT_FIELD+'='+ Convert(char(10),@topSortNumber) +' where '+@SEARCH_FIELD +' is null and TEXT='''+ @text1+''''
end
else
begin
			if @text1 is null
			begin
			set	@sql = 'Update '+  @TABLE_NAME   +' set '+@SORT_FIELD+'='+ Convert(char(10),@topSortNumber)  +' where '+@SEARCH_FIELD +'='+Convert(char(20), @propValue)  +' and TEXT is null'
			end
			else
			begin

			set	@sql = 'Update '+  @TABLE_NAME   +' set '+@SORT_FIELD+'='+ Convert(char(10),@topSortNumber)  +' where '+@SEARCH_FIELD +'='+ Convert(char(20), @propValue)  +' and TEXT ='''+ @text1+''''
			end 


	
end 
--print @sql
	Execute(@sql)
	Fetch Sort_cursor INTO @propValue,@text1

	END

	 deallocate Sort_cursor



	 
	 	Execute(@sql)

Fetch GroupSort_Prop_cursor INTO @TABLE_NAME,@SEARCH_FIELD 

END

  deallocate GroupSort_Prop_cursor

go

--- ****** now do the others i.e substances and CAS ********

print 'Adding substance fields where necessary'

--IF NOT EXISTS(SELECT * FROM sys.columns 
  --          WHERE Name =  'TBL_SUBSTANCES' AND Object_ID = Object_ID('NAME_SORT_TXT'))

	 IF COL_LENGTH('TBL_SUBSTANCES','NAME_SORT_TXT') IS  null
BEGIN

execute sp_RENAME 'TBL_SUBSTANCES.NAME_SORT', 'NAME_SORT_TXT' , 'COLUMN';

 END

 go
 --IF not EXISTS(SELECT * FROM sys.columns 
 --           WHERE Name =  'TBL_SUBSTANCES' AND Object_ID = Object_ID('MF_SORT_TXT'))
 	 IF COL_LENGTH('TBL_SUBSTANCES','MF_SORT_TXT') IS  null
BEGIN
execute sp_RENAME 'TBL_SUBSTANCES.MF_SORT', 'MF_SORT_TXT' , 'COLUMN';
end
go
 --IF not EXISTS(SELECT * FROM sys.columns 
       --     WHERE Name =  'TBL_SYNONYMS' AND Object_ID = Object_ID('SYN_SORT_TXT'))
	   	 IF COL_LENGTH('TBL_SYNONYMS','SYN_SORT_TXT') IS  null
BEGIN
execute sp_RENAME 'TBL_SYNONYMS.SYN_SORT', 'SYN_SORT_TXT' , 'COLUMN';
end
go

 --IF not EXISTS(SELECT * FROM sys.columns 
       --     WHERE Name =  'TBL_SUBSTANCES' AND Object_ID = Object_ID('FORM_SORT_TXT'))
	   	 IF COL_LENGTH('TBL_SUBSTANCES','FORM_SORT_TXT') IS  null
BEGIN
execute sp_RENAME 'TBL_SUBSTANCES.FORM_SORT', 'FORM_SORT_TXT' , 'COLUMN';
end
go


--IF not EXISTS(SELECT * FROM sys.columns 
          --  WHERE Name =  'TBL_SUBSTANCES' AND Object_ID = Object_ID('NAME_SORT'))
		  	   	 IF COL_LENGTH('TBL_SUBSTANCES','NAME_SORT') IS  null
BEGIN

ALTER TABLE [dbo].[TBL_SUBSTANCES] ADD NAME_SORT int;

 END

 go
-- IF not EXISTS(SELECT * FROM sys.columns 
    --        WHERE Name =  'TBL_SUBSTANCES' AND Object_ID = Object_ID('MOLFORM_SORT'))
 IF COL_LENGTH('TBL_SUBSTANCES','MOLFORM_SORT') IS  null
BEGIN
ALTER TABLE [dbo].[TBL_SUBSTANCES] ADD MOLFORM_SORT int;
end
go
-- IF not EXISTS(SELECT * FROM sys.columns 
  --          WHERE Name =  'TBL_SYNONYMS' AND Object_ID = Object_ID('SYNONYM_SORT'))
   IF COL_LENGTH('TBL_SYNONYMS','SYNONYM_SORT') IS  null
BEGIN
ALTER TABLE [dbo].[TBL_SYNONYMS] ADD SYNONYM_SORT int;
end
go

 --IF not EXISTS(SELECT * FROM sys.columns 
    --        WHERE Name =  'TBL_SUBSTANCES' AND Object_ID = Object_ID('FORMULA_SORT'))
	   IF COL_LENGTH('TBL_SUBSTANCES','FORMULA_SORT') IS  null
BEGIN
ALTER TABLE [dbo].[TBL_SUBSTANCES] ADD FORMULA_SORT int;
end
go




print 'update substances name sort'
update TBL_SUBSTANCES set NAME_SORT_TXT=null where LEN(NAME_SORT_TXT)=0
go

Declare Sub_Name_cursor CURSOR
For
-- create  add th sorting values by sorting on the name
SELECT    distinct  NAME_SORT_TXT 
FROM            TBL_SUBSTANCES
ORDER BY NAME_SORT_TXT

declare   @value nvarchar(500), 
@sortNum int

set @sortNum=1

open Sub_Name_cursor
Fetch Sub_Name_cursor INTO @value
while @@fetch_status =0

begin

update TBL_SUBSTANCES set NAME_SORT=@sortNum where NAME_SORT_TXT=@value

set @sortNum=@sortNum+1

Fetch Sub_Name_cursor INTO @value

END

  deallocate Sub_Name_cursor

go

-- we must set null values to a high number
update TBL_SUBSTANCES set NAME_SORT=99999999 where NAME IS null;
go 


print 'update substances molform sort'
update TBL_SUBSTANCES set MF_SORT_TXT=null where LEN(MF_SORT_TXT)=0
go

Declare Sub_MF_cursor CURSOR
For


SELECT       distinct MF_SORT_TXT 
FROM            TBL_SUBSTANCES
ORDER BY  MF_SORT_TXT

declare   @value nvarchar(500), 
@sortNum int

set @sortNum=1

open Sub_MF_cursor
Fetch Sub_MF_cursor INTO @value
while @@fetch_status =0

begin

update TBL_SUBSTANCES set MOLFORM_SORT=@sortNum where MF_SORT_TXT=@value

set @sortNum=@sortNum+1

Fetch Sub_MF_cursor INTO @value

END

  deallocate Sub_MF_cursor

go

update TBL_SUBSTANCES set MOLFORM_SORT=99999999 where MOLFORM IS null;
go 


print 'update substances synonym sort'
update TBL_SYNONYMS set SYN_SORT_TXT=null where LEN(SYN_SORT_TXT)=0
go

Declare Sub_Syn_cursor CURSOR
For


SELECT     distinct SYN_SORT_TXT as value
FROM            TBL_SYNONYMS
ORDER BY  SYN_SORT_TXT

declare   @value nvarchar(500), 
@sortNum int

set @sortNum=1

open Sub_Syn_cursor
Fetch Sub_Syn_cursor INTO @value
while @@fetch_status =0

begin

update TBL_SYNONYMS set SYNONYM_SORT=@sortNum where SYN_SORT_TXT=@value

set @sortNum=@sortNum+1

Fetch Sub_Syn_cursor INTO @value

END

  deallocate Sub_Syn_cursor

go

update TBL_SYNONYMS set SYNONYM_SORT=99999999 where [SYNONYM] IS null;
go 

print 'update substances formula sort'

update TBL_SUBSTANCES set FORMULA=null where LEN(FORMULA)=0
go
Declare Sub_Form_cursor CURSOR
For


SELECT       distinct FORM_SORT_TXT 
FROM            TBL_SUBSTANCES
ORDER BY  FORM_SORT_TXT 

declare    @value1 nvarchar(500),
  @value2 nvarchar(500),
@sortNum int

set @sortNum=1

open Sub_Form_cursor
Fetch Sub_Form_cursor INTO @value1
while @@fetch_status =0

begin

update TBL_SUBSTANCES set FORMULA_SORT=@sortNum where FORM_SORT_TXT =@value1


set @sortNum=@sortNum+1

Fetch Sub_Form_cursor INTO @value1

END

  deallocate Sub_Form_cursor

go

update TBL_SUBSTANCES set FORMULA_SORT=99999999 where FORMULA IS null;
go 

print 'update MOL_WT sort'

	   	 IF COL_LENGTH('TBL_SUBSTANCES','MOLWT_SORT') IS  null
BEGIN
ALTER TABLE [dbo].[TBL_SUBSTANCES] ADD MOLWT_SORT int
end
go


Declare Sub_MOLWT_cursor CURSOR
For


SELECT       distinct MOLWT
FROM            TBL_SUBSTANCES
ORDER BY  MOLWT

declare  @value1 as float,

@sortNum int

set @sortNum=1

open Sub_MOLWT_cursor
Fetch Sub_MOLWT_cursor INTO @value1
while @@fetch_status =0

begin

update TBL_SUBSTANCES set MOLWT_SORT=@sortNum where MOLWT =@value1;


set @sortNum=@sortNum+1

Fetch Sub_MOLWT_cursor INTO @value1

END

  deallocate Sub_MOLWT_cursor

go

update TBL_SUBSTANCES set MOLWT_SORT=99999999 where MOLWT IS null;
go 



 IF COL_LENGTH('TBL_DOC_TABLE_SUBHEADING','SUBHEADING_SORT') IS  null
BEGIN
ALTER TABLE [dbo].[TBL_DOC_TABLE_SUBHEADING] ADD SUBHEADING_SORT int;
end
go
print ' *** starting subheadings *******'
Declare Subheadings_cursor CURSOR
For
SELECT DISTINCT dbo.SortStringProduction(SUBHEADING) AS value,SUBHEADING
FROM           TBL_DOC_TABLE_SUBHEADING
ORDER BY value

declare    @value nvarchar(500),
@value2 nvarchar(500),
@sortNum int

set @sortNum=1

open Subheadings_cursor
Fetch Subheadings_cursor INTO @value,@value2
while @@fetch_status =0

begin

update TBL_DOC_TABLE_SUBHEADING set SUBHEADING_SORT=@sortNum where SUBHEADING=@value2

set @sortNum=@sortNum+1

Fetch Subheadings_cursor INTO  @value,@value2

END

  deallocate Subheadings_cursor

  update TBL_DOC_TABLE_SUBHEADING set SUBHEADING_SORT=99999999 where SUBHEADING IS null;
go



print ' *** create new overlay table  *******'



IF ( not EXISTS  (SELECT 1 FROM sys.tables WHERE name = 'TBL_IA_FOOTNOTE_OVERLAY'))
BEGIN

CREATE TABLE [dbo].[TBL_IA_FOOTNOTE_OVERLAY](
	[DOC_TABLE_ID] [int] NULL,
	[COLUMN_ORDER_NUM] [int] NULL,
	[ROW_ORDER_NUM] [int] NULL,
	[TAG] [nvarchar](50) NULL
) ON [PRIMARY]

end
GO

print '****** complete *******'
