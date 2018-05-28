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

if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2insurance' and SEQUENCE_NAME=N'SQ_VehicleMakes')
	create sequence a2insurance.SQ_VehicleMakes as bigint start with 1 increment by 1;
go
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'VehicleMakes')
begin
	create table a2insurance.VehicleMakes
	(
		Id bigint not null
			constraint PK_VehicleMakes primary key clustered
			constraint DF_VehicleMakes_PK default (next value for a2insurance.SQ_VehicleMakes),
		[Name] nvarchar (255)
	);
end
go
if not exists(select * from INFORMATION_SCHEMA.SEQUENCES where SEQUENCE_SCHEMA=N'a2insurance' and SEQUENCE_NAME=N'SQ_VehicleModels')
	create sequence a2insurance.SQ_VehicleModels as bigint start with 1 increment by 1;
go
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'VehicleModels')
begin
	create table a2insurance.VehicleModels
	(
		Id bigint not null
			constraint PK_VehicleModels primary key clustered
			constraint DF_VehicleModels_PK default (next value for a2insurance.SQ_VehicleModels),
		MakeId bigint not null
			constraint FK_VehicleModels_MakeId foreign key references a2insurance.VehicleMakes (Id),
		[Name] nvarchar (255)
	);
end
go
if (not exists (select * from sys.indexes where name=N'UQ_VehicleModels_MakeId_Id'))
	create unique index UQ_VehicleModels_MakeId_Id on a2insurance.VehicleModels (MakeId, Id);
go

if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'ContractsVehicles')
begin
	create table a2insurance.ContractsVehicles
	(
		ContractId bigint not null
			constraint FK_ContractsVehicles_ContractId references a2insurance.Contracts (Id) on delete cascade,
		[Index] int not null,
		constraint PK_ContractsVehicles primary key clustered (ContractId, [Index]),
		VIN nvarchar(36),
		LicensePlate nvarchar(16),
		MakeId bigint null
			constraint FK_ContractsVehicles_MakeId foreign key references a2insurance.VehicleMakes (Id)
		,
		MakeName nvarchar(255),
		ModelId bigint
			--constraint FK_ContractsVehicles_ModelId foreign key references a2insurance.VehicleModels (Id)
		,
		constraint FK_ContractsVehicles_MakeId_ModelId foreign key (MakeId, ModelId) references a2insurance.VehicleModels (MakeId, Id),
		ModelName nvarchar(255),
		ModelSuffix nvarchar(255),
		ProductionYear int,
		EngineDisplacement int,
		Color nvarchar(255),
		RegistrationRegion bigint,
		RegistrationDistrict bigint,
		RegistrationCity bigint,
		RegistrationZone bigint
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
	@Product nvarchar(16) = null,
	@Offset int = 0,
	@PageSize int = 20,
	@Order nvarchar(255) = N'Id',
	@Dir nvarchar(20) = N'desc'
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	declare @Asc nvarchar(10), @Desc nvarchar(10), @RowCount int;
	set @Asc = N'asc'; set @Desc = N'desc';
	set @Dir = isnull(@Dir, @Asc);

	-- list of users
	with T as(
		select ct.Id, RN = row_number() over (
			 order by
				case when @Order=N'Id' and @Dir = @Asc then ct.Id end asc,
				case when @Order=N'Id' and @Dir = @Desc  then ct.Id end desc,
				case when @Order=N'Date' and @Dir = @Asc then ct.[Date] end asc,
				case when @Order=N'Date' and @Dir = @Desc  then ct.[Date] end desc,
				case when @Order=N'No' and @Dir = @Asc then ct.[No] end asc,
				case when @Order=N'No' and @Dir = @Desc then ct.[No] end desc
			)
		from a2insurance.Contracts ct
		where @Product is null or ct.ProductKey=@Product
	)
	select [Contracts!TContract!Array]=null, [!!RowCount] = (select count(1) from T),
		[Id!!Id]=ct.Id, ct.[No],
		ProductName=p.[Name]
	from T
	inner join a2insurance.Contracts ct on ct.Id=T.Id
	inner join a2insurance.Products p on p.[Key]=ct.ProductKey
	where T.RN between @Offset+1 and @Offset+@PageSize;

	select [Products!TProduct!Array]=null,
		[Key!!Id]=p.[Key], p.[Name]
	from a2insurance.Products p
	order by p.[Name]

	select [!$System!] = null, 
		[!Contracts!PageSize] = @PageSize,
		[!Contracts!SortOrder] = @Order, 
		[!Contracts!SortDir] = @Dir,
		[!Contracts!Offset] = @Offset;
end
go