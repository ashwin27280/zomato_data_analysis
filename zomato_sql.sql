create table customers(
customer_id int primary key,
customer_name varchar(100) not null,
reg_date date
);

create table restaurants(
restaurant_id	int primary key,
restaurant_name	varchar(100) not null,
city	varchar(50),
opening_hours varchar(50)
);

create table orders(
order_id	int primary key,
customer_id	int,
restaurant_id	int,
order_item	varchar(50),
order_date	date not null,
order_time	time not null,
order_status	varchar(50) default 'Pending',
total_amount decimal(10,2) not null,
foreign key (customer_id) references customers(customer_id),
foreign key (restaurant_id) references restaurants(restaurant_id)
);

create table riders(
rider_id	int primary key,
rider_name	varchar(100) not null,
sign_up date
);

create table deliveries(
delivery_id	int primary key,
order_id	int,
delivery_status	varchar(50) default 'Pending',
delivery_time	time ,
rider_id int,
foreign key(rider_id) references riders(rider_id),
foreign key(order_id) references orders(order_id)
);

select *from orders;
select *from deliveries;
select *from riders;
select *from restaurants;
select *from customers;


select count(*) from customers
where reg_date is null;

select count(*) from restaurants
where 
	restaurant_name is null
	or 
	city is null
	or 
	opening_hours is null


select count(*) from orders
where 
	order_item is null
	or 
	order_date is null
	or 
	order_time is null
	or
	order_status is null
	or 
	total_amount is null

select count(*) from riders
where 
	rider_id is null
	or 
	rider_name is null
	or 
	sign_up is null

delete from deliveries
where 
	delivery_status is null
	or 
	delivery_time is null

select *from orders;
select *from customers;


select *from 
	(select 
		c.customer_id,
		c.customer_name,
		o.order_item as dishes,
		count(*) as total_orders,
		dense_rank() over(order by count(*) desc) as rank
	from orders as o
	join customers as c
	on c.customer_id=o.customer_id
	WHERE 
	o.order_date BETWEEN '2023-01-01' AND '2023-12-31'
	and c.customer_name='Arjun Mehta'
	group by 1,2,3
	order by 1,4 desc) 
where rank<=5
	
--apply rank system to find top 5 in previous code

--identify the time slots during which the most orders are placed based on 2-hour intervals
select 
	case
		when extract(hour from order_time) between 0 and 1 then '00:00-02:00'
		when extract(hour from order_time) between 2 and 3 then '02:00-04:00'
		when extract(hour from order_time) between 4 and 5 then '04:00-06:00'
		when extract(hour from order_time) between 6 and 7 then '06:00-08:00'
		when extract(hour from order_time) between 8 and 9 then '08:00-10:00'
		when extract(hour from order_time) between 10 and 11 then '10:00-12:00'
		when extract(hour from order_time) between 12 and 13 then '12:00-14:00'
		when extract(hour from order_time) between 14 and 15 then '14:00-16:00'
		when extract(hour from order_time) between 16 and 17 then '16:00-18:00'
		when extract(hour from order_time) between 18 and 19 then '18:00-20:00'
		when extract(hour from order_time) between 20 and 21 then '20:00-22:00'
		when extract(hour from order_time) between 22 and 23 then '22:00-00:00'
		end as time_slot,
		count(order_id)as order_count
from orders
group by time_slot
order by order_count desc;


--Find the average order value per customer who has placed more than 750 orders. -- Return customer_name, and aov(average order value)
select c.customer_name, 
avg(o.total_amount) as aov
from orders as o
join customers as c
on o.customer_id=c.customer_id
group by customer_name
having count(order_id) >750


--List the customers who have spent more than 100K in total on food orders. -- return customer_name, and customer_id!
select customer_name ,total_spent
from 
	(select c.customer_id, c.customer_name, sum(total_amount) as total_spent
	from orders as o
	join customers as c
	on o.customer_id=c.customer_id
	group by 1,2
	order by total_spent ) as t1
	where total_spent>100000


-- Write a query to find orders that were placed but not delivered. -- Return each restuarant name, city and number of not delivered orders
select restaurant_name, city,count(*) as no_ofnotdeliveredorders
from restaurants as rt
join orders as o
	on o.restaurant_id=rt.restaurant_id
join deliveries as d
	on o.order_id=d.order_id
where delivery_status ='Not Delivered'
group by restaurant_name,city

-- Rank restaurants by their total revenue from the last year, including their name, -- total revenue, and rank within their city.
select o.order_date, restaurant_name, city,sum(total_amount),
	dense_rank() over(order by sum(total_amount) desc) as rank
	from restaurants as rt
	join orders as o
		on rt.restaurant_id=o.restaurant_id
	WHERE 
	o.order_date BETWEEN '2023-01-01' AND '2023-12-31'
	group by 1,2,3 

-- Identify the most popular dish in each city based on the number of orders.
select * from 
	(select o.order_item,city, count(order_item),
	rank() over(partition by rt.city order by count(order_id) desc) as rank 
		from restaurants as rt
		join orders as o
			on rt.restaurant_id=o.restaurant_id
		group by 1,2
		order by 2)
		where rank = 1

-- Find customers who haven’t placed an order in 2024 but did in 2023.
select distinct customer_name
from customers as c
join orders as o 
	on o.customer_id=c.customer_id
 where extract(year from o.order_date) = 2023 
 
 except
	select distinct customer_name
	from customers as c
	join orders as o 
		on o.customer_id=c.customer_id
	 where extract(year from o.order_date) = 2024 
group by 1



-- Calculate each rider's total monthly earnings, assuming they earn 8% of the order amount.
select 
rider_id,
order_date,
sum(total_amount) as revenue,
sum(total_amount)*0.08 as riders_earning
from orders as o
join deliveries as d
	on o.order_id=d.order_id
group by 1,2
order by 1,2

-- Analyze order frequency per day of the week and identify the peak day for each restaurant.
select *from 
	(select 
	r.restaurant_name,
	to_char(o.order_date, 'Day')as day,
	count(o.order_id) as total_orders,
	rank() over(partition by r.restaurant_name order by count(o.order_id) desc)
	from orders as o
	Join restaurants as r
		on o.restaurant_id=r.restaurant_id
	group by 1,2
	order by 1,3 desc) as t1
	where rank=1;

-- Calculate the total revenue generated by each customer over all their orders.
SELECT 
	o.customer_id,
	c.customer_name,
	SUM(o.total_amount) as CLV
FROM orders as o
JOIN customers as c
ON o.customer_id = c.customer_id
GROUP BY 1, 2;

-- Identify sales trends by comparing each month's total sales to the previous month.
SELECT 
	EXTRACT(YEAR FROM order_date) as year,
	EXTRACT(MONTH FROM order_date) as month,
	SUM(total_amount) as total_sale,
	LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) as prev_month_sale
FROM orders
GROUP BY 1, 2;

-- Evaluate rider efficiency by determining average delivery times and identifying those with the lowest and highest averages.
WITH new_table
AS
(
	SELECT 
		*,
		d.rider_id as riders_id,
		EXTRACT(EPOCH FROM (d.delivery_time - o.order_time + 
		CASE WHEN d.delivery_time < o.order_time THEN INTERVAL '1 day' ELSE
		INTERVAL '0 day' END))/60 as time_deliver
	FROM orders as o
	JOIN deliveries as d
	ON o.order_id = d.order_id
	WHERE d.delivery_status = 'Delivered'
),

riders_time
AS

(
	SELECT 
		riders_id,
		AVG(time_deliver) avg_time
	FROM new_table
	GROUP BY 1
)
SELECT 
	MIN(avg_time),
	MAX(avg_time)
FROM riders_time;

--Track the popularity of specific order items over time and identify seasonal demand spikes.
SELECT 
	order_item,
	seasons,
	COUNT(order_id) as total_orders
FROM 
(
SELECT 
		*,
		EXTRACT(MONTH FROM order_date) as month,
		CASE 
			WHEN EXTRACT(MONTH FROM order_date) BETWEEN 4 AND 6 THEN 'Spring'
			WHEN EXTRACT(MONTH FROM order_date) > 6 AND 
			EXTRACT(MONTH FROM order_date) < 9 THEN 'Summer'
			ELSE 'Winter'
		END as seasons
	FROM orders
) as t1
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

--Rank each city based on the total revenue for last year 2023
SELECT 
	r.city,
	SUM(total_amount) as total_revenue,
	RANK() OVER(ORDER BY SUM(total_amount) DESC) as city_rank
FROM orders as o
JOIN
restaurants as r
ON o.restaurant_id = r.restaurant_id
GROUP BY 1;