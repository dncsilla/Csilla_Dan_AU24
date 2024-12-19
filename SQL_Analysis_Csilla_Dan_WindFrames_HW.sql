/* TASK 1: Create a query for analyzing the annual sales data for the years 1999 to 2001, focusing on different sales channels and regions: 'Americas,' 'Asia,' and 'Europe.' 
The resulting report should contain the following columns:
AMOUNT_SOLD: This column should show the total sales amount for each sales channel
% BY CHANNELS: In this column, we should display the percentage of total sales for each channel (e.g. 100% - total sales for Americas in 1999, 63.64% - percentage of sales for the channel “Direct Sales”)
% PREVIOUS PERIOD: This column should display the same percentage values as in the '% BY CHANNELS' column but for the previous year
% DIFF: This column should show the difference between the '% BY CHANNELS' and '% PREVIOUS PERIOD' columns, indicating the change in sales percentage from the previous year.
The final result should be sorted in ascending order based on three criteria: first by 'country_region,' then by 'calendar_year,' and finally by 'channel_desc'
*/

WITH SalesData AS (
    SELECT
        calendar_year,
        country_region,
        channel_desc,
        SUM(amount_sold) AS total_sales
    FROM sh.sales s
    INNER JOIN sh.times t ON s.time_id = t.time_id
    INNER JOIN sh.customers c ON c.cust_id = s.cust_id
    INNER JOIN sh.countries co ON co.country_id = c.country_id
    INNER JOIN sh.channels ch ON ch.channel_id = s.channel_id
    WHERE calendar_year BETWEEN 1999 AND 2001
      AND co.country_region IN ('Americas', 'Asia', 'Europe')
    GROUP BY calendar_year, country_region, channel_desc
),
ChannelPercentages AS (
    SELECT
        calendar_year,
        country_region,
        channel_desc,
        total_sales,
        ROUND(100.0 * total_sales / SUM(total_sales) OVER (PARTITION BY calendar_year, country_region), 2) AS percent_by_channel
    FROM SalesData
),
PreviousYearData AS (
    SELECT
        a.calendar_year,
        a.country_region,
        a.channel_desc,
        a.total_sales,
        a.percent_by_channel AS current_percent,
        b.percent_by_channel AS previous_percent
    FROM ChannelPercentages a
    LEFT JOIN ChannelPercentages b
        ON a.country_region = b.country_region
       AND a.channel_desc = b.channel_desc
       AND a.calendar_year = b.calendar_year + 1
),
FinalReport AS (
    SELECT
        calendar_year,
        country_region,
        channel_desc,
        total_sales AS amount_sold,
        current_percent AS "% BY CHANNELS",
        COALESCE(previous_percent, 0) AS "% PREVIOUS PERIOD",
        ROUND(current_percent - COALESCE(previous_percent, 0), 2) AS "% DIFF"
    FROM PreviousYearData
)
SELECT *
FROM FinalReport
ORDER BY country_region, calendar_year, channel_desc;


/* TASK 2 : 
You need to create a query that meets the following requirements:
Generate a sales report for the 49th, 50th, and 51st weeks of 1999.
Include a column named CUM_SUM to display the amounts accumulated during each week.
Include a column named CENTERED_3_DAY_AVG to show the average sales for the previous, current, and following days using a centered moving average.
For Monday, calculate the average sales based on the weekend sales (Saturday and Sunday) as well as Monday and Tuesday.
For Friday, calculate the average sales on Thursday, Friday, and the weekend.

Ensure that your calculations are accurate for the beginning of week 49 and the end of week 51. */


SELECT 
    t.calendar_week_number,
    t.time_id,
    t.day_name,
    SUM(s.amount_sold) AS sales,
    SUM(SUM(s.amount_sold)) OVER (PARTITION BY t.calendar_week_number ORDER BY t.time_id 
                                   RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum,
    (CASE 
                    WHEN UPPER(t.day_name) = UPPER('Monday') THEN 
                    	ROUND(AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
    								INTERVAL '2' DAY PRECEDING AND 
    								INTERVAL '1' DAY FOLLOWING),2)
                    WHEN UPPER(t.day_name) = UPPER('Friday') THEN 
                    	ROUND(AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
    								INTERVAL '1' DAY PRECEDING AND 
    								INTERVAL '2' DAY FOLLOWING),2)
                    ELSE 
                    	ROUND(AVG(SUM(s.amount_sold)) OVER (ORDER BY t.time_id RANGE BETWEEN 
    								INTERVAL '1' DAY PRECEDING AND 
    								INTERVAL '1' DAY FOLLOWING),2)
    END) AS centered_3_day_avg
FROM sh.sales s 
INNER JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999 AND t.calendar_week_number IN (49, 50, 51) 
GROUP BY t.calendar_week_number, t.time_id 
ORDER BY t.calendar_week_number, t.time_id;


/* TASK 3 Please provide 3 instances of utilizing window functions that include a frame clause, using RANGE, ROWS, and GROUPS modes. 
Additionally, explain the reason for choosing a specific frame type for each example. 
This can be presented as a single query or as three distinct queries.*/

-- RANGE
-- This example calculates the cumulative sales for each day within a specific week (49, 50, 51 of 1999), taking into account the sales up to and including the current day.
-- his frame specifies the cumulative sum of amount_sold up to and including the current row. This is useful for understanding the total sales amount from the start of the 
-- week up to each specific day.
SELECT 
    t.calendar_week_number,
    t.time_id,
    t.day_name,
    SUM(s.amount_sold),
    SUM(SUM(s.amount_sold)) OVER (PARTITION BY t.calendar_week_number ORDER BY t.time_id RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sum
FROM sh.sales s 
INNER JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999 AND t.calendar_week_number IN (49, 50, 51) 
GROUP BY t.calendar_week_number, t.time_id
ORDER BY t.calendar_week_number, t.time_id;

-- ROWS
--This example calculates a centered 3-day moving average for each day, including the current day and the two days before.
--This frame is used to include the current row and the two rows before it, effectively averaging the sales of three consecutive days.
SELECT 
    t.calendar_week_number,
    t.time_id,
    t.day_name,
    SUM(s.amount_sold),
    ROUND(
        AVG(SUM(s.amount_sold)) OVER (
            ORDER BY t.time_id 
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ), 2
    ) AS centered_3_day_avg
FROM sh.sales s 
INNER JOIN sh.times t ON s.time_id = t.time_id
WHERE t.calendar_year = 1999 AND t.calendar_week_number IN (49, 50, 51) 
GROUP BY t.calendar_week_number, t.time_id
ORDER BY t.calendar_week_number, t.time_id;



-- GROUPS
-- This example calculates the monthly cumulative sales from the start of the year for each specific month.
-- This frame calculates to calculate cumulative sales for the last three months up to the current month, based on the month of the sale.
SELECT 
   t.calendar_month_number,
   SUM(s.amount_sold) AS sales,
   SUM(SUM(s.amount_sold)) OVER (ORDER BY t.calendar_month_number
   								GROUPS BETWEEN 2 PRECEDING AND CURRENT ROW) AS last_3month_amount
FROM 
	sh.sales s
INNER JOIN sh.channels c ON c.channel_id = s.channel_id 
INNER JOIN sh.times t ON t.time_id = s.time_id 
INNER JOIN sh.customers c2 ON c2.cust_id = s.cust_id 
WHERE t.calendar_year = 1999
GROUP BY t.calendar_month_number 
ORDER BY t.calendar_month_number;
























