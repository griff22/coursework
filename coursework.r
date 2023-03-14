# preparation
install.packages('tidyverse')
library('tidyverse')
install.packages('RSQLite')
library('RSQLite')
install.packages('DBI')
library('DBI')
install.packages('ggplot2')
library('ggplot2')
#
# connect to DB already set up
setwd('c:/Users/Surface/Documents/PROGRAMMING/COURSEWORK')
conn <- dbConnect(RSQLite::SQLite(), 'flights.db')
#
# check all there
dbReadTable(conn, 'flights')
# answer 14.3m flights
dbListTables(conn)
# all there "airports", "carriers", "flights", "plane-data", "variable-descriptions"
# 
# -------------------------------------------
# QUERY 1. Best time to travel with minimum delays.
# Average delay per month query
month <- dbGetQuery(conn, 'SELECT month, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 GROUP BY month')
class(month) # answer is data frame
# avg_delay_month = dbFetch((), n=-1) not working
# answer is April
#
# Average delay per month plot?
#
# Average delay per day of week
day <- dbGetQuery(conn, 'SELECT DayOfWeek, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 GROUP BY DayOfWeek')
# answer is Tuesday
# plot?
# Average delay per hour of day
hour <- dbGetQuery(conn, 'SELECT SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3), AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 AND DayOfWeek=2 GROUP BY SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3)')
# doesn't like it?
#
# QUERY 2. Do older plane suffer more delays?
age <- dbGetQuery(conn, WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
'SELECT AgeAtDep, AVG(DepDelay) FROM temp_query WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep NOT IN (-2, -1, 2005, 2006) GROUP BY AgeAtDep')
# not working?
# Justify outliers (-1, -2, 2005, 2006)
# shows only 2 planes account for outliers. how show?
# avg_delay_ageatdep = cur.fetchall()
# avg_delay_ageatdep = {k: v for k,v in avg_delay_ageatdep}
# 
