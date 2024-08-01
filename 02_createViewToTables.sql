
/****** Object:  StoredProcedure [dbo].[createTableViewFormatted]    Script Date: 09/11/2015 09:11:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
-- this script creates the INT table and adds the fields to the TBL_INTERACT_FIELDS table
-- note it can be run multiple times as the table is initially dropped

-- have found sometime that the CRCNUM has been set to off
--takes about 5 of mins
SET NOCOUNT ON
update TBL_FIELD  set TBL_FIELD.FOR_WEB = 1 where FIELD_NAME ='CRCNUM'
go
update TBL_FIELD  set TBL_FIELD.FOR_WEB = 1 where FIELD_NAME ='ORDERING'
go


update TBL_FIELD  set TBL_FIELD.FOR_WEB = 1 where FIELD_NAME ='ORDERING'
go

-- there are two table where the Strucutures are large images and do not look good in the interactive table
-- we set these to web=false so they are not picked up in the interactive tables, (but documents are already implimented so this does not effect them)
--table 07_14_01
update TBL_FIELD  set TBL_FIELD.FOR_WEB = 0 where FIELD_NAME ='STRUCTURE' and DOC_TABLE_ID=421
go

--table 06_60_02
update TBL_FIELD  set TBL_FIELD.FOR_WEB = 0 where FIELD_NAME ='STRUCTURE' and DOC_TABLE_ID=727
go



-- if Cas only has importance 2 move it to 1, or the links do now work correctly for the views

declare  
@crcnum int


Declare CAS_cursor CURSOR
For
SELECT      CRCNUM
FROM            TBL_CAS AS C
WHERE        (ORDERING = 2) AND (NOT EXISTS
                             (SELECT        ID, CRCNUM, OLD_CAS, ORDERING, NOTES, DATECHANGE, COMPOSITE_ID, DATECREATED, CAS_LONG
                               FROM            TBL_CAS AS TBL_CAS_1
                               WHERE        (CRCNUM = C.CRCNUM) AND (ORDERING = 1)))



ORDER BY CRCNUM

  open CAS_cursor
Fetch CAS_cursor INTO @crcnum
while @@fetch_status =0
begin



Update TBL_CAS set ORDERING=1 where CRCNUM=@crcnum;
print 'changing CAS importance on crcnum' + convert(char(10),@crcnum);


Fetch CAS_cursor INTO @crcnum
END
deallocate CAS_cursor
go

--*******************************************************************************
declare  @tableRef nvarchar(50),
@tableID int,
@createTable nvarchar(1000),
@dropTable nvarchar(1000)



-- drop all the old views
Declare Tables_cursor CURSOR
For
SELECT        name
FROM            sys.views
WHERE        (name LIKE 'VE_%') OR
                         (name LIKE 'VF_%') OR
                         (name LIKE 'VR_%') 

  open Tables_cursor
Fetch Tables_cursor INTO @dropTable
while @@fetch_status =0
begin



set @dropTable='DROP VIEW [dbo].['+@dropTable+']'


execute ( @dropTable)

Fetch Tables_cursor INTO @dropTable
END
deallocate Tables_cursor
go


print '**** start creating the new production views '

declare  @tableRef nvarchar(50),
@tableID int,
@createTable nvarchar(1000),
@dropTable nvarchar(1000),
@sql nvarchar(1000)



--start the table loop i.e. all tables are dropped an recreated
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


set @tableRef=(Select DOCUMENT_TABLE_REF from TBL_DOC_TABLE where ID=@tableID)

print 'dbo.createTableViewPROD' + convert(char(10),@tableID) + ' ' +@tableRef ;
EXEC  dbo.createTableViewPROD @tableId;


Fetch Tables_cursor INTO @tableID
END
deallocate Tables_cursor
go

print 'create the tables and populate them from the veiws'
declare  @tableRef nvarchar(50),
@tableID int,
@createTable nvarchar(1000),
@dropTable nvarchar(1000),
@sql nvarchar(1000)



--start the table loop i.e. all tables are dropped an recreated
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
print 'doing table'+@tableRef

	IF (EXISTS (SELECT 1 FROM sys.tables WHERE name like 'INT_'+@tableRef))
	begin 
	set @dropTable='DROP TABLE [dbo].[INT_'+@tableRef+']'
	execute (@dropTable)

	end



set @sql='SELECT * INTO INT_'+@tableRef+'  FROM dbo.VPROD_' + @tableRef +';'
--print @sql;

Execute (@sql)

-- make orderings not null

set @sql='ALTER TABLE [INT_'+@tableRef+'] ALTER COLUMN [ORDERING] INTEGER NOT NULL';
Execute (@sql);

-- now make it the primary key

IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
WHERE CONSTRAINT_TYPE = 'PRIMARY KEY' AND TABLE_NAME = 'INT_'+@tableRef
AND TABLE_SCHEMA ='dbo')
BEGIN
   set @sql='ALTER TABLE [dbo].[INT_'+ @tableRef  +'] ADD  CONSTRAINT [PK_INT_'+@tableRef+'] PRIMARY KEY CLUSTERED 
(
	[ORDERING] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]';
--print @sql;
Execute (@sql);
END



Fetch Tables_cursor INTO @tableID
END
deallocate Tables_cursor
go
print '**** complete *****'

