
# Period
-- DB contains orders made between September 2016 and October, 2018.
select  cast(min(order_purchase_timestamp) as date) as Date_first_order, 
    cast(max(order_purchase_timestamp) as date) as Date_last_order,
    round(date_diff(max(order_purchase_timestamp), min(order_purchase_timestamp), day)/365, 2) as Years
from OLIST.orders 

# Total States
-- OLIST has customers in all states in Brazil while it has sellers in only 23 of the states.
select count (distinct customer_state) as Number_of_customer_states, count (distinct seller_state) as Number_of_seller_states
from 
    (select c.customer_state, c.customer_city, s.seller_state, s.seller_city
    from OLIST.customers as c
    full join OLIST.sellers as s
    on c.customer_state = s.seller_state) 

# Total Cities
-- Customers are present in 4119 cities while sellers are present in 611 cities.
select count (distinct customer_city) as Number_of_customer_cities, count (distinct seller_city) as Number_of_seller_cities
from 
    (select c.customer_state, c.customer_city, s.seller_state, s.seller_city
    from OLIST.customers as c
    full join OLIST.sellers as s
    on c.customer_state = s.seller_state) 

# Total Product Categories
-- OLIST sells products across 73 product categories.
select count(distinct product_category_name) as Total_product_categories
from OLIST.products 

# Total Items in Inventory per Category
-- Bed, Bath & Table is the most stocked product category followed by Sports Leisure category.
select count(*) as Items_per_category, pc.string_field_1 as Product_category
from OLIST.products as p 
join OLIST.product_category as pc 
    on p.product_category_name = pc.string_field_0 
group by Product_category
order by Items_per_category desc 

# Total Items in Inventory per Category (using Sub Queries)
-- Bed, Bath & Table is the most stocked product category followed by Sports Leisure category.
select count(*) as Number_of_items, Product_category
from 
    (select pc.string_field_1 as Product_category
    from OLIST.products as p
    left join OLIST.product_category as pc
    on p.product_category_name = pc.string_field_0)
group by Product_category 
order by Number_of_items desc 

# Total number of Orders in Period
-- 99,441 orders were made during this period.
select count(*) as Total_number_of_orders
from OLIST.orders 

# Total Value of Orders in Period
-- R$16,008,872 worth of orders were made during this period.
select cast(sum(payment_value) as int) as Total_value_of_orders
from OLIST.order_payments 

# Total Price of Orders Each Month of Each Year
-- November 2017 had the highest amount in sales on record
select round(sum(price),2) as Total_orders, extract(month from order_purchase_timestamp) as Month, extract(year from order_purchase_timestamp) as Year 
from OLIST.orders as o
    left join OLIST.order_items as oi 
    on oi.order_id = o.order_id
group by Year, Month 
order by Year desc, Month desc 

# Total Price of Orders Each Month of Each Year
-- November 2017 had the highest amount in sales on record
select round(sum(price),2) as Total_orders, date_trunc(order_purchase_timestamp, month) as Month_of_year
from OLIST.orders as o
    left join OLIST.order_items as oi 
    on oi.order_id = o.order_id
group by Month_of_year
order by Month_of_year desc  

# Average Number of Orders Each Month
-- Orders are lowest during at the end and start of the year except for November where orders are the highest (Holiday deals)
select cast(avg(Number_of_orders) as int) as Number_of_orders,extract(month from Month_of_year) as Month 
from 
    (select count(*)  as Number_of_orders, date_trunc(order_purchase_timestamp, month) as Month_of_year 
    from OLIST.orders 
    group by Month_of_year)
group by Month 
order by Number_of_orders desc 

# Average Number of Orders Each Day
-- The weekend had the least amount of orders with most orders coming on Tuesdays, Mondays and Wednesdays
select cast(avg(Number_of_orders) as int) as Number_of_orders, extract(dayofweek from Day_of_week) as Day
from
    (select count(*) as Number_of_orders, date_trunc(order_purchase_timestamp, day) as Day_of_week
    from OLIST.orders 
    group by Day_of_week)
group by Day 
order by Number_of_orders desc 

#Returning/Repeat Customers vs New Customers
-- There are currently no repeat customers on record.
select (avg
    (case when Number_of_orders = 1 then 0
    else 1
    end))*100 as Percentage_of_Repeat_Customers
from 
    (select count(*) as Number_of_orders, customer_id
    from OLIST.orders
    group by customer_id)
 
# Most Popular Product Category
-- The Bed, Bath and Table category at 11.2% of the orders, is the most popular category based on customer orders
select Product_category, count (*) as Number_of_orders, round(100*(count(*)/(select count(*) from OLIST.orders)),2) as Percentage_of_orders 
from OLIST.order_items as oi
 left join (select p.product_id, pc.string_field_1 as Product_category 
        from OLIST.products as p
        left join OLIST.product_category as pc
        on p.product_category_name = pc.string_field_0) as pceng 
    on oi.product_id = pceng.product_id 
group by Product_category 
order by Number_of_orders desc 
limit 10 

# Average Order Price in Period vs Average Order Price by Category
-- Computers cost the highest of all the product categories on average, costing over 8 times the average product price.
select round(avg(price),2) as Average_price, category,
    (select round(avg(price),2) from OLIST.order_items) as Overall_average 
from 
    (select oi.price as price, pc.string_field_1 as category
    from OLIST.order_items as oi
    left join OLIST.products as p 
    on oi.product_id = p.product_id 
    left join OLIST.product_category as pc
    on p.product_category_name = pc.string_field_0)
group by category 
order by Average_price desc 

# Top Performing Categories by Period (Run promotions/ increase prices by category for months were there are spikes in demands for some product categories)
-- Computers and accessories are usually high in demand at the start of the year, especially in February when they account for the most orders.
with cte as (select count(*) as Number_of_orders, extract(month from order_purchase_timestamp) as Month, string_field_1 as Product_category
    from OLIST.orders as o 
        left join OLIST.order_items as oi
        on o.order_id = oi.order_id
        left join OLIST.products as op
        on oi.product_id = op.product_id 
        left join OLIST.product_category as pc 
        on op.product_category_name = pc.string_field_0
     group by Month, Product_category)

select * from
    (select Number_of_orders, Month, Product_category, rank() over(partition by Month order by Number_of_orders desc) as Ranks 
    from cte)
where Ranks in (1,2,3)
order by Month, Ranks

# Average Order Price by Customer State
-- Customers in PB spend the most on orders, more sales should be made to this state.
select round(avg(price),2) as Average_price, State
from 
    (select oi.price as price, c.customer_state as State 
    from OLIST.order_items as oi
    left join OLIST.orders as o 
    on oi.order_id = o.order_id 
    left join OLIST.customers as c
    on o.customer_id = c.customer_id)
group by State  
order by Average_price desc 

# Average Delivery Time by State
-- Deliveries in RR take an average of about 4 days, the longest of all the states. 
select round(avg(Delivery_time), 2) as Avg_delivery_time, State 
from 
    (select date_diff(order_delivered_carrier_date, order_purchase_timestamp, day) as Delivery_time, c.customer_state as State 
    from OLIST.orders as o
    left join OLIST.customers as c 
    on o.customer_id = c.customer_id) 
group by State 
order by Avg_delivery_time desc 

# Lowest Rated Sellers by Product Category (Average Rating)
-- Sellers with multiple sales and an average rating of 1 should be penalised to encourage better quality products on the platform.
select avg(rating_score) as Avg_rating, oi.seller_id, count(*) as Number_of_orders 
from OLIST.order_ratings as ord  
    left join OLIST.order_items as oi
    on ord.order_id = oi.order_id 
group by seller_id 
order by Avg_rating, Number_of_orders desc  

# Higest Rated Sellers Product Category (Average Rating) 
-- Sellers with multiple sales and an average rating of 5 should be rewarded to encourage better quality products on the platform.
select avg(rating_score) as Avg_rating, oi.seller_id, count(*) as Number_of_orders 
from OLIST.order_ratings as ord  
    left join OLIST.order_items as oi
    on ord.order_id = oi.order_id 
group by seller_id 
order by Avg_rating desc, Number_of_orders desc 

# Number of Sellers in Each State
-- Over half of the sellers on the platform are in Sao Paolo, more sellers should be recruited in every other state for more competitive pricing.  
select count(*) as Number_of_sellers, seller_state, (select count(*) from OLIST.sellers) as Sellers_on_OLIST
from OLIST.sellers
group by seller_state
order by Number_of_sellers desc

# Number of Customers in Each State
-- Run targeted marketing campaigns in other states apart from Sao Paolo especially those with few customers.
select count(*) as Number_of_customers, customer_state, (select count(*) from OLIST.customers) as OLIST_customers
from OLIST.customers
group by customer_state
order by Number_of_customers desc


 # Cities/ States with decreasing sales over period (Average Increase between 4 months and 5 months ago) 
-- Revenue from most states was less than the previous month
select round(100*(Total_c_month - Total_p_month)/ Total_p_month, 2) as Percentage_increase_from_previous_month, C_month.State
from
    (select round(sum(oi.price),2) as Total_c_month, c.customer_state as State 
    from OLIST.orders as o
        left join OLIST.customers as c
        on o.customer_id = c.customer_id
        left join OLIST.order_items as oi
        on o.order_id = oi.order_id
    where date_trunc(order_purchase_timestamp, month) = (select date_trunc (date_sub (max(order_purchase_timestamp), interval 120 day), month) from OLIST.orders)
    group by State) as C_month
join
    (select round(sum(price),2) as Total_p_month, c.customer_state as State
    from OLIST.orders as o
        left join OLIST.customers as c
        on o.customer_id = c.customer_id
        left join OLIST.order_items as oi
        on o.order_id = oi.order_id
    where date_trunc(order_purchase_timestamp, month) = (select date_trunc (date_sub (max(order_purchase_timestamp), interval 150 day), month) from OLIST.orders)
    group by State) as P_month
on C_month.State = P_month.State
order by Percentage_increase_from_previous_month 

# Most Items Bought from Other Cities
-- More sellers need to be recruited in other states apart from Sao Paolo, this could help in reducing delivery times
select Number_of_items_bought_from_other_states, a.customer_state, (Number_of_items_bought_from_other_states/ Number_of_orders_from_states) * 100 as Percentage_of_orders_from_state
from    
    (select count(*) as Number_of_items_bought_from_other_states, customer_state
    from OLIST.orders as o
    left join OLIST.customers as c
    on o.customer_id = c.customer_id
    left join OLIST.order_items as oi
    on o.order_id = oi.order_id
    left join OLIST.sellers as s
    on oi.seller_id = s.seller_id
    where customer_state <> seller_state
    group by customer_state) as a
join
    (select count(*) as Number_of_orders_from_states, customer_state
     from OLIST.orders as o
    left join OLIST.customers as c
    on o.customer_id = c.customer_id
    left join OLIST.order_items as oi
    on o.order_id = oi.order_id
    left join OLIST.sellers as s
    on oi.seller_id = s.seller_id
    group by customer_state) as b
on a.customer_state = b.customer_state
order by Percentage_of_orders_from_state

