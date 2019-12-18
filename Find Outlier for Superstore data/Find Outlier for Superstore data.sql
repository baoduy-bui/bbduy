-- STEP  1: Find the sum of value of orders group by state.
with sales_per_order as (
select Order_ID
	, state
	, sum(Sales) as total_order_sales
from performance.orders
group by Order_ID, state
)
-- STEP 2: Find the average and standard  diviation. 
, avg_std as (
select state 
	,sum(total_order_sales) as sum_sales
	,count(*) as number_of_orders
	,avg(total_order_sales) as avg_sales
	,std(total_order_sales) as std_sales
from sales_per_order 
group by state
)
-- STEP 3: Find upper and lower whisker
-- upper_whisker = avg + std*steps
-- lower_whisker = avg - std*steps
-- with steps = 3
, upper_lower_whisker as (
select state
	, std_sales
	, avg_sales
	, number_of_orders
	, (avg_sales + std_sales*3) as upper_whisker
    , case when (avg_sales - std_sales*3) < 0 then 0 
	else (avg_sales - std_sales*3) end as lower_whisker 
from avg_std 
) 
-- STEP 4:  Determind which orders are oulier.

, find_outliers as ( 
select spo.Order_ID 
	, spo.state 
	, spo.total_order_sales 
	, ulh.number_of_orders 
	, ulh.std_sales 
	, ulh.avg_sales 
	, ulh.upper_whisker 
	, ulh.lower_whisker 
	, case when spo.total_order_sales > ulh.upper_whisker
		or spo.total_order_sales < ulh.lower_whisker 
	then 'Outlier' else 'Expected' end as Outlier_status 
from sales_per_order as spo 
	left join upper_lower_whisker as ulh on ulh.state = spo.state ) 
    
-- STEP 5: Calculate the average value of order after deleting outliers.
select state 
	-- All order by state
	, number_of_orders 
	, std_sales 
	, upper_whisker 
	, lower_whisker 
	, avg_sales 
	, avg(total_order_sales) as avg_sales_no_outliers  -- only count order with 'Expected'
	-- Order after eliminating outliers
	, count(*) as new_number_of_orders -- count row that have 'Expected'
	-- The percentage of remaining data
	, count(*)/number_of_orders*100 as remaining_data 
from find_outliers where outlier_status = 'Expected' 
group by state,number_of_orders 
-- The percentage of remainning data are all higher than 95%. Therefore, no need to change the step. 