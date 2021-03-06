
--SCRIPT TO MANIPULATE REGISTRATIONINFO DATA
SELECT DISTINCT Customer_ID, P.Sp_id
INTO #TEMP
FROM Customer_Plan CP
INNER JOIN [Plan] P ON P.Plan_id = CP.Plan_ID

--UPDATE THE SP WITH CUSTOMER ID
UPDATE R
SET R.SP_ID = T.SP_ID
FROM Registrationinfo R
INNER JOIN #TEMP T ON T.Customer_ID = R.Customer_id


--DELETE THE NON MAPPED CUSTOMER IDs
DELETE FROM Registrationinfo
WHERE Reg_ID IN (SELECT r.Reg_ID
FROM Registrationinfo R
LEFT JOIN (
SELECT DISTINCT Customer_ID, P.Sp_id
FROM Customer_Plan CP
INNER JOIN [Plan] P ON P.Plan_id = CP.Plan_ID
)AS X ON X.Customer_ID = r.Customer_id AND X.Sp_id = R.SP_ID
WHERE X.Customer_ID IS NULL)
