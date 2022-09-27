CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');


-- data cleaning
-- 1. customer_orders table
Select *
From customer_orders;

Create temporary table customer_orders_clean 
Select order_id, customer_id, pizza_id, order_time,
(case when exclusions = '' then null
	  when exclusions = 'null' then null else exclusions end) as exclusions,
(case when extras = '' then null
	  when extras = 'null' then null else extras end) as extras
From customer_orders;

Select *
From customer_orders_clean; -- check if it's clean

-- 2. runner_orders table
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

Select *
From runner_orders_clean; -- check if it's clean

-- Start Analysis
-- Pizza Metrics
-- 1. How many pizzas were ordered?
Select pizza_id, count(pizza_id) as count
From customer_orders_clean
Group by 1 with rollup
Order by 1
;

-- 2. How many unique customer orders were made?
Select count(distinct order_id) as count
From customer_orders_clean
;

-- 3. How many successful orders were delivered by each runner?
Select runner_id, count(distinct order_id) as successful_orders
From runner_orders_clean
Where cancellation is null
Group by 1
Order by 1
;

-- 4. How many of each type of pizza was successfully delivered?
Select pizza_id, count(order_id) as pizza_delivered_count
From (
Select pizza_id, ro.order_id, count(ro.order_id) as delivered_count
From customer_orders_clean co
Left Join runner_orders_clean ro on co.order_id = ro.order_id
Where cancellation is null
Group by 1,2) temp
Group by 1
;

-- 5. What was the maximum number of pizzas delivered in a single order?
With cte as (
Select order_id, count(pizza_id) as pizzas, rank() over (order by count(pizza_id) desc) as rnk
From customer_orders_clean
Group by 1)

Select order_id, pizzas
From cte 
Where rnk = 1
;

-- 6. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
Select customer_id,
sum(case when exclusions is null and extras is null then 1 else 0 end) as order_wo_change,
sum(case when exclusions is not null or extras is not null then 1 else 0 end) order_change
From customer_orders_clean co
Join runner_orders_clean ro on co.order_id = ro.order_id
Where cancellation is null
Group by 1
;

-- 7. How many pizzas were delivered that had both exclusions and extras?
Select sum(case when exclusions is not null and extras is not null then 1 else 0 end) as order_with_exclusions_extras
From customer_orders_clean co
Join runner_orders_clean ro on co.order_id = ro.order_id
Where cancellation is null
;

-- 8. What was the total volume of pizzas ordered for each hour of the day?
With pizza_hr_vol as 
(Select *, hour(order_time) as hour_of_day
From customer_orders_clean)

Select hour_of_day, count(pizza_id) as pizza_volume
From pizza_hr_vol
Group by hour_of_day
Order by 1;

-- 9. What was the volume of orders for each day of the week?
With pizza_week_vol as 
(Select *, dayname(order_time) as day_of_week
From customer_orders_clean)

Select day_of_week, count(pizza_id) as pizza_volume_week
From pizza_week_vol
Group by 1
Order by 2 desc;


-- Runner and Customer Experience
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
Select week(registration_date) as registration_week, count(runner_id) as runners
From runners
Group by 1
Order by 1
;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
Select runner_id, round(avg(timestampdiff(minute, order_time, pickup_time)), 2) as avg_time_pickup_order
From customer_orders_clean co
Left Join runner_orders_clean ro on co.order_id = ro.order_id
Group by 1
Order by 1
;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
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

-- 4. What was the average distance travelled for each customer?
Select customer_id, round(avg(distance),2) as avg_dist
From customer_orders_clean c 
Join runner_orders_clean r on c.order_id = r.order_id
Group by 1
Order by 1
;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
Select max(duration) as max_duration, min(duration) as min_duration, 
(max(duration) - min(duration)) as difference_in_duration
From runner_orders_clean
Where cancellation is null;

-- 6. What was the average speed for each runner and do you notice any trend for these values?
Select runner_id, round(avg(duration/distance),2) as avg_speed
From runner_orders_clean
Where cancellation is null
Group by 1
Order by 1;

-- 7. What is the successful delivery percentage for each runner?
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

-- Pricing and Ratings
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes:
-- how much money has Pizza Runner made so far if there are no delivery fees?
With cal_price as (
Select pizza_id, (case when pizza_id = 1 then 12 else 10 end) as price
From customer_orders_clean)

Select pizza_name, sum(price) as pizza_price
From cal_price cp
Join pizza_names pn on cp.pizza_id = pn.pizza_id
Group by 1 with rollup
;

-- 2. What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
With cal_price_wh_extras as (
Select pizza_id, (case when pizza_id = 1 then 12 else 10 end) as price,
(case when extras like '%4%' then 1 else 0 end) as extras_price
From customer_orders_clean)

Select pizza_name, sum(price+extras_price) as pizza_price
From cal_price_wh_extras cpwe
Join pizza_names pn on cpwe.pizza_id = pn.pizza_id
Group by 1 with rollup
;




