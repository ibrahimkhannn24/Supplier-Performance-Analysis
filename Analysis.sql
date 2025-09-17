-- Firstly, we take a quick overview of the whole order_history table to identify any inconsistencies/missing values 
-- and the total number of rows, which is 12,000.
SELECT * FROM order_history;
SELECT COUNT(*) FROM order_history; 

-- Obtaining the number of missing values in each column.
SELECT 
	SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_count_order_id,
    SUM(CASE WHEN supplier_id IS NULL THEN 1 ELSE 0 END) AS null_count_supplier_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_count_order_date,
    SUM(CASE WHEN units_ordered IS NULL THEN 1 ELSE 0 END) AS null_count_units_ordered,
    SUM(CASE WHEN units_delivered IS NULL THEN 1 ELSE 0 END) AS null_count_units_delivered,
    SUM(CASE WHEN delivery_date IS NULL THEN 1 ELSE 0 END) AS null_count_delivery_date
FROM order_history;

-- In this case, imputing dates could introduce inconsistencies in our visualizations, therefore we can delete rows with missing delivery_dates.
DELETE FROM order_history WHERE delivery_date IS NULL;

-- 201 rows removed, 11,799 rows left for analysis.
-- For the 'units_ordered' column, since the missing values are relatively important and can be imputed using the mean, we will impute them using the average units ordered for each supplier ID, as there are no outliers present.
SELECT 
	MAX(units_ordered) AS max_value,
	MIN(units_ordered) AS min_value
FROM order_history;
WITH AvgUnits AS (
    SELECT 
        supplier_id,
        AVG(CAST(units_ordered AS FLOAT)) AS avg_units_ordered
    FROM 
        Order_History
    WHERE 
        units_ordered IS NOT NULL
    GROUP BY 
        supplier_id
)

UPDATE Order_History
SET units_ordered = (
    SELECT CAST(avg_units_ordered AS INTEGER)
    FROM AvgUnits
    WHERE AvgUnits.supplier_id = Order_History.supplier_id
)
WHERE units_ordered IS NULL;
DELETE FROM order_history WHERE units_ordered IS NULL;

-- Again, since the number of rows with 'units_delivered' marked as 'error' are relatively important, we will impute these values using the average units delivered for each supplier ID, as there are no outliers present.
SELECT 
	MAX(units_delivered) AS max_value,
	MIN(units_delivered) AS min_value
FROM order_history;
WITH AvgUnits AS (
    SELECT 
        supplier_id,
        ROUND(AVG(CAST(units_delivered AS FLOAT))) AS avg_units_delivered
    FROM 
        Order_History
    WHERE 
        units_delivered IS NOT NULL 
        AND units_delivered != 'error' 
    GROUP BY 
        supplier_id
)

UPDATE Order_History
SET units_delivered = (
    SELECT CAST(avg_units_delivered AS INTEGER)
    FROM AvgUnits
    WHERE AvgUnits.supplier_id = Order_History.supplier_id
)
WHERE units_delivered = 'error';
DELETE FROM order_history WHERE units_delivered IS NULL;

-- Now taking a look at our cleaned table of order_history.
SELECT * FROM order_history;

-- Now, we take a quick overview of the whole supplier_performance table to identify any inconsistencies/missing values.
-- and the total number of rows, which is 5,000.
SELECT * FROM supplier_performance; 
SELECT COUNT(*) FROM supplier_performance; 

-- Obtaining the number of missing values in each column.
SELECT 
	SUM(CASE WHEN supplier_name IS NULL THEN 1 ELSE 0 END) AS null_count_supplier_name,
    SUM(CASE WHEN supplier_id IS NULL THEN 1 ELSE 0 END) AS null_count_supplier_id,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS null_count_region,
    SUM(CASE WHEN on_time_delivery IS NULL THEN 1 ELSE 0 END) AS null_count_on_time_delivery,
    SUM(CASE WHEN defect_rate IS NULL THEN 1 ELSE 0 END) AS null_count_defect_rate,
    SUM(CASE WHEN cost_per_unit IS NULL THEN 1 ELSE 0 END) AS null_count_cost_per_unit
FROM supplier_performance;

-- Since the 'supplier_name' column is categorical and cannot be imputed using common methods like the mean, we will remove the rows with missing supplier names, as we cannot identify the supplier in these cases.
DELETE FROM Order_History
WHERE supplier_id IN (
    SELECT supplier_id
    FROM Supplier_Performance
    WHERE supplier_name IS NULL
);
DELETE FROM Supplier_Performance
WHERE supplier_name IS NULL;

-- 99 rows removed, 4,901 rows left for analysis. (supplier_performance)
-- 202 rows removed, 11,581 left for analysis. (order_history)
-- As for 'on_time_delivery' and'defect_rate' since missing values here are important and can be imputed using methods like mean, we will impute them using the average of their respective columns (since their are no outliers).
SELECT 
	MAX(on_time_delivery) AS max_value_ontimedelivery,
	MIN(on_time_delivery) AS min_value_ontimedelivery,
	MAX(defect_rate) AS max_value_defect_rate,
	MIN(defect_rate) AS min_value_defectrate
FROM supplier_performance;
UPDATE Supplier_Performance
SET on_time_delivery = (
    SELECT AVG(CAST(on_time_delivery AS INTEGER))
    FROM supplier_performance
    WHERE on_time_delivery IS NOT NULL
)
WHERE on_time_delivery IS NULL;
UPDATE supplier_performance
SET defect_rate = ROUND((
    SELECT AVG(CAST(defect_rate AS NUMERIC))
    FROM supplier_performance
    WHERE defect_rate IS NOT NULL
), 4)
WHERE defect_rate IS NULL;

-- Now taking a look at our cleaned table of supplier_performance.
SELECT * FROM supplier_performance;

-- Now standardizing the column supplier_name by removing any trailing/leading spaces and replacing the hyphen with 'and'.
UPDATE supplier_performance
SET supplier_name = TRIM(REPLACE(supplier_name, '-', ' and '));

-- Now standardizing the column region by capitalizing all values and removing any trailing/leading spaces.
UPDATE supplier_performance
SET region = TRIM(INITCAP(region));

-- Now taking a look at our formatted/cleaned dataset.
SELECT * FROM supplier_performance;


-- This query retrieves performance metrics for each supplier by joining the Supplier_Performance and Order_History tables.
SELECT 
    SP.supplier_id,
    ROUND(AVG(SP.on_time_delivery), 2) AS avg_on_time_delivery_rate,
    ROUND(AVG(SP.defect_rate), 4) AS avg_defect_rate,
    SUM(CAST(OH.units_delivered AS INTEGER)) AS total_units_supplied,
    ROUND(AVG(SP.cost_per_unit), 2) AS avg_cost_per_unit
FROM 
    Supplier_Performance SP
JOIN 
    Order_History OH ON SP.supplier_id = OH.supplier_id
GROUP BY 
    SP.supplier_id
ORDER BY
	SP.supplier_id;


-- This query retrieves the top 5 best-performing suppliers based on their average on-time delivery rate, the results are grouped by suppplier_id.
-- Suppliers with a 100% defect rate were common, so the average defect rate is used as a secondary ordering criterion to ensure a more accurate ranking of the top suppliers.
SELECT 
    supplier_id,
    supplier_name,
    region,
    AVG(on_time_delivery) AS on_time_delivery_rate
FROM 
    Supplier_Performance
GROUP BY 
    supplier_id
ORDER BY 
    on_time_delivery_rate DESC, defect_rate ASC
LIMIT 5; 


-- Calculating average metrics by region and identify regions with best and worst performance.
SELECT 
    region,
    ROUND(AVG(on_time_delivery),2) AS avg_on_time_delivery_rate,
    ROUND(AVG(defect_rate),4) AS avg_defect_rate
FROM 
    Supplier_Performance
GROUP BY 
    region
ORDER BY 
    avg_on_time_delivery_rate DESC, avg_defect_rate ASC
LIMIT 1; -- Best performance

SELECT 
    region,
    ROUND(AVG(on_time_delivery),2) AS avg_on_time_delivery_rate,
    ROUND(AVG(defect_rate),4) AS avg_defect_rate
FROM 
    Supplier_Performance
GROUP BY 
    region
ORDER BY 
    avg_on_time_delivery_rate ASC, avg_defect_rate DESC
LIMIT 1; -- Worst performance