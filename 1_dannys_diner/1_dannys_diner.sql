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
Select customer_id, count(distinct order_date) as total_days_visited
From sales
Group by 1
Order by 1
;

-- 3. What was the first item from the menu purchased by each customer?
-- By looking at the first item each customer ordered, we are able to tell which menu item is more attractive for first visiting.
With cte as (
Select customer_id, product_id, dense_rank() over (partition by customer_id order by order_date) as first_item
From sales)

Select distinct customer_id, product_name
From cte
Join menu As m on cte.product_id = m.product_id
Where cte.first_item = 1
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

-- 8. What is the total items and amount spent for each member before they became a member?
With cte as
(select s.customer_id, product_id, order_date
From sales s 
Join members ms on s.customer_id = ms.customer_id
Where s.order_date < ms.join_date)

Select customer_id, count(product_name) as total_items, sum(price) as total_price
From cte 
Join menu m on cte.product_id = m.product_id
group by cte.customer_id
order by 1
;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
with cte as
(Select s.customer_id, s.product_id, m.price, m.product_name,
(case 
	when product_name in ('curry','ramen') then price*10
    else price*20
end) as points
From sales s 
Join menu m on s.product_id = m.product_id)

Select customer_id, sum(points) as total_points
From cte
Group by 1
;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
with cte as
(Select s.customer_id, order_date, product_id, join_date
From sales s 
Join members m on s.customer_id = m.customer_id),
cte2 as
(select customer_id, order_date, product_name, price,join_date,
case 
	when product_name = 'sushi' then price*20
	when datediff(order_date,join_date) <= 6 and datediff(order_date,join_date) >= 0 then price*20
    when datediff(order_date,join_date) >= 7 and product_name in ('curry','ramen') then price*10
    when datediff(order_date,join_date) < 0 then price*10
	else price*10
end as total_points
from cte
join menu m on cte.product_id = m.product_id
order by 1)

select customer_id, sum(total_points)
from cte2 
where order_date < '2021-02-01'
group by 1;
