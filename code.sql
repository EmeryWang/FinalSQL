-- input the data

DROP TABLE interest_rate；

CREATE TABLE interest_rate (
	date_1 date PRIMARY KEY,
	interest_3 numeric
)

SELECT * FROM interest_rate;

DROP TABLE prices;

CREATE TABLE prices (
	date_2 date PRIMARY KEY,
	corn_future numeric,
	corn_spot numeric,
	corn_long numeric,
	soy_future numeric,
	soy_spot numeric,
	soy_long numeric,
	corn_short numeric,
	soy_short numeric,
	net_corn numeric,
	net_soy numeric
);

SELECT * FROM prices;

-- Basic discovery

-- Corn & Soy
SELECT
	MAX(corn_spot),
	MIN(corn_spot),
	AVG(corn_spot),
	STDDEV(corn_spot) AS volatility
FROM prices
WHERE date_2 < '2014/1/1' and date_2 > '2010/1/1';

SELECT
	MAX(soy_spot),
	MIN(soy_spot),
	AVG(soy_spot),
	STDDEV(soy_spot) AS volatility
FROM prices
WHERE date_2 > '2014/1/1';

-- Corn vs. Soy

SELECT
	date_2,
	corn_spot,
	soy_spot,
	corn_future,
	soy_future
FROM prices
ORDER BY 5;

SELECT 
	CORR(corn_spot, soy_spot) AS correlation_spot,
	CORR(corn_future,soy_future) AS correlation_future,
	CORR(corn_spot, soy_spot)-CORR(corn_future,soy_future) AS difference
FROM prices;

SELECT 
	CORR(corn_spot_average, soy_spot_average) AS correlation_spot,
	CORR(corn_future_average,soy_future_average) AS correlation_future,
	CORR(corn_spot_average, soy_spot_average)-CORR(corn_future_average,soy_future_average) AS difference
FROM (
SELECT
  EXTRACT(MONTH FROM date_2) AS month,
  EXTRACT(YEAR FROM date_2) AS year,
  AVG(corn_spot) AS corn_spot_average,
  AVG(corn_future) AS corn_future_average,
  AVG(soy_spot) AS soy_spot_average,
  AVG(soy_future) AS soy_future_average
FROM prices
GROUP BY year, month
ORDER BY year, month);


SELECT 
	CORR(postponed_corn_spot, soy_spot_average) AS correlation_spot,
	CORR(postponed_corn_future,soy_future_average) AS correlation_future
FROM (
	SELECT
		LAG(corn_spot_average,4) OVER (ORDER BY month) AS postponed_corn_spot,
		LAG(corn_future_average,4) OVER (ORDER BY month) AS postponed_corn_future,
		corn_spot_average,
		corn_future_average,
		soy_spot_average,
		soy_future_average
	FROM (
		SELECT
  			EXTRACT(MONTH FROM date_2) AS month,
  			EXTRACT(YEAR FROM date_2) AS year,
  			AVG(corn_spot) AS corn_spot_average,
  			AVG(corn_future) AS corn_future_average,
  			AVG(soy_spot) AS soy_spot_average,
  			AVG(soy_future) AS soy_future_average
		FROM prices
		GROUP BY year, month
		ORDER BY year, month)
);

-- Spots vs. Future
	
SELECT
    AVG((soy_future - soy_spot)/soy_spot) AS soy_difference,
    AVG((corn_future - corn_spot)/corn_spot) AS corn_difference
FROM prices
WHERE date_2 > '2014/1/1';


SELECT
	CORR(soy_spot,soy_future),
	CORR(corn_spot,corn_future)
FROM prices;

SELECT count(*)
FROM prices;

SELECT count(*)
FROM prices
WHERE  (soy_future - soy_spot) < 0;


SELECT
  COUNT(*) FILTER (WHERE date_2 < '2008-01-01') AS num_1,
  COUNT(*) FILTER (WHERE date_2 < '2010-01-01' AND date_2 >= '2008-01-01') AS num_2,
  COUNT(*) FILTER (WHERE date_2 < '2014-01-01' AND date_2 >= '2010-01-01') AS num_3,
  COUNT(*) FILTER (WHERE date_2 >= '2014-01-01') AS num_4
FROM prices
WHERE (soy_future - soy_spot) < 0;

-- futures vs. short position
SELECT
	date_2,
	corn_spot,
	corn_future
FROM prices
WHERE corn_spot > corn_future;


SELECT
	AVG(net_corn),
	AVG(corn_long),
	AVG(corn_short),
	STDDEV(corn_future)
FROM prices
WHERE corn_spot > corn_future;

SELECT
	AVG(net_corn),
	AVG(corn_long),
	AVG(corn_short),
	STDDEV(corn_future)
FROM prices
WHERE corn_spot < corn_future AND (date_2 > '2011/5/1' AND date_2 < '2015/1/1');

SELECT
	date_2,
	soy_future,
	soy_spot
FROM prices
WHERE soy_spot > soy_future

SELECT
	AVG(net_soy),
	AVG(soy_long),
	AVG(soy_short),
	STDDEV(soy_future)
FROM prices
WHERE soy_spot < soy_future;

SELECT
	AVG(net_corn),
	AVG(corn_long),
	AVG(corn_short),
	STDDEV(corn_future)
FROM prices
WHERE corn_spot < corn_future


-- Free Arbitrage Model
-- F0 = S0*ert
SELECT *
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1;



SELECT
	date,
	(cal_corn_future - corn_future) AS corn_dif,
	(cal_soy_future - soy_future) AS soy_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1);


SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif > 0.05 and corn_percent_dif > 0.05;




SELECT
	COUNT(*) FILTER (WHERE date < '2008-01-01') AS num_1,
	COUNT(*) FILTER (WHERE date < '2010-01-01' AND date >= '2008-01-01') AS num_2,
	COUNT(*) FILTER (WHERE date < '2014-01-01' AND date >= '2010-01-01') AS num_3,
	COUNT(*) FILTER (WHERE date >= '2014-01-01') AS num_4
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif < -0.05 or corn_percent_dif > 0.05;

SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_soy_future - soy_future)/soy_future) AS soy_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE soy_percent_dif > 0.05 and soy_percent_dif < 0.05;

SELECT
	COUNT(*) FILTER (WHERE date < '2008-01-01') AS num_1,
	COUNT(*) FILTER (WHERE date < '2010-01-01' AND date >= '2008-01-01') AS num_2,
	COUNT(*) FILTER (WHERE date < '2014-01-01' AND date >= '2010-01-01') AS num_3,
	COUNT(*) FILTER (WHERE date >= '2014-01-01') AS num_4
FROM (
SELECT
	date,
	((cal_soy_future - soy_future)/soy_future) AS soy_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE soy_percent_dif < -0.05 or soy_percent_dif > 0.05;

-- Adjustment 1 No-shorting
SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif < -0.05;

SELECT
	date,
	soy_future,
	soy_percent_dif
FROM (
SELECT
	date,
	soy_future,
	((cal_soy_future - soy_future)/soy_future) AS soy_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 3/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE soy_percent_dif < -0.05;

-- Adjustment 2: T=3? 
-- t=4
SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 21/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 21/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif > 0.05 and corn_percent_dif < -0.05;


SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_soy_future - soy_future)/soy_future) AS soy_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	(table1.corn_spot * EXP(table2.interest_3/100 * 16/12)) AS cal_corn_future,
	table1.soy_future AS soy_future,
	(table1.soy_spot * EXP(table2.interest_3/100 * 16/12)) AS cal_soy_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE soy_percent_dif > -0.05 and soy_percent_dif < 0.05;


-- Adjustement 3 storage costs

SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	((table1.corn_spot * (1 + 0.15*3/12)) * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif > 0.05 OR corn_percent_dif < -0.05;

-- all together, corn

-- no shorting. 1

SELECT
	COUNT(*)
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	((table1.corn_spot * (1 + 0.16*3/12)) * EXP(table2.interest_3/100 * 3/12)) AS cal_corn_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif < -0.05;
	
SELECT
	date,
	corn_percent_dif
FROM (
SELECT
	date,
	((cal_corn_future - corn_future)/corn_future) AS corn_percent_dif
FROM (
SELECT 
	table1.date_2 AS date,
	table1.corn_future AS corn_future,
	((table1.corn_spot * (1 + 0.2*3/12)) * EXP(table2.interest_3/100 * 5/12)) AS cal_corn_future
FROM prices AS table1
JOIN interest_rate AS table2 ON table1.date_2 = table2.date_1))
WHERE corn_percent_dif < -0.05;


