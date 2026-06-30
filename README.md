# 🍽️ Zomato - Food Delivery Analytics SQL Project

## Overview

This project is a comprehensive **SQL-based data analysis system** built for a food delivery platform. It models real-world operations such as customers placing orders, restaurants fulfilling them, riders delivering orders, and revenue tracking.

The goal is to demonstrate strong SQL skills including:

* Data modeling
* Data cleaning
* Aggregations
* Window functions
* Time-based analysis
* Business insights generation

---


## Data Cleaning & Validation

* Checked NULL values across all tables
* Identified missing or inconsistent records
* Removed invalid delivery records where required

---

##  Key SQL Analyses Performed

### Customer Analysis

* Customers who are inactive in 2024 but active in 2023
* Top spending customers (Customer Lifetime Value)
* Average Order Value (AOV) for high-frequency customers

###  Restaurant Analysis

* Top restaurants by revenue
* Most popular dishes by city
* City-wise revenue ranking

###  Time-Based Analysis

* Peak ordering time slots (2-hour intervals)
* Sales trends month-over-month
* Day-of-week ordering behavior per restaurant

###  Rider Performance

* Total earnings (8% commission model)
* Average delivery time per rider
* Best and worst performing riders

###  Delivery Insights

* Undelivered orders analysis
* Delivery status tracking

### Advanced Analytics

* Seasonal demand trends for menu items
* Revenue ranking within cities
* Window functions (RANK, DENSE_RANK, LAG)

---

##  Key Insights

* Certain 2-hour time slots dominate order volume, indicating peak demand hours.
* A small percentage of customers contribute to majority of revenue.
* Restaurant performance varies significantly by city.
* Rider efficiency can be measured effectively using delivery time calculations.
* Seasonal trends impact food item popularity.

---

##  Technologies Used

* SQL (PostgreSQL syntax)
* Window Functions
* Joins & Subqueries
* Aggregations
* Date/Time Functions

----------------------------------------------

## Database Schema

### Customers Table
- Stores customer details and registration date

### Restaurants Table
- Stores restaurant information including city and opening hours

### Orders Table
- Stores all food orders with item, time, status, and amount

### Riders Table
- Stores delivery riders information

### Deliveries Table
- Tracks delivery status and assigned riders


---

# 📁 Repository Name

**food-delivery-sql-analysis**

---

# 📄 README.md (GitHub Content)

````md
# 🍔 Food Delivery SQL Analysis Project

This project simulates a **food delivery platform database** and performs real-world SQL analytics such as customer behavior, revenue trends, delivery performance, and restaurant insights.

---

## 🗄️ Database Schema

### Customers Table
- Stores customer details and registration date

### Restaurants Table
- Stores restaurant information including city and opening hours

### Orders Table
- Stores all food orders with item, time, status, and amount

### Riders Table
- Stores delivery riders information

### Deliveries Table
- Tracks delivery status and assigned riders

---

## 🧱 SQL Schema

```sql
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
````

---

##  Data Cleaning Queries

```sql
select count(*) from customers
where reg_date is null;

select count(*) from restaurants
where restaurant_name is null
or city is null
or opening_hours is null;

select count(*) from orders
where order_item is null
or order_date is null
or order_time is null
or order_status is null
or total_amount is null;

select count(*) from riders
where rider_id is null
or rider_name is null
or sign_up is null;

delete from deliveries
where delivery_status is null
or delivery_time is null;
```

---

##  SQL Analytics & Business Insights

###  Top Orders by Customer (Arjun Mehta)

```sql
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
where rank<=5;
```

---

###  Peak Order Time Slots (2-Hour Intervals)

```sql
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
count(order_id) as order_count
from orders
group by time_slot
order by order_count desc;
```

---

###  High Value Customers (>100K Spend)

```sql
select customer_name ,total_spent
from 
(
	select c.customer_id, c.customer_name, sum(total_amount) as total_spent
	from orders as o
	join customers as c
	on o.customer_id=c.customer_id
	group by 1,2
	order by total_spent
) as t1
where total_spent>100000;
```

---

### Not Delivered Orders by Restaurant

```sql
select restaurant_name, city,count(*) as no_ofnotdeliveredorders
from restaurants as rt
join orders as o
	on o.restaurant_id=rt.restaurant_id
join deliveries as d
	on o.order_id=d.order_id
where delivery_status ='Not Delivered'
group by restaurant_name,city;
```

---

###  City Wise Revenue Ranking

```sql
select r.city,
sum(total_amount) as total_revenue,
rank() over(order by sum(total_amount) desc) as city_rank
from orders o
join restaurants r
on o.restaurant_id = r.restaurant_id
group by r.city;
```

---

###  Monthly Sales Trend (LAG Analysis)

```sql
SELECT 
	EXTRACT(YEAR FROM order_date) as year,
	EXTRACT(MONTH FROM order_date) as month,
	SUM(total_amount) as total_sale,
	LAG(SUM(total_amount), 1) OVER(ORDER BY EXTRACT(YEAR FROM order_date), EXTRACT(MONTH FROM order_date)) as prev_month_sale
FROM orders
GROUP BY 1, 2;
```


