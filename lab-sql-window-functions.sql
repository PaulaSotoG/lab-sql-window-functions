USE sakila;

-- This challenge consists of three exercises that will test your ability to use the SQL RANK() function. You will use it to rank films by their length, their length within the rating category, and by the actor or actress who has acted in the greatest number of films.
-- Rank films by their length and create an output table that includes the title, length, and rank columns only. Filter out any rows with null or zero values in the length column.

SELECT f.title, f.length, 
       RANK() OVER (ORDER BY f.length DESC) AS ranking
FROM sakila.film AS f
WHERE f.length IS NOT NULL AND f.length > 0;


-- Rank films by length within the rating category and create an output table that includes the title, length, rating and rank columns only. Filter out any rows with null or zero values in the length column.

SELECT f.title, f.length, f.rating, 
       RANK() OVER (PARTITION BY f.rating ORDER BY f.length DESC) AS ranking
FROM sakila.film AS f
WHERE f.length IS NOT NULL AND f.length > 0;


-- Produce a list that shows for each film in the Sakila database, the actor or actress who has acted in the greatest number of films, as well as the total number of films in which they have acted. Hint: Use temporary tables, CTEs, or Views when appropiate to simplify your queries.

WITH prolific_actor AS (
    SELECT fa.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS film_count
    FROM sakila.film_actor AS fa
    JOIN sakila.actor AS a ON fa.actor_id = a.actor_id
    GROUP BY fa.actor_id, a.first_name, a.last_name
    ORDER BY film_count DESC
    LIMIT 1
)
SELECT * FROM prolific_actor;


WITH prolific_actor AS (
    SELECT fa.actor_id, a.first_name, a.last_name, COUNT(fa.film_id) AS film_count
    FROM sakila.film_actor AS fa
    JOIN sakila.actor AS a ON fa.actor_id = a.actor_id
    GROUP BY fa.actor_id, a.first_name, a.last_name
    ORDER BY film_count DESC
    LIMIT 1
)
SELECT f.title, pa.first_name, pa.last_name, pa.film_count
FROM sakila.film AS f
JOIN sakila.film_actor AS fa ON f.film_id = fa.film_id
JOIN prolific_actor AS pa ON fa.actor_id = pa.actor_id;


-- This challenge involves analyzing customer activity and retention in the Sakila database to gain insight into business performance. By analyzing customer behavior over time, businesses can identify trends and make data-driven decisions to improve customer retention and increase revenue.
-- The goal of this exercise is to perform a comprehensive analysis of customer activity and retention by conducting an analysis on the monthly percentage change in the number of active customers and the number of retained customers. Use the Sakila database and progressively build queries to achieve the desired outcome.
-- Step 1. Retrieve the number of monthly active customers, i.e., the number of unique customers who rented a movie in each month.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM sakila.rental AS r
    GROUP BY rental_year, rental_month
)
SELECT * FROM monthly_active_customers
ORDER BY rental_year, rental_month;


-- Step 2. Retrieve the number of active users in the previous month.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM sakila.rental AS r
    GROUP BY rental_year, rental_month
)
SELECT *,
       LAG(active_customers, 1) OVER (ORDER BY rental_year, rental_month) AS previous_month_active
FROM monthly_active_customers
ORDER BY rental_year, rental_month;


-- Step 3. Calculate the percentage change in the number of active customers between the current and previous month.

WITH monthly_active_customers AS (
    SELECT 
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month,
        COUNT(DISTINCT r.customer_id) AS active_customers
    FROM sakila.rental AS r
    GROUP BY rental_year, rental_month
)
SELECT *,
       LAG(active_customers, 1) OVER (ORDER BY rental_year, rental_month) AS previous_month_active,
       CASE
           WHEN LAG(active_customers, 1) OVER (ORDER BY rental_year, rental_month) IS NULL THEN NULL
           ELSE ROUND(
               (active_customers - LAG(active_customers, 1) OVER (ORDER BY rental_year, rental_month)) * 100 /
               LAG(active_customers, 1) OVER (ORDER BY rental_year, rental_month), 2)
       END AS percentage_change
FROM monthly_active_customers
ORDER BY rental_year, rental_month;


-- Step 4. Calculate the number of retained customers every month, i.e., customers who rented movies in the current and previous months.

WITH rentals_by_month AS (
    SELECT 
        r.customer_id,
        YEAR(r.rental_date) AS rental_year,
        MONTH(r.rental_date) AS rental_month
    FROM sakila.rental AS r
    GROUP BY r.customer_id, rental_year, rental_month
),
retained_customers AS (
    SELECT 
        current_month.rental_year,
        current_month.rental_month,
        COUNT(DISTINCT current_month.customer_id) AS retained_customers
    FROM rentals_by_month AS current_month
    JOIN rentals_by_month AS previous_month
      ON current_month.customer_id = previous_month.customer_id
      AND (current_month.rental_year = previous_month.rental_year AND current_month.rental_month = previous_month.rental_month + 1
          OR current_month.rental_year = previous_month.rental_year + 1 AND current_month.rental_month = 1 AND previous_month.rental_month = 12)
    GROUP BY current_month.rental_year, current_month.rental_month
)
SELECT * FROM retained_customers
ORDER BY rental_year, rental_month;


