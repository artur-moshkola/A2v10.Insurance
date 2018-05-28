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


if not exists (select 1 from a2insurance.Products where [Key]=N'OSAGO')
	insert into a2insurance.Products ([Key], [Name])
	values (N'OSAGO', N'ОСЦПВ');
go

if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'ContractsOSAGO')
begin
	create table a2insurance.ContractsOSAGO
	(
		ContractId bigint not null
			constraint PK_ContractsOSAGO primary key clustered
			constraint FK_ContractsOSAGO_ContractId foreign key references a2insurance.Contracts (Id) on delete cascade,
		BlankSeries nchar(2), BlankNo int, StikerSeries nchar(2), StikerNo int, StickerMatches bit,
		TariffTable nvarchar(16),
		Duration int,
		DatePay datetime,
		Exemption nvarchar(16),
		IsUnexperienced bit,
		IsFroad bit,
		InsurantDocKind nvarchar(16),
		InsurantDocSer nvarchar(32),
		InsurantDocNo nvarchar(32),
		InsurantDocDate date,
		InsurantDocIssuer nvarchar(255),
		Usage bigint,
		IsCommercePass bit,
		IsInspectionRequired bit,
		NextInspectionDate date,
		MonthsUnusedMask int,
		MonthsUnusedQTY int,
		PremiumCalc money,
		PremiumHand money,
		isPremiumHand bit,
		BonusMalus nvarchar(2),
		Discount int,
		BM float, K1 float, K2 float, K3 float, K4 float, K5 float, K6 float, K7 float, D1 float, D2 float
	);
end
go
