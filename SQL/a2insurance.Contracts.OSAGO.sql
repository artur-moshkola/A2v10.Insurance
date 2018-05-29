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



if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'OSAGO_BlanksSeries')
begin
	create table a2insurance.OSAGO_BlanksSeries
	(
		[Key] nchar(2) collate Latin1_General_100_CS_AS not null
			constraint PK_OSAGO_BlanksSeries primary key,
		IsVoid bit not null
			constraint DF_OSAGO_BlanksSeries_IsVoid default (0)
	);
end
go

merge into a2insurance.OSAGO_BlanksSeries t
using (
	select ss.[Key]
	from (values
		(N'AB'),(N'AC'),(N'AE'),(N'AI'),(N'AK'),(N'AM')
	) ss ([Key])
) s on s.[Key]=t.[Key]
when not matched by target then insert ([Key]) values (s.[Key])
when matched then update set IsVoid=0
when not matched by source then update set IsVoid=1;

-- drop table a2insurance.ContractsOSAGO
if not exists(select * from INFORMATION_SCHEMA.TABLES where TABLE_SCHEMA=N'a2insurance' and TABLE_NAME=N'ContractsOSAGO')
begin
	create table a2insurance.ContractsOSAGO
	(
		ContractId bigint not null
			constraint PK_ContractsOSAGO primary key clustered
			constraint FK_ContractsOSAGO_ContractId foreign key references a2insurance.Contracts (Id) on delete cascade,
		MediaType nvarchar(16) collate Latin1_General_100_CS_AS,
		BlankSeries nchar(2) collate Latin1_General_100_CS_AS null
			constraint FK_ContractsOSAGO_BlankSeries foreign key references a2insurance.OSAGO_BlanksSeries ([Key]),
		BlankNo int,
		StickerSeries nchar(2) collate Latin1_General_100_CS_AS null
			constraint FK_ContractsOSAGO_StickerSeries foreign key references a2insurance.OSAGO_BlanksSeries ([Key]),
		StickerNo int,
		StickerMatches bit,
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






if exists (select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_SCHEMA=N'a2insurance' and ROUTINE_NAME=N'Contract.OSAGO.Load')
	drop procedure a2insurance.[Contract.OSAGO.Load]
go
------------------------------------------------
create procedure a2insurance.[Contract.OSAGO.Load]
	@UserId bigint,
	@Id bigint = null
as
begin
	set nocount on;
	set transaction isolation level read uncommitted;

	select [Contract!TContract!Object]=null,
		[Id!!Id]=ct.Id, ct.[No], ct.[Date],
		ct.[State],
		-- exec a2temp.fetch_colums N'alias', N'ct', N'a2insurance', N'Contracts', 100, @Exclude=N'Id,No,Date,State,IsVoid,OwnerId,ProductKey';
		ct.DateFrom, ct.DateTo, ct.Premium, ct.SumCover, ct.Tariff, ct.Deductible, ct.CompanyDelegatePerson, 
		ct.CompanyDelegateGrounds, ct.CompanyBankAccount, ct.CompanyBankName, ct.CompanyBankMFO, ct.InsurantType, 
		ct.InsurantPersTaxNo, ct.InsurantPersBirthday, ct.InsurantPersGivenName, ct.InsurantPersFamilyName, 
		ct.InsurantPersPatroName, ct.InsurantPersPassportSer, ct.InsurantPersPassportNo, 
		ct.InsurantPersPassportDate, ct.InsurantPersPassportIssuer, ct.InsurantFirmRegNo, ct.InsurantFirmName, 
		ct.InsurantFirmBankAccount, ct.InsurantFirmBankName, ct.InsurantFirmBankMFO, 
		ct.InsurantFirmDelegatePerson, ct.InsurantFirmDelegateGrounds, ct.InsurantAddress, ct.InsurantPhone, 
		ct.InsurantEmail, ct.BeneficiaryTheSame, ct.BeneficiaryType, ct.BeneficiaryPersTaxNo, 
		ct.BeneficiaryPersBirthday, ct.BeneficiaryPersGivenName, ct.BeneficiaryPersFamilyName, 
		ct.BeneficiaryPersPatroName, ct.BeneficiaryPersPassportSer, ct.BeneficiaryPersPassportNo, 
		ct.BeneficiaryPersPassportDate, ct.BeneficiaryPersPassportIssuer, ct.BeneficiaryFirmRegNo, 
		ct.BeneficiaryFirmName, ct.BeneficiaryFirmBankAccount, ct.BeneficiaryFirmBankName, 
		ct.BeneficiaryFirmBankMFO, ct.BeneficiaryFirmDelegatePerson, ct.BeneficiaryFirmDelegateGrounds, 
		ct.BeneficiaryAddress, ct.BeneficiaryPhone, ct.BeneficiaryEmail,
		-- exec a2temp.fetch_colums N'alias', N'ctd', N'a2insurance', N'ContractsOSAGO', 100, @Exclude=N'Id';
		ctd.ContractId, ctd.MediaType, ctd.BlankSeries, ctd.BlankNo, ctd.StickerSeries, ctd.StickerNo, 
		ctd.StickerMatches, ctd.TariffTable, ctd.Duration, ctd.DatePay, ctd.Exemption, ctd.IsUnexperienced, 
		ctd.IsFroad, ctd.InsurantDocKind, ctd.InsurantDocSer, ctd.InsurantDocNo, ctd.InsurantDocDate, 
		ctd.InsurantDocIssuer, ctd.Usage, ctd.IsCommercePass, ctd.IsInspectionRequired, ctd.NextInspectionDate, 
		ctd.MonthsUnusedMask, ctd.MonthsUnusedQTY, ctd.PremiumCalc, ctd.PremiumHand, ctd.isPremiumHand, 
		ctd.BonusMalus, ctd.Discount, ctd.BM, ctd.K1, ctd.K2, ctd.K3, ctd.K4, ctd.K5, ctd.K6, ctd.K7, 
		ctd.D1, ctd.D2,
		-- exec a2temp.fetch_colums N'alias', N'ctv', N'a2insurance', N'ContractsVehicles', 100, @Exclude=N'ContractId,Index';
		ctv.VIN, ctv.LicensePlate, ctv.MakeId, ctv.MakeName, ctv.ModelId, ctv.ModelName, ctv.ModelSuffix, 
		ctv.ProductionYear, ctv.EngineDisplacement, ctv.Color, ctv.RegistrationRegion, ctv.RegistrationDistrict, 
		ctv.RegistrationCity, ctv.RegistrationZone
	from a2insurance.Contracts ct
	inner join a2insurance.ContractsOSAGO ctd on ctd.ContractId=ct.Id
	inner join a2insurance.ContractsVehicles ctv on ctv.ContractId=ct.Id and ctv.[Index]=0
	where ct.Id=@Id;

	select [BlankSeries!TBlankSeries!Array]=null,
		[Key!!Id]=bs.[Key]
	from a2insurance.OSAGO_BlanksSeries bs
	where bs.IsVoid=0
	order by bs.[Key]

end