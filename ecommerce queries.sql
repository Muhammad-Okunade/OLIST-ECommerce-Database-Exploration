# Saved 21st Nov, 10.01 pm

# Period
select  cast(min(order_purchase_timestamp) as date) as Date_first_order, 
    cast(max(order_purchase_timestamp) as date) as Date_last_order
from OLIST.orders 

# Total States
select count (distinct customer_state) as Number_of_customer_states, count (distinct seller_state) as Number_of_seller_states
from 
    (select c.customer_state, c.customer_city, s.seller_state, s.seller_city
    from OLIST.customers as c
    full join OLIST.sellers as s
    on c.customer_state = s.seller_state) 

# Total Cities
select count (distinct customer_city) as Number_of_customer_cities, count (distinct seller_city) as Number_of_seller_cities
from 
    (select c.customer_state, c.customer_city, s.seller_state, s.seller_city
    from OLIST.customers as c
    full join OLIST.sellers as s
    on c.customer_state = s.seller_state) 

# Total Product Categories
select count(distinct product_category_name) as Total_product_categories
from OLIST.products 

# Total Items in Inventory per Category
select count(*) as Items_per_category, pc.string_field_1 as Product_category
from OLIST.products as p 
join OLIST.product_category as pc 
    on p.product_category_name = pc.string_field_0 
group by Product_category
order by Items_per_category desc 

# Total Items in Inventory per Category (using Sub Queries)
select count(*) as Number_of_items, Product_category
from 
    (select pc.string_field_1 as Product_category
    from OLIST.products as p
    left join OLIST.product_category as pc
    on p.product_category_name = pc.string_field_0)
group by Product_category 
order by Number_of_items desc 

# Total number of Orders in Period
select count(*) as Total_number_of_orders
from OLIST.orders 

# Total Value of Orders in Period
select cast(sum(payment_value) as int) as Total_value_of_orders
from OLIST.order_payments 

# Total Price of Orders Each Month of Each Year
select round(sum(price),2) as Total_orders, extract(month from order_purchase_timestamp) as Month, extract(year from order_purchase_timestamp) as Year 
from OLIST.order_items as oi 
    left join OLIST.orders as o 
    on oi.order_id = o.order_id
group by Year, Month 
order by Year, Month 

# Total Number of Orders Each Month of Each Year
select count(*) as Number_of_orders, date_trunc(order_purchase_timestamp, month) as Month_of_year
from OLIST.orders 
group by Month_of_year 
order by Month_of_year

# Total Number of Orders Each Day by Category

# Total Price of Orders Each Month by Category

/* Returning/Repeat Customers vs New Customers
select (avg
    (case when Number_of_orders = 1 then 1
    else 0
    end))*100 as Percentage_of_Repeat_Customers
from 
    (select count(*) as Number_of_orders, customer_id
    from OLIST.orders
    group by customer_id) */
 
# Most Popular Product Category
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

# Average Order Price in Period of Period
# Average Order Price by State
# Average Order Price by City
# Average Delivery Time by State
# Average Delivery Time by City
# Biggest Customer by Number of Orders by City (Target for Promotions)
# Biggest Customer by Price of Orders by Categories (Target for Promotions) 
# Lowest Rated Sellers by Product Category (Average Rating) 
# Higest Rated Sellers Product Category (Average Rating) 
# Prefered Payment Type by Average Price
# Number of Sellers in Each City (Recruit More Sellers in Areas with Few Sellers) 
# Cities/ States with decreasing sales over period (Average Increase) 
# Most Items Bought from Other Cities
# Day of the weeks/ time of day/ month of the year (use extact)
