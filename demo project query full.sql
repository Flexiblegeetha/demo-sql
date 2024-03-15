


CREATE TABLE sales(
"customer_id" VARCHAR(1),
"product_id" INTEGER,
"order_date" DATE,
"order_id" INTEGER
);


INSERT INTO sales
	("customer_id", "product_id", "order_date", "order_id")
VALUES
	('A', '1', '2020-05-04','10'),
	('A', '1', '2020-05-01','20'),
	('A', '4', '2020-05-02','30'),
	('A', '3', '2020-05-02','40'),
	('B', '1', '2021-06-05','50'),
	('B', '3', '2021-06-04','50'),
	('B', '4', '2021-06-06','50'),
	('B', '2', '2021-06-04','40'),
	('C', '1', '2020-04-01','40'),
	('C', '1', '2020-06-02','30'),
	('C', '1', '2020-04-03','20'),
	('C', '3', '2020-01-04','10'),
	('D', '1', '2021-05-10','20'),
	('D', '3', '2021-02-09','10'),
	('D', '2', '2021-05-11','30'),
	('D', '4', '2021-03-12','60');


CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(100),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '800'),
  ('2', 'ramen', '250'),
  ('4', 'noodles', '400'),
  ('3', 'curry', '500');
  


CREATE TABLE members(
"customer_id" VARCHAR(6),
"join_date" DATE
);

INSERT INTO members
	("customer_id", "join_date")
VALUES
	('A', '2020-05-04'),
	('B', '2021-03-12'),
	('C', '2020-06-02'),
	('D', '2021-02-09');






--1. What is the total amount each customer spent at the restaurtant?
--	For this need custome_id as well as price cloumn . the customer_id is in there will take it from sales clounmand then the amount that each customer spent which is the price
-- will be from themenus statement .


SELECT  s.customer_id, SUM(m.price) AS total_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id;

--2. How many days has each customer visited the restaurtant?

SELECT s.customer_id, COUNT(DISTINCT s.order_date) AS visited_days
FROM sales s
GROUP BY s.customer_id;

--3. What was the first item from the menu purchased by each customer?

WITH customers_first_purchase AS (
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	GROUP BY s.customer_id
)
SELECT cfp.customer_id, cfp.first_purchase_date, m.product_name
FROM customers_first_purchase cfp
JOIN sales s ON s.customer_id = cfp.customer_id
AND cfp.first_purchase_date = s.order_date
JOIN menu m ON m.product_id = s.product_id;


--4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1 m.product_name, COUNT(*) AS total_purchase
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY total_purchase DESC;

--5. Which item was the most popular for each customer?

WITH popular_dish AS(
	SELECT s.customer_id, m.product_name, COUNT (*) AS count_purcahse,
	DENSE_RANK () OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS rank
	FROM sales s
	JOIN menu m ON s.product_id = m.product_id
	GROUP BY s.customer_id, m.product_name
)
SELECT cp.customer_id, cp.product_name, cp.count_purcahse
FROM popular_dish cp
WHERE rank=1;



--6. Which item was purchased first by customer after they became a member?

WITH membership_after_first_purchase AS (
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	JOIN members mb ON s.customer_id = mb.customer_id
	WHERE s.order_date >= mb.join_date
	GROUP BY s.customer_id
)
SELECT mafp.customer_id, m.product_name
FROM  membership_after_first_purchase mafp
JOIN sales s ON s.customer_id = mafp.customer_id
AND mafp.first_purchase_date = s.order_date
JOIN menu m ON s.product_id= m.product_id;

--7. Which item was purchased just before the customer became a member?


WITH last_purchase_before_membership AS(
	SELECT s.customer_id, MAX(s.order_date) AS last_purchase_date
	FROM sales s
	JOIN members mb ON s.customer_id = mb.customer_id
	WHERE s.order_date < mb.join_date
	GROUP BY s.customer_id
)
SELECT lpbm.customer_id, m.product_name
FROM last_purchase_before_membership lpbm
JOIN sales s ON lpbm.customer_id = s.customer_id
AND lpbm.last_purchase_date = s.order_date
JOIN menu m ON s.product_id= m.product_id;

--8. What is the total items and amount for each member before they became?

SELECT s.customer_id, COUNT(*) AS total_items, SUM (m.price) AS total_spent
FROM sales s 
JOIN menu m ON s.product_id = m.product_id
JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiple - how many points would each customer have?

SELECT s.customer_id, SUM(
	CASE
		WHEN m.product_name = 'sushi' THEN m.price*20
		ELSE m.price*10 END) AS total_purchase
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
how many points do customer A and B have at the end of January?*/

SELECT s.customer_id, SUM(
	CASE
		WHEN s.order_date BETWEEN mb.join_date AND DATEADD(day, 7, mb.join_date)
		THEN m.price*20
		WHEN m.product_name = 'sushi' THEN m.price*20
		ELSE m.price*10 END) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.customer_id IN ('A', 'B', 'C') AND s.order_date <= '2021-06-04'
GROUP BY s.customer_id ;


--11. Recreate the table output using the available data?

SElECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN s.order_date >= mb.join_date THEN 'Y'
ELSE 'N' END AS member
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
ORDER BY s.customer_id, s.order_date;

--12. Rank all the things?

WITH customers_data AS(
	SELECT s.customer_id, s.order_date, m.product_name, m.price,
	CASE
		WHEN s.order_date < mb.join_date THEN 'N'
		WHEN s.order_date >= mb.join_date THEN 'Y'
		ELSE 'N' END AS member
	FROM sales s
	LEFT JOIN members mb ON s.customer_id = mb.customer_id
	JOIN menu m ON s.product_id = m.product_id
)
SELECT *,
CASE WHEN member = 'N' THEN NULL 
ELSE RANK() OVER(PARTITION BY customer_id, member ORDER BY order_date)
END AS rankingee
FROM customers_data
ORDER BY customer_id, order_date;
