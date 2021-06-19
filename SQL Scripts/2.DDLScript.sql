

CREATE TABLE Customer 
(
	Customer_ID bigint not null identity(10000000,1),
	Customer_fname varchar (100) not null,
	Customer_Lname varchar (100) not null,
	Address_line1  varchar (225) not null,
	City varchar (100) not null,
	[State] varchar (2) not null,
	zipcode int not null,
	phone_number VARCHAR(20),
	email varchar(225) not null,
	Constraint email check ( email like '%@%.%'),
	DateofBirth date,
	constraint customr_pk primary key (Customer_Id)
);
GO

CREATE TABLE ServiceProvider
(
	Sp_id int not null identity(3000,1), 
	Sp_Name varchar(50) not null , 
	Sp_Email varchar(50) not null,
	Sp_Contact varchar(50) not null,
	CONSTRAINT PK_ServiceProvider_Sp_id PRIMARY KEY(Sp_id),
);
GO


CREATE TABLE Registrationinfo 
(
	Reg_ID bigint not null identity(10000000,1),
	SP_ID INT not null,
	Customer_id bigint not null,
	reg_date date,
	Constraint  PK_RegistrationInfo_ID primary key (Reg_id),
	Constraint FK_RegistrationInfo_Customer_ID foreign key(Customer_id) references customer(customer_id),
    Constraint FK_RegistrationInfo_SP_ID foreign key(SP_ID) references ServiceProvider(SP_ID)
);
GO

Create table [Plan]
(
	Plan_id int not null identity(1,1),
	Sp_id int not null,
	Plan_Name varchar(20),
	Plan_Desc varchar(50),
	Price decimal(6,2),
	Cycle varchar(20),
	Has_Tv  bit not null,
	Has_Wifi bit not null,
	Has_Mobile bit not null,
	CONSTRAINT CHK_Cycle CHECK (Cycle in ('Yearly','Half-Yearly','Quarterly','Monthly')),
	CONSTRAINT PK_Plan_Plan_id PRIMARY KEY(Plan_id),
	CONSTRAINT FK_Plan_Sp_id FOREIGN KEY(Sp_id) REFERENCES ServiceProvider(Sp_id)
);
GO

Create table Wifi
(
	WPlan_id int not null,
	Usage decimal(6,2),
	speed decimal (6,2),
	Extra_charge decimal (6,2),
	CONSTRAINT PK_Wifi_WPlan_id PRIMARY KEY(WPlan_id),
	CONSTRAINT FK_Wifi_WPlan_id FOREIGN KEY(WPlan_id) REFERENCES [Plan](Plan_id)
);
GO


Create table Television
(
	TPlan_id int not null,
	TName VARCHAR(40),
	Tv_Services varchar(50),
	CONSTRAINT PK_TV_TPlan_id PRIMARY KEY(TPlan_id),
	CONSTRAINT FK_TV_TPlan_id FOREIGN KEY(TPlan_id) REFERENCES [Plan](Plan_id)
);
GO

Create table Mobile
(
	MPlan_id int not null,
	DataSpeed decimal(6,2),
	Calling varchar(20),
	SMS varchar(20),
	CONSTRAINT PK_Mobile_MPlan_id PRIMARY KEY(MPlan_id),
	CONSTRAINT FK_Mobile_MPlan_id FOREIGN KEY(MPlan_id) REFERENCES [Plan](Plan_id)
);
GO

CREATE TABLE [Customer_Plan] 
(
	CustPlan_ID Integer Not Null identity(1,1),
	Customer_ID BIGINT,
	Plan_ID Integer,
	[Start Date] Date,
	[End Date] DATE,
	
	CONSTRAINT PK_CustPlan_ID PRIMARY KEY (CustPlan_ID),
	CONSTRAINT FK_CustPlan_Customer_ID FOREIGN KEY (Customer_ID) REFERENCES CUSTOMER (Customer_ID),
	CONSTRAINT FK_CustPlan_Plan_ID FOREIGN KEY (Plan_ID) REFERENCES [PLAN] (Plan_ID)
)
GO

CREATE TABLE [Asset]
(
	Asset_ID Integer Not Null identity(100,1),
	Asset_Name varchar(20),
	SP_ID Integer,
	[Description] varchar(50),
	ModelNo Integer,
	SerialNo Integer,
	Quantity Integer,
	Price Decimal(6,2),
	CONSTRAINT PK_Asset_ID PRIMARY KEY (Asset_ID),
	CONSTRAINT FK_Asset_SP_ID FOREIGN KEY (SP_ID) REFERENCES ServiceProvider (SP_ID)
)
GO

CREATE TABLE dbo.[ORDER]
(
	 Order_ID BIGINT NOT NULL IDENTITY(100000,1)
	,Customer_ID BIGINT NOT NULL
	,Asset_ID INT NOT NULL
	,Order_Desc VARCHAR(200)
	,Order_Date DATE NOT NULL
	,Quantity INT NOT NULL
	,Amount AS dbo.CalculatePrice(Asset_ID,Quantity)
 CONSTRAINT PK_Order_Order_ID PRIMARY KEY (Order_ID)
,CONSTRAINT FK_Order_Customer_ID FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID)
,CONSTRAINT FK_Order_Asset_ID FOREIGN KEY (Asset_ID) REFERENCES Asset(Asset_ID)
)
GO


CREATE TABLE dbo.BillingInfo
(
	 Transaction_ID BIGINT NOT NULL IDENTITY(500000,1)
	,Customer_ID BIGINT NOT NULL
	,[Month] INT NOT NULL
	,[Year] INT NOT NULL
	,TotalAmount AS CONVERT(DECIMAL(8,3),dbo.CalculateTotalAmount(Customer_ID,[Month],[Year]))
	,YearlyEstimate AS (dbo.CalculateTotalAmount(Customer_ID,[Month],[Year])*12)
 CONSTRAINT PK_BillingInfo_Transaction_ID PRIMARY KEY (Transaction_ID)
,CONSTRAINT FK_BillingInfo_Customer_ID FOREIGN KEY (Customer_ID) REFERENCES Customer(Customer_ID)
) 
GO

CREATE TABLE [dbo].[Customer_Audit](
	
	[Customer_AuditID] [bigint] primary key IDENTITY(1,1) NOT NULL,
	[Customer_ID] [bigint] NOT NULL,
	[Customer_fname] [varchar](100) NOT NULL,
	[Customer_Lname] [varchar](100) NOT NULL,
	[Address_line1] [varchar](225) NOT NULL,
	[City] [varchar](100) NOT NULL,
	[State] [varchar](2) NOT NULL,
	[zipcode] [int] NOT NULL,
	[phone_number] [varchar](20) NULL,
	[email] [varchar](225) NOT NULL,
	[DateofBirth] [date] NULL,
	Action char(1),
	ActionDate datetime);
GO

CREATE TABLE [dbo].[Customer_Plan_Audit](
	[CustomerPlanAudit_ID] [int] IDENTITY(1,1) NOT NULL primary key,
	[CustPlan_ID] [int] NOT NULL,
	[Customer_ID] [bigint] NULL,
	[Plan_ID] [int] NULL,
	[Start Date] [date] NULL,
	[End Date] [date] NULL,
	[Action] [char](1) NULL,
	[ActionDate] [datetime] NULL
	)

GO