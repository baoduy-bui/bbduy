WITH  sale_per_order as (SELECT Order_ID
, Category 
, Sum(Sales) as Total_order_sale
FROM performance.Orders 
GROUP BY Category, Order_ID
ORDER BY Category
)
, avg_std as (SELECT category
, count(*) as  number_ordrer
, sum(Total_order_sale) as Sum_sales
, avg(Total_order_sale) as avg_sales
, std(Total_order_sale) as std_sales
FROM sale_per_order
GROUP BY Category
)

, upper_lower_whisker as (SELECT Category
, number_ordrer
, Sum_sales
, avg_sales
, std_sales
, (avg_sales + 3*std_sales)  as upper_whisker
, CASE WHEN (avg_sales - 3*std_sales) < 0  THEN 0 ELSE (avg_sales - 3*std_sales) END as lower_whisker
FROM avg_std
)
, outliers as (SELECT spo.Order_ID
, spo.Category
, spo.Total_order_sale
, ulw.number_ordrer
, ulw.Sum_sales
, ulw.std_sales
, ulw.upper_whisker
, ulw.lower_whisker
, CASE WHEN spo.Total_order_sale < ulw.lower_whisker or spo.Total_order_sale > ulw.upper_whisker THEN 'Outlier' ELSE 'Expected' END AS outlier_status
FROM sale_per_order as spo
LEFT JOIN upper_lower_whisker as ulw ON spo.Category = ulw.Category
)

SELECT Category
, number_ordrer
, std_sales
, upper_whisker
, lower_whisker
, sum(Total_order_sale) as new_Sum_sales
, count(*) as new_no_orders
, count(*)/number_ordrer *100 as remaining_data
 FROM outliers
 WHERE outlier_status = 'Expected'
 GROUP BY Category
 ORDER BY Category;
