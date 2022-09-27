h1 align="center">CASE STUDY #2 - Pizza Runner</h1>

## Introduction
Did you know that over 115 million kilograms of pizza is consumed daily worldwide??? (Well according to Wikipedia anyway…)

Danny was scrolling through his Instagram feed when something really caught his eye - “80s Retro Styling and Pizza Is The Future!”

Danny was sold on the idea, but he knew that pizza alone was not going to help him get seed funding to expand his new Pizza Empire - so he had one more genius idea to combine with it - he was going to Uberize it - and so Pizza Runner was launched!

Danny started by recruiting “runners” to deliver fresh pizza from Pizza Runner Headquarters (otherwise known as Danny’s house) and also maxed out his credit card to pay freelance developers to build a mobile app to accept orders from customers.

## Problem Statement
Danny has prepared for us an entity relationship diagram of his database design but requires further assistance to clean his data and apply some basic calculations so he can better direct his runners and optimise Pizza Runner’s operations.

## Entity Relationship Diagram
All datasets exist within the pizza_runner database schema.
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/entity%20for%20case%20study%202.png" />

## Data Cleaning
The data has some issues which need to be tackled before it can be used to answer the questions of the case study. 
#### customer_orders

Before
The columns 'exclusions' and 'extras' have values such as 'null' and 'Nan' which need to cleaned and replaced with actual null values. All blanks have been cleaned and replaced with actual null values.
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/dc1%20before.png" />

After
```sql
Select *
From customer_orders;

Create temporary table customer_orders_clean 
Select order_id, customer_id, pizza_id, order_time,
(case when exclusions = '' then null
	  when exclusions = 'null' then null else exclusions end) as exclusions,
(case when extras = '' then null
	  when extras = 'null' then null else extras end) as extras
From customer_orders
; 
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/dc1%20after.png" />

#### runner_orders

Before
The columns 'distance' and 'duration' have mixed values with words 'km', 'minutes' and 'mins' which need to be cleared out. The column 'cancellation' has issues as well and as a result this column needs to be standardised too.
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/dc2%20before.png" />

After
```sql
Select *
From runner_orders;

Drop table runner_orders_clean;
CREATE TEMPORARY TABLE runner_orders_clean
Select order_id, runner_id, 
(case when pickup_time is null or pickup_time like 'null' then null 
	  else pickup_time end) pickup_time,
(case when distance is null or distance like 'null' THEN null
	  when distance like '%km' THEN TRIM('km' from distance) 
	  else distance end) distance,
(case when duration is null or duration like 'null' THEN null 
	  when duration like '%mins' then TRIM('mins' from duration) 
	  when duration like '%minute' then TRIM('minute' from duration)        
	  when duration like '%minutes' then TRIM('minutes' from duration)       
	  else duration end) duration,
(case when cancellation = '' or cancellation like 'null' THEN null
	  else cancellation end) cancellation
from runner_orders;
; 
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/dc2%20after.png" />

## Case Study Questions and Solutions

#### Pizza Metrics - by analyzing orders, we are able to understand the popular month/day, which types of pizza are more popular, customers flavor toward exclusions and extras, etc.
#### 1. How many pizzas were ordered?
```sql
Select pizza_id, count(pizza_id) as count
From customer_orders_clean
Group by 1 with rollup
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q1.pngg" />

#### 2. How many unique customer orders were made?
```sql
Select count(distinct order_id) as count
From customer_orders_clean
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q2.png" />

#### 3. How many successful orders were delivered by each runner?
```sql
Select runner_id, count(distinct order_id) as successful_orders
From runner_orders_clean
Where cancellation is null
Group by 1
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q3.png" />

#### 4. How many of each type of pizza was successfully delivered?
```sql
Select pizza_id, count(order_id) as pizza_delivered_count
From (
Select pizza_id, ro.order_id, count(ro.order_id) as delivered_count
From customer_orders_clean co
Left Join runner_orders_clean ro on co.order_id = ro.order_id
Where cancellation is null
Group by 1,2) temp
Group by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q4.png" />

#### 5. What was the maximum number of pizzas delivered in a single order?
```sql
With cte as (
Select order_id, count(pizza_id) as pizzas, rank() over (order by count(pizza_id) desc) as rnk
From customer_orders_clean
Group by 1)

Select order_id, pizzas
From cte 
Where rnk = 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q5.png" />

#### 6. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
```sql
Select customer_id,
sum(case when exclusions is null and extras is null then 1 else 0 end) as order_wo_change,
sum(case when exclusions is not null or extras is not null then 1 else 0 end) order_change
From customer_orders_clean co
Join runner_orders_clean ro on co.order_id = ro.order_id
Where cancellation is null
Group by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q6.png" />

#### 7. How many pizzas were delivered that had both exclusions and extras?
```sql
Select sum(case when exclusions is not null and extras is not null then 1 else 0 end) as order_with_exclusions_extras
From customer_orders_clean co
Join runner_orders_clean ro on co.order_id = ro.order_id
Where cancellation is null
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q7.png" />

#### 8. What was the total volume of pizzas ordered for each hour of the day?
```sql
With pizza_hr_vol as 
(Select *, hour(order_time) as hour_of_day
From customer_orders_clean)

Select hour_of_day, count(pizza_id) as pizza_volume
From pizza_hr_vol
Group by hour_of_day
Order by 1;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q8.png" />

#### 9. What was the volume of orders for each day of the week?
```sql
With pizza_week_vol as 
(Select *, dayname(order_time) as day_of_week
From customer_orders_clean)

Select day_of_week, count(pizza_id) as pizza_volume_week
From pizza_week_vol
Group by 1
Order by 2 desc;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/A%20q9.png" />


#### Runner and Customer Experience - by analyzing orders, we are able to understand the customer experience with runner and the delivery service.
#### 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
```sql
Select week(registration_date) as registration_week, count(runner_id) as runners
From runners
Group by 1
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q1.png" />

#### 2.  What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
```sql
Select runner_id, round(avg(timestampdiff(minute, order_time, pickup_time)), 2) as avg_time_pickup_order
From customer_orders_clean co
Left Join runner_orders_clean ro on co.order_id = ro.order_id
Group by 1
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q2.png" />

#### 3.  Is there any relationship between the number of pizzas and how long the order takes to prepare?
```sql
With pizza_ord_prep as
(Select c.order_id, count(c.pizza_id) over (partition by c.order_id) as num_of_pizza,
round(timestampdiff(minute, c.order_time, r.pickup_time),2) as mins
From customer_orders_clean c 
Join runner_orders_clean r on c.order_id = r.order_id
Where r.cancellation is null)

Select num_of_pizza, round(avg(mins),2) as avg_prep_time
From pizza_ord_prep
Group by num_of_pizza
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q3.png" />

#### 4. What was the average distance travelled for each customer?
```sql
Select customer_id, round(avg(distance),2) as avg_dist
From customer_orders_clean c 
Join runner_orders_clean r on c.order_id = r.order_id
Group by 1
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q4.png" />

#### 5. What was the difference between the longest and shortest delivery times for all orders?
```sql
Select max(duration) as max_duration, min(duration) as min_duration,
(max(duration) - min(duration)) as difference_in_duration
From runner_orders_clean
Where cancellation is null;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q5.png" />

#### 6. What was the average speed for each runner and do you notice any trend for these values?
```sql
Select runner_id, round(avg(duration/distance),2) as avg_speed
From runner_orders_clean
Where cancellation is null
Group by 1
Order by 1;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q6.png" />

#### 7. What is the successful delivery percentage for each runner?
```sql
With total as (
Select runner_id, count(order_id) as total_orders
From runner_orders
Group by 1),

success as (
Select runner_id, count(order_id) as successful_orders
From runner_orders_clean
Where cancellation is null
Group by 1)

Select t.runner_id, total_orders, successful_orders, round((successful_orders/total_orders)*100,2) as successful_delivery_percentage
From total t
Join success s on t.runner_id = s.runner_id
Order by 1
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/B%20q7.png" />


#### Pricing and Ratings - by analyzing the pricing, we are able to understand the profit and the cost.
#### 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes: how much money has Pizza Runner made so far if there are no delivery fees?
```sql
With cal_price as (
Select pizza_id, (case when pizza_id = 1 then 12 else 10 end) as price
From customer_orders_clean)

Select pizza_name, sum(price) as pizza_price
From cal_price cp
Join pizza_names pn on cp.pizza_id = pn.pizza_id
Group by 1 with rollup
;
```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/D%20q1.png" />

#### 2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
```sql
With cal_price_wh_extras as (
Select pizza_id, (case when pizza_id = 1 then 12 else 10 end) as price,
(case when extras like '%4%' then 1 else 0 end) as extras_price
From customer_orders_clean)

Select pizza_name, sum(price+extras_price) as pizza_price
From cal_price_wh_extras cpwe
Join pizza_names pn on cpwe.pizza_id = pn.pizza_id
Group by 1 with rollup
;

```
<img src = "https://github.com/KYCHEN39/SQL-8-Business-Case-Study/blob/main/2_pizza_runner/image%20for%20case%20study%202/D%20q2.png" />