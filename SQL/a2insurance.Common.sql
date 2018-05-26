------------------------------------------------
set noexec off;
go
------------------------------------------------
if DB_NAME() = N'master'
begin
	declare @err nvarchar(255);
	set @err = N'Error! Can not use the master database!';
	print @err;
	raiserror (@err, 16, -1) with nowait;
	set noexec on;
end
go
------------------------------------------------
set nocount on;

if not exists(select * from INFORMATION_SCHEMA.SCHEMATA where SCHEMA_NAME=N'a2insurance')
begin
	exec sp_executesql N'create schema a2insurance';
end
go

--- ui

------------------------------------------------
begin
	-- App Title/SubTitle
	if not exists (select * from a2sys.SysParams where [Name] = N'AppTitle')
		insert into a2sys.SysParams([Name], StringValue) values (N'AppTitle', N'A2:Insurance'); 
	if not exists (select * from a2sys.SysParams where [Name] = N'AppSubTitle')
		insert into a2sys.SysParams([Name], StringValue) values (N'AppSubTitle', N'демонстрационное приложение'); 
end
go
------------------------------------------------
begin
	-- create user menu
	declare @menu table(id bigint, p0 bigint, [name] nvarchar(255), [url] nvarchar(255), icon nvarchar(255), [order] int, help nvarchar(255));
	insert into @menu(id, p0, [name], [url], icon, [order], [help])
	values
		( 1, null,  N'Default',     null,             null,   0,  null),
		( 5,    1,  N'Панель',      N'dashboard',     null,   5,  null),
		(10,    1,  N'Договоры',    N'contracts',     null,  10,  null)
	merge a2ui.Menu as target
	using @menu as source
	on target.Id=source.id and target.Id between 1 and 199
	when matched then
		update set
			target.Id = source.id,
			target.[Name] = source.[name],
			target.[Url] = source.[url],
			target.[Icon] = source.icon,
			target.[Order] = source.[order],
			target.Help = source.help
	when not matched by target then
		insert(Id, Parent, [Name], [Url], Icon, [Order], Help) values (id, p0, [name], [url], icon, [order], help)
	when not matched by source and target.Id between 1 and 199 then 
		delete;

	if not exists (select * from a2security.Acl where [Object] = 'std:menu' and [ObjectId] = 1 and GroupId = 1)
	begin
		insert into a2security.Acl ([Object], ObjectId, GroupId, CanView)
			values (N'std:menu', 1, 1, 1);
	end
	exec a2security.[Permission.UpdateAcl.Menu];
end
go

--------------
--- TABLES ---
--------------

if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2insurance' and SEQUENCE_NAME=N'SQ_Products')
	create sequence a2insurance.SQ_Products as bigint start with 1 increment by 1;
go
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'Products')
begin
	create table a2insurance.Products
	(
		Id bigint not null
			constraint PK_Products primary key clustered
			constraint DF_Products_PK default (next value for a2insurance.SQ_Products),
		[Key] nvarchar(16) collate Latin1_General_100_CI_AS not null,
		[Name] nvarchar(255) null
	);
	create unique index UQ_Products_Key on a2insurance.Products ([Key]);
end
go

if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2insurance' and SEQUENCE_NAME=N'SQ_Contracts')
	create sequence a2insurance.SQ_Contracts as bigint start with 1 increment by 1;
go
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'Contracts')
begin
	create table a2insurance.Contracts
	(
		Id bigint not null
			constraint PK_Contracts primary key clustered
			constraint DF_Contracts_PK default (next value for a2insurance.SQ_Contracts),
		IsVoid bit not null
			constraint DF_Contracts_IsVoid default (0),
		OwnerId bigint not null
			constraint FK_Contracts_OwnerId foreign key references a2security.Users (Id),
		ProductKey nvarchar(16) collate Latin1_General_100_CI_AS not null
			constraint FK_Contracts_ProductKey foreign key references a2insurance.Products ([Key]),
		[State] nvarchar(16) collate Latin1_General_100_CI_AS not null,
		[No] nvarchar(16) collate Latin1_General_100_CI_AS not null,
		[Date] datetime null,
		[DateFrom] datetime null,
		[DateTo] datetime null,
		Premium money null,
		SumCover money null,
		Tariff float null,
		Deductible money null,
		CompanyDelegatePerson nvarchar(255) null,
		CompanyDelegateGrounds nvarchar(255) null,
		CompanyBankAccount nvarchar(32) null,
		CompanyBankName nvarchar(255) null,
		CompanyBankMFO nvarchar(16) null,
		InsurantType nchar(1) collate Latin1_General_100_CI_AS null,
		InsurantPersTaxNo nvarchar(16) null,
		InsurantPersBirthday date null,
		InsurantPersGivenName nvarchar(255) null,
		InsurantPersFamilyName nvarchar(255) null,
		InsurantPersPatroName nvarchar(255) null,
		InsurantPersPassportSer nvarchar(32) null,
		InsurantPersPassportNo nvarchar(32) null,
		InsurantPersPassportDate date null,
		InsurantPersPassportIssuer nvarchar(255) null,
		InsurantFirmRegNo nvarchar(16) null,
		InsurantFirmName nvarchar(2048) null,
		InsurantFirmBankAccount nvarchar(32) null,
		InsurantFirmBankName nvarchar(255) null,
		InsurantFirmBankMFO nvarchar(16) null,
		InsurantFirmDelegatePerson nvarchar(255) null,
		InsurantFirmDelegateGrounds nvarchar(255) null,
		InsurantAddress nvarchar(255) null,
		InsurantPhone nvarchar(64) null,
		InsurantEmail nvarchar(255) null,
		BeneficiaryTheSame bit null,
		BeneficiaryType nchar(1) collate Latin1_General_100_CI_AS null,
		BeneficiaryPersTaxNo nvarchar(16) null,
		BeneficiaryPersBirthday date null,
		BeneficiaryPersGivenName nvarchar(255) null,
		BeneficiaryPersFamilyName nvarchar(255) null,
		BeneficiaryPersPatroName nvarchar(255) null,
		BeneficiaryPersPassportSer nvarchar(32) null,
		BeneficiaryPersPassportNo nvarchar(32) null,
		BeneficiaryPersPassportDate date null,
		BeneficiaryPersPassportIssuer nvarchar(255) null,
		BeneficiaryFirmRegNo nvarchar(16) null,
		BeneficiaryFirmName nvarchar(2048) null,
		BeneficiaryFirmBankAccount nvarchar(32) null,
		BeneficiaryFirmBankName nvarchar(255) null,
		BeneficiaryFirmBankMFO nvarchar(16) null,
		BeneficiaryFirmDelegatePerson nvarchar(255) null,
		BeneficiaryFirmDelegateGrounds nvarchar(255) null,
		BeneficiaryAddress nvarchar(255) null,
		BeneficiaryPhone nvarchar(64) null,
		BeneficiaryEmail nvarchar(255) null
	);
end
go

if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'ContractsVehicles')
begin
	create table a2insurance.ContractsVehicles
	(
		ContractId bigint not null
			constraint FK_ContractsVehicles_ContractId references a2insurance.Contracts (Id),
		[Index] int not null,
		constraint PK_ContractsVehicles primary key clustered (ContractId, [Index])
	);
end
go


--------------
--- MODELS ---
--------------


---[ Contract ]---

if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2insurance' and ROUTINE_NAME=N'Contract.Index')
	drop procedure a2insurance.[Contract.Index]
go
------------------------------------------------
create procedure a2insurance.[Contract.Index]
	@UserId bigint,
	@Kind nvarchar(255),
	@Offset int = 0,
	@PageSize int = 20,
	@Order nvarchar(255) = N'Id',
	@Dir nvarchar(20) = N'desc',
	@Agent bigint = null,
	@GroupBy nvarchar(255) = N''
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;
	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = isnull(@Dir, @Asc);

	-- list of users
	with T([Id!!Id], [Date], [No], [Sum], Memo, 
		[Agent.Id!TAgent!Id], [Agent.Name!TAgent!Name], 
		[DepFrom.Id!TAgent!Id],  [DepFrom.Name!TAgent!Name],
		[DepTo.Id!TAgent!Id],  [DepTo.Name!TAgent!Name], Done,
		DateCreated, DateModified, [ParentDoc!TDocParent!RefId],
		[!!RowNumber])
	as(
		select d.Id, d.[Date], d.[No], d.[Sum], d.Memo, 
			d.Agent, a.[Name], d.DepFrom, f.[Name], d.DepTo, t.[Name], d.Done,
			d.DateCreated, d.DateModified, d.Parent,
			[!!RowNumber] = row_number() over (
			 order by
				case when @Order=N'Id' and @Dir = @Asc then d.Id end asc,
				case when @Order=N'Id' and @Dir = @Desc  then d.Id end desc,
				case when @Order=N'Date' and @Dir = @Asc then d.[Date] end asc,
				case when @Order=N'Date' and @Dir = @Desc  then d.[Date] end desc,
				case when @Order=N'No' and @Dir = @Asc then d.[No] end asc,
				case when @Order=N'No' and @Dir = @Desc then d.[No] end desc,
				case when @Order=N'Sum' and @Dir = @Asc then d.[Sum] end asc,
				case when @Order=N'Sum' and @Dir = @Desc then d.[Sum] end desc,
				case when @Order=N'Memo' and @Dir = @Asc then d.Memo end asc,
				case when @Order=N'Memo' and @Dir = @Desc then d.Memo end desc,
				case when @Order=N'Agent.Name' and @Dir = @Asc then a.[Name] end asc,
				case when @Order=N'Agent.Name' and @Dir = @Desc then a.[Name] end desc
			)
		from a2demo.Documents d
			left join a2demo.Agents a on d.Agent = a.Id
			left join a2demo.Agents f on d.DepFrom = f.Id
			left join a2demo.Agents t on d.DepTo = t.Id
		where d.Kind=@Kind and (@Agent is null or d.Agent = @Agent)
	)
	select [Documents!TDocument!Array]=null, *, [Links!TDocLink!Array] = null, 
		[!!RowCount] = (select count(1) from T)
	into #tmp
	from T
		where [!!RowNumber] > @Offset and [!!RowNumber] <= @Offset + @PageSize

	select * from #tmp
	order by [!!RowNumber];

	select [!TDocLink!Array] = null, [Id!!Id] = Id, [!TDocument.Links!ParentId] = Parent, Kind, [Date], [No], [Sum]
	from a2demo.Documents where Parent in (select [Id!!Id] from #tmp)

	select [!TDocParent!Map] = null, [Id!!Id] = Id, Kind, [Date], [No], [Sum]
	from a2demo.Documents where Id in (select [ParentDoc!TDocParent!RefId] from #tmp);

	select [!$System!] = null, 
		[!Documents!PageSize] = @PageSize, 
		[!Documents!SortOrder] = @Order, 
		[!Documents!SortDir] = @Dir,
		[!Documents!Offset] = @Offset,
		[!Documents!GroupBy] = @GroupBy,
		[!Documents.Agent.Id!Filter] = @Agent,
		[!Documents.Agent.Name!Filter] = (select [Name] from a2demo.Agents where Id=@Agent);
end
go