/* This file contains Teradata SQL queries used for the "Managing Big Data with
   MySQL" [sic] course on Coursera. This is organied to be best used store queries
   for my reference during the quiz (not intended to be used in this manner by future students). */

/* WEEK ENDING 20180429 */

=== Counts distinct dates in the database for each month in each year ===
SELECT EXTRACT(YEAR FROM saledate) AS Year_Num, EXTRACT(MONTH FROM saledate) AS Month_Num, 
       COUNT(DISTINCT saledate) AS Date_Count
FROM trnsact
GROUP BY Year_Num, Month_Num
ORDER BY Year_Num ASC, Month_Num ASC;
--- Same as above but excludes Aug 2005 data ---
SELECT EXTRACT(YEAR FROM saledate) AS Year_Num, EXTRACT(MONTH FROM saledate) AS Month_Num, COUNT(DISTINCT saledate) AS Date_Count,
       CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
       ELSE 'Include'
       END AS Exclusion
FROM trnsact
WHERE Exclusion = 'Include'
GROUP BY Year_Num, Month_Num
ORDER BY Year_Num ASC, Month_Num ASC;

--- This sorts total summer sales by SKU ---

SELECT TOP 10 SUM(CASE WHEN EXTRACT(MONTH from saledate) IN (6,7,8) THEN sprice 
                  END) AS sum_sprice, sku
FROM trnsact
WHERE stype = 'P'
GROUP BY sku
ORDER BY sum_sprice DESC;
/* Verified fifth highest SKU price matches instructor's value. */

--- Find days with sale by store, year, month ---

SELECT store, EXTRACT(YEAR FROM saledate) AS Year_Num, EXTRACT(MONTH FROM saledate) AS Month_Num, 
       COUNT(DISTINCT saledate) AS days_with_sale
FROM trnsact
GROUP BY store, Year_Num, Month_Num
ORDER BY days_with_sale ASC;
/* Verified that there are few stores that had 1 day with a sale in a month,
   there were also few stores that had less than the total number of days in a month with a sale. */

--- Calculate average daily revenue of the above ---

SELECT store, EXTRACT(YEAR FROM saledate) AS Year_Num, EXTRACT(MONTH FROM saledate) 
       AS Month_Num, COUNT(DISTINCT saledate) AS days_with_sale, 
       SUM(sprice)/COUNT(DISTINCT saledate) AS average_daily_revenue
FROM trnsact
WHERE stype = 'P'
GROUP BY store, Year_Num, Month_Num
ORDER BY average_daily_revenue DESC;
/* Added WHERE stype = 'P' so returns are not counted as revenue
   Verified that store #204 has an avg daily sale price of $16303.65 in Aug 2005 */

SELECT t.store AS t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, EXTRACT(MONTH FROM t.saledate) 
       AS Month_Num, COUNT(DISTINCT t.saledate) AS days_with_sale, 
       SUM(t.sprice)/COUNT(DISTINCT t.saledate) AS average_daily_revenue,
       CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
            WHEN days_with_sale < 20 THEN 'Exclude'
       ELSE 'Include'
       END AS Exclusion
FROM trnsact t
WHERE t.stype = 'P'
GROUP BY t_store, Year_Num, Month_Num
ORDER BY days_with_sale ASC;
/* Sets exclude flag for approprate combinations. Attempted concatenate function but
   couldn't get it to work properly in CASE statement or WHERE statement, attempts to overcome this overcomplicated
   the query. Probably missing some little trick */
   
SELECT t.store AS t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, EXTRACT(MONTH FROM t.saledate) 
       AS Month_Num, COUNT(DISTINCT t.saledate) AS days_with_sale, 
       SUM(t.sprice)/COUNT(DISTINCT t.saledate) AS average_daily_revenue,
       CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
            WHEN days_with_sale < 20 THEN 'Exclude'
       ELSE 'Include'
       END AS Exclusion
FROM trnsact t
WHERE t.stype = 'P'
GROUP BY t_store, Year_Num, Month_Num
HAVING Exclusion = 'Include'
ORDER BY days_with_sale ASC;
-- Looks like this query excludes the proper fields, but we shall 
-- see whether the concatenation is necessary for future querys...

/* To add a column with High School Education level, we'll incorporate the following 
   query as a subquery in the above query */
SELECT CASE WHEN msa_high >= 50 AND msa_high <= 60 THEN 'low'
               WHEN msa_high > 60 AND msa_high <= 70 THEN 'medium'
               WHEN msa_high > 70 THEN 'high' END AS hs_edu_level, store
FROM store_msa
ORDER BY msa_high ASC;

/* Like so */

SELECT t.store AS t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, EXTRACT(MONTH FROM t.saledate) 
       AS Month_Num, COUNT(DISTINCT t.saledate) AS days_with_sale, 
       SUM(t.sprice)/COUNT(DISTINCT t.saledate) AS average_daily_revenue,
       store_edu_level.hs_edu_level,
       CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
            WHEN days_with_sale < 20 THEN 'Exclude'
       ELSE 'Include'
       END AS Exclusion
FROM trnsact t JOIN (SELECT CASE WHEN msa_high >= 50 AND msa_high <= 60 THEN 'low'
                     WHEN msa_high > 60 AND msa_high <= 70 THEN 'medium'
                     WHEN msa_high > 70 THEN 'high' END AS hs_edu_level, store
                     FROM store_msa) AS store_edu_level
                 ON t.store = store_edu_level.store
WHERE t.stype = 'P'
GROUP BY t_store, Year_Num, Month_Num, store_edu_level.hs_edu_level
HAVING Exclusion = 'Include'
ORDER BY days_with_sale ASC;

/* And then we need to group this table's avg daily sales by High School Education level */
SELECT tbl.hs_edu_level, SUM(tbl.sum_sprice)/SUM(tbl.days_with_sale) AS avg_daily_revenue
FROM(SELECT t.store as t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, EXTRACT(MONTH FROM t.saledate) 
             AS Month_Num, COUNT(DISTINCT t.saledate) AS days_with_sale, 
             SUM(t.sprice) AS sum_sprice,
             store_edu_level.hs_edu_level,
             CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
                  WHEN days_with_sale < 20 THEN 'Exclude'
             ELSE 'Include'
             END AS Exclusion
      FROM trnsact t JOIN (SELECT CASE WHEN msa_high >= 50 AND msa_high <= 60 THEN 'low'
                           WHEN msa_high > 60 AND msa_high <= 70 THEN 'medium'
                           WHEN msa_high > 70 THEN 'high' END AS hs_edu_level, store
                           FROM store_msa) AS store_edu_level
                       ON t.store = store_edu_level.store
      WHERE t.stype = 'P'
      GROUP BY t_store, Year_Num, Month_Num, store_edu_level.hs_edu_level
      HAVING Exclusion = 'Include') AS tbl
GROUP BY hs_edu_level;
--The education level group avrages from this query match the instructor's values

/* And then we need to group by MSA Income */

SELECT tbl.msa_income, SUM(tbl.sum_sprice)/SUM(tbl.days_with_sale) AS avg_daily_revenue
      FROM(SELECT t.store as t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, EXTRACT(MONTH FROM t.saledate) 
                   AS Month_Num, COUNT(DISTINCT t.saledate) AS days_with_sale, 
                   SUM(t.sprice) AS sum_sprice,
                   Top_Income_Stores.msa_income,
                   CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
                        WHEN days_with_sale < 20 THEN 'Exclude'
                   ELSE 'Include'
                   END AS Exclusion
            FROM trnsact t JOIN (SELECT store, msa_income 
                           FROM store_msa
                           ) AS Top_Income_Stores
                       ON t.store = Top_Income_Stores.store
      WHERE t.stype = 'P'
      GROUP BY t_store, Year_Num, Month_Num, Top_Income_Stores.msa_income
      HAVING Exclusion = 'Include') AS tbl
GROUP BY msa_income
ORDER BY msa_income DESC;

/* === Find brand of SKU with greatest standard deviation of sale price excluding SKUs with <100 transactions === */

SELECT Top_10_sku.sku, i.brand, Top_10_sku.stddev_sprice, Top_10_sku.num
FROM (SELECT TOP 10 sku, STDDEV_SAMP(sprice) AS stddev_sprice,
      COUNT(*) AS num
      FROM trnsact
      WHERE stype = 'P'
      GROUP BY sku
      HAVING num > 100
      ORDER BY stddev_sprice DESC) AS Top_10_sku
JOIN skuinfo i
  ON Top_10_sku.sku = i.sku
ORDER BY Top_10_sku.stddev_sprice DESC;
-- OUTPUT (top row):
-- sku,     brand,   stddev, num
-- 2762683, HART SCH, 175.8, 106

-- Used the below queries to investigate this SKU
SELECT *
FROM trnsact
WHERE sku = 2762683
ORDER BY sprice DESC;

SELECT *
FROM skuinfo
WHERE sku = 2762683;

/* Note that very few transactions were made for the original sale price.
   Item was often discounted over 75%. Think original price was set too high. */
   
-- The below query finds a few metrics for sales made in each month, other adaptations may be needed in the future

SELECT filtered_data.Year_Num, filtered_data.Month_Num, 
       SUM(filtered_data.days_with_sale) AS sum_sale_days,
       SUM(filtered_data.sum_daily_revenue) AS total_daily_revenue,
       total_daily_revenue/sum_sale_days AS avg_daily_revenue_by_store
FROM (SELECT t.store AS t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, 
             EXTRACT(MONTH FROM t.saledate) 
             AS Month_Num, COUNT(DISTINCT t.saledate) AS days_with_sale, 
             SUM(t.sprice) AS sum_daily_revenue,
             CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
                  WHEN days_with_sale < 20 THEN 'Exclude'
             ELSE 'Include'
             END AS Exclusion
      FROM trnsact t
      WHERE t.stype = 'P'
      GROUP BY t_store, Year_Num, Month_Num
      HAVING Exclusion = 'Include') AS filtered_data
GROUP BY Year_Num, Month_Num
ORDER BY avg_daily_revenue_by_store DESC;

/* Which department, in which city and state of what store, had the greatest %
   increase in average daily sales revenue from November to December? */
   
SELECT store, city, state, deptdesc, 
       COUNT(DISTINCT saledate) AS days_with_sale,
       SUM(CASE WHEN Month_Num = 11 THEN sprice END) AS Nov_Sales,
       SUM(CASE WHEN Month_Num = 12 THEN sprice END) AS Dec_Sales,
       ((Dec_Sales - Nov_Sales) / Nov_Sales) * 100 AS Pct_Change
FROM (SELECT s.sku, d.deptdesc
      FROM deptinfo d JOIN skuinfo s
        ON s.dept = d.dept) AS dept_sku JOIN 
     (SELECT t.store, s.city, s.state, t.sku, t.sprice, t.saledate, 
             EXTRACT(YEAR FROM t.saledate) AS Year_Num, 
             EXTRACT(MONTH FROM t.saledate) AS Month_Num, 
             CASE WHEN (Month_Num NOT IN (11,12)) THEN 'Exclude'
             ELSE 'Include'
             END AS Exclusion
      FROM trnsact t JOIN strinfo s
        ON s.store = t.store
      WHERE t.stype = 'P' AND Exclusion = 'Include') AS trnsact_store 
  ON dept_sku.sku = trnsact_store.sku
GROUP BY store, city, state, deptdesc
HAVING Nov_Sales IS NOT NULL AND Dec_Sales IS NOT NULL AND days_with_sale > 20 --Tweak to adjust exclusion of bad data
ORDER BY pct_change DESC;

/* What is the city and state of the store that had the greatest decrease in
   average daily revenue from August to September? */

SELECT store, city, state, --remove store if you want to group by city
       COUNT(DISTINCT saledate) AS days_with_sale,
       SUM(CASE WHEN Month_Num = 8 THEN sprice END) AS Aug_Sales,
       SUM(CASE WHEN Month_Num = 9 THEN sprice END) AS Sep_Sales,
       ((Sep_Sales - Aug_Sales) / Aug_Sales) * 100 AS Pct_Change
FROM (SELECT t.store, s.city, s.state, t.sku, t.sprice, t.saledate, 
             EXTRACT(YEAR FROM t.saledate) AS Year_Num, 
             EXTRACT(MONTH FROM t.saledate) AS Month_Num, 
             CASE WHEN (Month_Num NOT IN (8,9)) THEN 'Exclude'
             ELSE 'Include'
             END AS Exclusion
      FROM trnsact t JOIN strinfo s
        ON s.store = t.store
      WHERE t.stype = 'P' AND Exclusion = 'Include') AS trnsact_store 
GROUP BY store, city, state
HAVING Aug_Sales IS NOT NULL AND Sep_Sales IS NOT NULL AND days_with_sale > 20 --Tweak to adjust exclusion of bad data
ORDER BY pct_change ASC;

/* Extract the month with the greatest revenue */
SELECT t.store AS t_store, EXTRACT(YEAR FROM t.saledate) AS Year_Num, 
       EXTRACT(MONTH FROM t.saledate) AS Month_Num, 
       COUNT(DISTINCT t.saledate) AS days_with_sale, 
       SUM(t.sprice)/COUNT(DISTINCT t.saledate) AS average_daily_revenue,
       RANK() OVER (PARTITION BY t_store ORDER BY average_daily_revenue DESC) AS Month_Ranking,
       CASE WHEN (Month_Num = 8 AND Year_Num = 2005) THEN 'Exclude'
            WHEN days_with_sale < 20 THEN 'Exclude'
       ELSE 'Include'
       END AS Exclusion
QUALIFY Month_Ranking = 1
FROM trnsact t
WHERE t.stype = 'P'
GROUP BY t_store, Year_Num, Month_Num
HAVING Exclusion = 'Include'
ORDER BY Month_Ranking ASC;

/* WEEK ENDING 20180415 */

=== Counts of Distinct sku in skuinfo, skstinfo, trnsact ===

SELECT COUNT(DISTINCT sku)
FROM skuinfo;
...1564178 ... {also note that there are no duplicate sku in this table becasue
                count(sku) provides the same 1564178}

SELECT COUNT(DISTINCT sku)
FROM skstinfo;
...760212

SELECT COUNT(DISTINCT sku)
FROM trnsact;
...714499

=== Counts of Distinct sku in table pairs using inner joins ===
  === skuinfo/skstinfo, skuinfo/trnsact, skstinfo/trnsact ===

SELECT COUNT(DISTINCT si.sku)
FROM skuinfo si LEFT JOIN trnsact t
  ON si.sku = t.sku
WHERE t.sku IS NULL;
...849679
# Since 1564178 - 849679 = 714499 this query looks like it is performing as expected.
# Due to many-to relationship between skstinfo and trnsact, we can use the skuinfo
# table to join these two columns by sku since its primary key is sku and all values
# are unique. Yay Dillards!

=== Identify whether store + sku pair is unique in trnsact or skstinfo table ===

SELECT store, sku, COUNT(*) AS Total_Instances
FROM trnsact
GROUP BY store, sku
ORDER BY Total_Instances DESC;
...36099491 rows; Total_Instances >> 1 for many

SELECT store, sku, COUNT(*) AS Total_Instances
FROM skstinfo
GROUP BY store, sku
ORDER BY Total_Instances DESC;
...36099491 rows; Total_Instances = 1 for all
# Find that store, sku combine to form a unique pair in skstinfo table, so can be used
# to join with trnsact table.

=== Count distinct stores from strinfo, store_msa, skstinfo, trnsact tables ===

SELECT COUNT(DISTINCT store)
FROM strinfo;
...453

SELECT COUNT(DISTINCT store)
FROM store_msa;
...333

SELECT COUNT(DISTINCT store)
FROM skstinfo;
...357

SELECT COUNT(DISTINCT store)
FROM trnsact;
...332

=== Find common features in table produced when outer joining skstinfo and trnsact ===
             === When an sku is in trnsact but not in skstinfo ===

SELECT *
FROM skstinfo r RIGHT JOIN trnsact t
  ON t.sku = r.sku AND t.store = r.store
WHERE r.sku IS NULL;

# At first glance, and with a few unsuccessful queries into what might be going on with the data,
# I don't notice any common issues. Although many 'interid' entries are 000000000, this is true
# for the entire dataset in general.

SELECT t.sku AS sku_missing_info, COUNT(DISTINCT t.store) AS Num_Stores,
COUNT(DISTINCT t.interid) AS Num_Interids, COUNT(DISTINCT t.mic) AS Num_mics
FROM skstinfo r RIGHT JOIN trnsact t
  ON t.sku = r.sku AND t.store = r.store
WHERE r.sku IS NULL
GROUP BY t.sku
ORDER BY Num_mics DESC;

# Lets me see if there are any obvious patterns in the counts of these variables, but
# so far, no pattern is noted.

=== Calculate average daily profit ===
***Note: although according to practice exercises, this query obtains the correct answer,
   it does not consider the effect of returns on profit***

SELECT register, SUM(t.sprice-s.cost)/COUNT(DISTINCT t.saledate) AS AVG_Purchase_Profit
FROM trnsact t LEFT JOIN skstinfo s
  ON t.sku = s.sku AND t.store = s.store
WHERE s.sku IS NOT NULL AND t.stype='P' AND register=640
GROUP BY register
ORDER BY register DESC;
...10779.20

## Think to find more accurate value we would need to add the result of this query:
(we want to find the total amount that the store paid back to customers who returned products)
SELECT register, SUM(-t.amt)/COUNT(DISTINCT t.saledate) AS AVG_Return_Loss
FROM trnsact t LEFT JOIN skstinfo s
  ON t.sku = s.sku AND t.store = s.store
WHERE s.sku IS NOT NULL AND t.stype='R' AND register=640
GROUP BY register
ORDER BY register DESC;
...-2614.35

Yielding a more accurate average profit of $8164.85... that's what I think anyway.

=== On what day was the total cost of returned items highest? ===
SELECT t.saledate, SUM(-t.amt) AS Total_Return_Loss
FROM trnsact t LEFT JOIN skstinfo s
  ON t.sku = s.sku AND t.store = s.store
WHERE s.sku IS NOT NULL AND t.stype='R'
GROUP BY t.saledate
ORDER BY Total_Return_Loss ASC;
...2004-12-27 had the most return loss, -$1,212,071.96

## This is a big number so to verify that it is within the realm of possibility, I ran
## this query:

SELECT t.saledate, SUM(t.sprice-s.cost) AS Total_Purchase_Profit
FROM trnsact t LEFT JOIN skstinfo s
  ON t.sku = s.sku AND t.store = s.store
WHERE s.sku IS NOT NULL AND t.stype='P'
GROUP BY t.saledate
ORDER BY Total_Purchase_Profit DESC;
...On 2005-03-26 had the max total purchase profit, $5,140,397.75
## In other words, max total return loss represents aobut 24% of max total purchase
## profit... this is in line with returns accounting for about 24% of the total purchase
## profit at register 640. So what's happening on the microscale is, apparently, also
## manifesting in macroscale statistics. Interesting...

## The below query aggrigates sums of returned item quantities by unique sale date.

SELECT t.saledate, SUM(quantity) AS Total_Returned_Items
FROM trnsact t LEFT JOIN skstinfo s
  ON t.sku = s.sku AND t.store = s.store
WHERE s.sku IS NOT NULL AND t.stype='R'
GROUP BY t.saledate
ORDER BY Total_Returned_Items DESC;
...2005-07-30 had the most returned items: 36,984.

=== What are the maximum and minimum sale prices of an item in the database ===

SELECT MAX(sprice), MIN(sprice)
FROM trnsact;
...MAX: $6017.00, MIN: $0.00

## Can also aggrigate on the sku level if desired, e.g.

SELECT MAX(sprice), MIN(sprice), sku, COUNT(*)
FROM trnsact
GROUP BY sku
ORDER BY MIN(sprice) ASC;
...$0 saleprices aren't extremely prolific in the data, but many items do sell way under cost.
## Expensive items tend to sell for one high price.

=== How many departments have more than 100 brands in them, and what are their descriptions? ===
Answer: only three of them...

SELECT d.dept, d.deptdesc, COUNT(DISTINCT s.brand) AS Num_Brands
FROM deptinfo d RIGHT JOIN skuinfo s
  ON d.dept = s.dept
GROUP BY d.dept, d.deptdesc
HAVING Num_Brands > 100
ORDER BY Num_Brands DESC;

Environ, Colehann, and Carters have 389, 118, and 109 brands respectively.

=== Retreive dept descriptions from each of the skus in the skstinfo table. ===

SELECT s.sku, d.deptdesc
FROM (skstinfo s LEFT JOIN skuinfo sr ON s.sku = sr.sku) LEFT JOIN deptinfo d
  ON  sr.dept = d.dept
WHERE sr.sku IS NOT NULL
GROUP BY s.sku, d.deptdesc;
...Confirmed that SKU # 5020024 is 'LESLIE' by adding AND s.sku = 5020024.

## Noted that each of the 760212 skus have a dept description, which is as expected
## There don't appear to be any duplicates. Makes sense because each dept can have
## many SKUs but each SKU can only have one department. Go Dillard's db dev team!

=== What department (with department description), brand, style, and color had the greatest total
    value of returned items? ===

SELECT d.dept, d.deptdesc, s.brand, s.style, s.color, SUM(-t.amt) AS Value_of_Returned_Items, COUNT(*)
FROM (trnsact t LEFT JOIN skuinfo s ON t.sku = s.sku) LEFT JOIN deptinfo d
  ON s.dept = d.dept
WHERE s.sku IS NOT NULL AND t.stype='R'
GROUP BY d.dept, d.deptdesc, s.brand, s.style, s.color
ORDER BY Value_of_Returned_Items ASC;

Can confirm this query retreives the correct data on row 5.

=== In what state and zip code is the store that had the greatest total revenue during the time
period monitored in our dataset? ===

SELECT s.store, s.city, s.state, s.zip, SUM(t.sprice) AS Total_Sale_Revenue
FROM trnsact t LEFT JOIN strinfo s
  ON t.store = s.store
WHERE t.stype = 'P'
GROUP BY s.store, s.city, s.state, s.zip
ORDER BY Total_Sale_Revenue DESC;

Can confirm that this query retreives the correct data on row 10.

/* WEEK ENDING 20180407 */
####################################################################################
  What is the color of the Liz Claiborne brand item with the highest SKU # in the  
  Dillard’s database (the Liz Claiborne brand is abbreviated “LIZ CLAI” in the     
  Dillard’s database)?                                                             
####################################################################################
SELECT color
FROM skuinfo
WHERE sku = (SELECT MAX(sku) FROM skuinfo WHERE brand = 'LIZ CLAI') AND brand = 'LIZ CLAI';

#####################################################################################
  What is the sku number of the item in the Dillard’s database that had the highest
  original sales price?
#####################################################################################
SELECT sku
FROM trnsact
WHERE orgprice = (SELECT MAX(orgprice) FROM trnsact);

#####################################################################################
  What register number made the sale with the highest original price and highest sale 
  price between the dates of August 1, 2004 and August 10, 2004? Make sure to sort by 
  original price first and sale price second.
#####################################################################################
SELECT TOP 10 register, orgprice, sprice, orgprice - sprice AS margin, saledate
FROM trnsact
WHERE saledate BETWEEN '2004-08-01' AND '2004-08-10'
ORDER BY orgprice DESC, sprice DESC;
