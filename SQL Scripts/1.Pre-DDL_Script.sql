CREATE FUNCTION dbo.CalculatePrice(@Asset_ID INT,@Quantity INT)
RETURNS DECIMAL(8,3)
AS
BEGIN
	DECLARE @finalResult DECIMAL(8,3) = 0
	
	SELECT @finalResult = @Quantity*A.Price
	FROM Asset A
	WHERE A.Asset_ID = @Asset_ID

	RETURN @finalResult
END
GO



CREATE FUNCTION dbo.GetMonthlyCharges(@Price DECIMAL(8,3), @Cycle VARCHAR(15))
RETURNS DECIMAL(8,3)
AS
BEGIN
	DECLARE @MonthlyCharge DECIMAL(8,3) = 0

	SELECT @MonthlyCharge = 
		CASE WHEN @Cycle = 'YEARLY' THEN (@Price/12)
			 WHEN @Cycle = 'HALF-YEARLY' THEN (@Price/6)
			 WHEN @Cycle = 'QUARTERLY' THEN (@Price/3)
			 WHEN @Cycle = 'MONTHLY' THEN (@Price)
		END 

	RETURN @MonthlyCharge
END
GO



CREATE FUNCTION dbo.CalculateTotalAmount(@Customer_ID BIGINT,@Month INT,@Year INT)
RETURNS DECIMAL(8,3)
AS
BEGIN
	DECLARE @TotalAmount DECIMAL(8,3)

	
	--Plan charges based on the month and cycle
	SELECT @TotalAmount = dbo.GetMonthlyCharges(P.Price, P.Cycle)
	FROM Customer_Plan CP
	INNER JOIN [Plan] P ON P.Plan_ID = CP.Plan_ID
	WHERE Customer_ID = @Customer_ID
		AND DATEFROMPARTS(@Year, @Month, '01') BETWEEN CP.[Start Date] AND CP.[End Date]

	
	RETURN @TotalAmount
END
GO

