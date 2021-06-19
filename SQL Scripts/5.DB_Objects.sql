--------VIEWS-------------------------------------------------
CREATE VIEW dbo.VW_ServiceProviderPlan
AS
	SELECT 
		SP.SP_ID,SP.SP_Name, SP_Email, SP.SP_Contact
		,P.Plan_Name, P.Cycle, P.Price
		,CONCAT(IIF(Has_Wifi = 1, 'WIFI, ',''),IIF(Has_TV = 1 ,'TV, ',''),IIF(Has_Mobile = 1,'Mobile','')) AS ServicesIncluded
	FROM ServiceProvider SP
	INNER JOIN [Plan] P ON P.SP_ID = SP.SP_ID


GO


CREATE VIEW VW_CustomerPlan 
AS
	SELECT 
		c.Customer_ID, c.Customer_fname, c.Customer_Lname, c.email, 
		SP.SP_Name, p.Plan_ID, p.Plan_Name, p.Price, CP.[Start Date], CP.[End date]
	FROM Customer c 
	INNER JOIN Customer_Plan cp ON c.Customer_ID = cp.Customer_ID 
	INNER JOIN [Plan] p ON cp.Plan_ID = p.Plan_ID 
	INNER JOIN ServiceProvider sp ON p.SP_ID = sp.SP_ID
GO


--ALSO INCLUDE QUANTITY AND PRICE
CREATE VIEW VW_CustomerAssets
AS
	SELECT c.Customer_ID, c.Customer_fname, c.Customer_lname, a.Asset_Name 
	FROM (Customer c 
	INNER JOIN [Order] o ON c.Customer_ID = o.Customer_ID) 
	INNER JOIN Asset a ON o.Asset_ID = a.Asset_ID;
	
GO


---------------STORED PROCEDURE-----------------------------------------

CREATE PROCEDURE spLeadingServiceProviderByYear (
	@Year int,
	@Sp_id int output,
	@Sp_Name varchar(50) output,
	@Sp_Email varchar(50) output,
	@Sp_Contact varchar(50) output,
	@BillingYear int output,
	@Total decimal(8,3) output
)
AS
BEGIN
	SELECT TOP 1 @Sp_id=sp.Sp_id, @Sp_Name=sp.Sp_Name, @Sp_Email = sp.Sp_Email, @Sp_Contact=sp.Sp_Contact,@BillingYear = b.[Year], @Total = SUM(b.TotalAmount)
	FROM ServiceProvider sp
	INNER JOIN [Plan] p ON sp.Sp_id = p.Sp_id
	INNER JOIN Customer_Plan cp ON p.Plan_id = cp.Plan_id
	INNER JOIN Billinginfo b ON cp.Customer_id = b.Customer_id
	WHERE [Year] = @Year
	GROUP BY sp.Sp_id, sp.Sp_Name, sp.Sp_Email, sp.Sp_Contact,b.[Year]
	ORDER BY SUM(b.TotalAmount) DESC

	SELECT @Sp_id AS ServiceProvider_ID,@Sp_Name ServiceProvider_Name,
		@Sp_Email ServiceProvider_Email,@Sp_Contact ServiceProvider_Contact,
		@BillingYear Billing_Year,@Total Total_Revenue

END
GO


CREATE PROCEDURE ServiceProviderSales(@spid Integer, @month Integer, @year Integer)
AS 
BEGIN

	SELECT  @spid, MONTH(cp.[Start Date]),YEAR(cp.[Start Date]),sum(p.Price) as Sales 
	FROM Customer_Plan cp 
	JOIN [Plan] p ON cp.Plan_ID=p.Plan_ID 
	WHERE (MONTH(cp.[Start Date])=@month 
		AND SP_ID=@spid 
		AND YEAR(cp.[Start Date])=@year) 
		GROUP BY SP_ID ,month(cp.[Start Date]),year(cp.[Start Date])
END 
GO


CREATE PROCEDURE dbo.GenerateConsolidatedBill
(
	 @Customer_ID INT
	,@FromDate DATE
	,@ToDate DATE
)
AS
BEGIN
	DECLARE @OrderSum DECIMAL(8,3) = 0
	DECLARE @PlanSum DECIMAL(8,3) = 0

	CREATE TABLE #CustomerPlanMapping
	(
		 Customer_ID BIGINT
		,SP_ID INT
		,StartDate DATE
		,EndDate DATE
		,Plan_Price DECIMAL(8,3)
		,Plan_Cycle VARCHAR(10)
		,ServicesIncluded VARCHAR(20)
		,MonthlyCharges DECIMAL(8,3)
	)

	--Customer plans list within the given time period
	--CASE 1 : StartDate and EndDate both are between FromDate and ToDate
	INSERT INTO #CustomerPlanMapping
	SELECT 
		 CP.Customer_ID, SP_ID
		,CP.[Start Date]
		,CP.[End date]
		,P.Price, P.Cycle
		,CONCAT(IIF(Has_Wifi = 1, 'WIFI, ',''),IIF(Has_TV = 1 ,'TV, ',''),IIF(Has_Mobile = 1,'Mobile',''))
		,dbo.GetMonthlyCharges(P.Price, P.Cycle)
	FROM Customer_Plan CP
	INNER JOIN [Plan] P ON P.Plan_ID = CP.Plan_ID
	WHERE Customer_ID = @Customer_ID
		AND (CP.[Start date] BETWEEN @FromDate AND @ToDate AND CP.[End date] BETWEEN @FromDate AND @ToDate)

	UNION

	--CASE 2 : FromDate and ToDate are both between StartDate and EndDate
	SELECT 
		 CP.Customer_ID, SP_ID
		,@FromDate
		,@ToDate
		,P.Price, P.Cycle
		,CONCAT(IIF(Has_Wifi = 1, 'WIFI, ',''),IIF(Has_TV = 1 ,'TV, ',''),IIF(Has_Mobile = 1,'Mobile',''))
		,dbo.GetMonthlyCharges(P.Price, P.Cycle)
	FROM Customer_Plan CP
	INNER JOIN [Plan] P ON P.Plan_ID = CP.Plan_ID
	WHERE Customer_ID = @Customer_ID
		AND (@FromDate BETWEEN CP.[Start Date] AND CP.[End Date] AND @ToDate BETWEEN CP.[Start Date] AND CP.[End Date])

	UNION
	
	--CASE 3 : StartDate	FromDate	EndDate	ToDate
	SELECT 
		 CP.Customer_ID, SP_ID
		,@FromDate
		,CP.[End Date]
		,P.Price, P.Cycle
		,CONCAT(IIF(Has_Wifi = 1, 'WIFI, ',''),IIF(Has_TV = 1 ,'TV, ',''),IIF(Has_Mobile = 1,'Mobile',''))
		,dbo.GetMonthlyCharges(P.Price, P.Cycle)
	FROM Customer_Plan CP
	INNER JOIN [Plan] P ON P.Plan_ID = CP.Plan_ID
	WHERE Customer_ID = @Customer_ID
		AND (@FromDate BETWEEN CP.[Start Date] AND CP.[End Date] AND CP.[End date] BETWEEN @FromDate AND @ToDate)

	UNION
	
	--CASE 4 : FromDate	StartDate	ToDate	EndDate
	SELECT 
		 CP.Customer_ID, SP_ID
		,CP.[Start Date]
		,@ToDate
		,P.Price, P.Cycle
		,CONCAT(IIF(Has_Wifi = 1, 'WIFI, ',''),IIF(Has_TV = 1 ,'TV, ',''),IIF(Has_Mobile = 1,'Mobile',''))
		,dbo.GetMonthlyCharges(P.Price, P.Cycle)
	FROM Customer_Plan CP
	INNER JOIN [Plan] P ON P.Plan_ID = CP.Plan_ID
	WHERE Customer_ID = @Customer_ID
		AND (CP.[Start Date] BETWEEN @FromDate AND @ToDate AND @ToDate BETWEEN CP.[Start Date] AND CP.[End Date])


	--Customer plan list
	SELECT * FROM #CustomerPlanMapping

	--Asset Owned by the customer
	SELECT *
	FROM [Order] 
	WHERE Customer_ID = @Customer_ID
		AND Order_Date BETWEEN @FromDate AND @ToDate


	--Asset charges in case any exist
	SELECT @OrderSum = SUM(Amount) 
	FROM [Order] 
	WHERE Customer_ID = @Customer_ID
		AND Order_Date BETWEEN @FromDate AND @ToDate

	--Plan charges based on the month and cycle
	SELECT @PlanSum = SUM(CPM.MonthlyCharges*(DATEDIFF(MONTH,StartDate,EndDate))) 
	FROM #CustomerPlanMapping CPM
	
	--Total charges
	SELECT (ISNULL(@OrderSum,0) + ISNULL(@PlanSum,0)) AS Total_Charges
	
END
GO


CREATE PROCEDURE TotalCustomers (@SP_ID INT)
AS
BEGIN
	SELECT SP.Sp_id, SP.Sp_Name, COUNT(customer_id) AS TotalCustomers
	FROM Registrationinfo RI
	INNER JOIN ServiceProvider SP ON SP.Sp_id = RI.SP_ID
	WHERE RI.[SP_ID]=@SP_ID
	GROUP BY SP.Sp_id, SP.Sp_Name
END
GO


----TRIGGERS---------------------------

CREATE TRIGGER CustomerAudit ON customer 
FOR UPDATE,INSERT,DELETE
AS 
	IF EXISTS(SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted)
	BEGIN
		INSERT INTO [Customer_Audit] (Customer_ID,Customer_fname,Customer_Lname,Address_line1,
		City,[State], [zipcode], [phone_number],[email],[DateofBirth], Action,ActionDate)	
		SELECT [Customer_ID],[Customer_fname],[Customer_Lname],[Address_line1],
		[City],[State], [zipcode], [phone_number],[email],[DateofBirth],'U',getdate() from deleted
	END

	IF EXISTS (SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
	BEGIN
		INSERT INTO [Customer_Audit] (Customer_ID,Customer_fname,Customer_Lname,Address_line1,
		City,[State], [zipcode], [phone_number],[email],[DateofBirth], Action,ActionDate)
		SELECT [Customer_ID],[Customer_fname],[Customer_Lname],[Address_line1],
		[City],[State], [zipcode], [phone_number],[email],[DateofBirth],'I',getdate() from Inserted
	END
	
	IF EXISTS(SELECT * FROM DELETED) AND NOT EXISTS(SELECT * FROM INSERTED)
	BEGIN
		INSERT INTO [Customer_Audit] (Customer_ID,Customer_fname,Customer_Lname,Address_line1,
		City,[State], [zipcode], [phone_number],[email],[DateofBirth], Action,ActionDate)
		SELECT [Customer_ID],[Customer_fname],[Customer_Lname],[Address_line1],
		[City],[State], [zipcode], [phone_number],[email],[DateofBirth],'D',getdate() from Deleted
	END

GO
	
CREATE TRIGGER CustomerPlanAudit ON Customer_Plan
FOR UPDATE,INSERT,DELETE
AS 
	IF EXISTS(SELECT * FROM INSERTED) AND EXISTS (SELECT * FROM DELETED)
	BEGIN
		INSERT INTO Customer_Plan_Audit( CustPlan_ID,Customer_ID,Plan_ID,[Start Date],[End Date], Action,ActionDate)
		SELECT  CUSTPLAN_ID,CUSTOMER_ID,PLAN_ID,[START DATE],[END DATE],'U',GETDATE() FROM DELETED
	END
	
	IF EXISTS (SELECT * FROM INSERTED) AND NOT EXISTS(SELECT * FROM DELETED)
	BEGIN
		INSERT INTO Customer_Plan_Audit( CustPlan_ID,Customer_ID,Plan_ID,[Start Date],[End Date], Action,ActionDate)
		SELECT CustPlan_ID,Customer_ID,Plan_ID,[Start Date],[End Date], 'I',getdate() from Inserted
	END
	
	IF EXISTS(SELECT * FROM DELETED) AND NOT EXISTS(SELECT * FROM INSERTED)
	BEGIN
		INSERT INTO Customer_Plan_Audit(CustPlan_ID,Customer_ID,Plan_ID,[Start Date],[End Date], Action,ActionDate)
		SELECT CustPlan_ID,Customer_ID,Plan_ID,[Start Date],[End Date],'D',getdate() from Deleted
	END

GO