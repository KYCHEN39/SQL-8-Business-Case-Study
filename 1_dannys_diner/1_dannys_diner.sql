CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?
Select customer_id, sum(price) As total_amount
From sales As s
Left Join menu As m on s.product_id = m.product_id
Group by 1
Order by 1
;

-- 2. How many days has each customer visited the restaurant?
-- From 1 and 2, we can see the visiting pattern of each customer. Customer A and B more loyal to Danny's.
Select customer_id, count(order_date) as total_days_visited
From sales
Group by 1
Order by 1
;

-- 3. What was the first item from the menu purchased by each customer?
-- By looking at the first item each customer ordered, we are able to tell which menu item is more attractive for first visiting.
With cte as (
Select customer_id, product_name, row_number() over (partition by customer_id order by order_date) as first_item
From sales As s
Left Join menu As m on s.product_id = m.product_id
Order by 1)

Select customer_id, product_name
From cte
Where first_item = 1
Order by 1
;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- We can see which menu item is the most popular for further marketing campaign.
With cte as (
Select product_name, rank() over (order by count(s.product_id) desc) as rnk, count(s.product_id) as purchased_time
From sales As s
Left Join menu As m on s.product_id = m.product_id
Group by 1)

Select product_name, purchased_time
From cte
Where rnk = 1
;

-- 5. Which item was the most popular for each customer?
-- Since we analyzed who are more loyal to Danny's, we can further look at their favorites.
With cte as (
Select customer_id, product_id, count(product_id) as cnt, rank() over (partition by customer_id order by count(product_id) desc) as rnk
From sales
group by 1,2)

Select customer_id, product_name
From cte c
Left Join menu As m on c.product_id = m.product_id
Where rnk = 1
;

-- 6. Which item was purchased first by the customer after they became a member?
With cte as (
Select s.customer_id, product_id, case when order_date > join_date then order_date end as member_purchase, rank() over (partition by s.customer_id order by order_date) as rnk
From members as ms
Join sales as s on ms.customer_id = s.customer_id
Where case when order_date > join_date then order_date end is not null)

Select customer_id, product_name
From cte c
Join menu m on c.product_id = m.product_id
Where rnk = 1
Order by 1
;

-- 7. Which item was purchased just before the customer became a member?
With cte as (
Select s.customer_id, product_id, case when order_date < join_date then order_date end as purchase, rank() over (partition by s.customer_id order by order_date desc) as rnk
From members as ms
Join sales as s on ms.customer_id = s.customer_id
Where case when order_date < join_date then order_date end is not null)

Select customer_id, product_name
From cte c
Join menu m on c.product_id = m.product_id
Where rnk = 1
Order by 1
;
