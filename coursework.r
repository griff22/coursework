# preparation
install.packages('tidyverse')
library('tidyverse')
install.packages('RSQLite')
library('RSQLite')
install.packages('DBI')
library('DBI')
install.packages('ggplot2')
library('ggplot2')
install.packages("lubridate")
library(lubridate)
#
# connect to DB already set up
setwd('c:/Users/Surface/Documents/PROGRAMMING/COURSEWORK')
conn <- dbConnect(RSQLite::SQLite(), 'flights.db')
#
# check all there
dbReadTable(conn, 'flights') # answer 14.3m flights
dbListTables(conn) # all there "airports", "carriers", "flights", "plane-data", "variable-descriptions"
# 
# -------------------------------------------
# QUERY 1. Best time to travel with minimum delays.
#
# Average delay per month query
bestmonth <- dbGetQuery(conn, 'SELECT month, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 GROUP BY month')
class(bestmonth) # answer is data frame
str(bestmonth) # answer is $ Month        : int  1 2 3 4 5 6 7 8 9 10 ...$ AVG(DepDelay): num  21.2 19.9 20.9 17.9 18.4 ...
# bestmonth <- transform(bestmonth, MonthAbb = month.abb[Month])
# answer is April
# plot
avg.dep.delay.month <- c(bestmonth$`AVG(DepDelay)`)
month <- c(bestmonth$Month)
png(file='c:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/MonthR.png', width=600)
barplot(avg.dep.delay.month, names.arg = month.abb, main='Av Dep Delay per Month in 2005 & 2006', xlab='Month', ylab='Delay (mins)')
dev.off()
#
# Average delay per day of week
bestday <- dbGetQuery(conn, 'SELECT DayOfWeek, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 GROUP BY DayOfWeek')
# answer is Tuesday
# plot
avg.dep.delay.day <- c(bestday$`AVG(DepDelay)`)
day <- c(bestday$DayOfWeek)
png(file='c:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/DayR.png', height=1000, width=1000)
barplot(avg.dep.delay.day, main = 'Av Dep Delay per Day in April 05 & 06', xlab='Day', ylab ='Delay (mins)')
dev.off()
#
# Average delay per hour of day
besthour <- dbGetQuery(conn, 'SELECT SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3), AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 AND DayOfWeek=2 GROUP BY SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3)')
# doesn't like it?
#
# -------------------------------------------
# QUERY 2. Do older plane suffer more delays?
age <- dbGetQuery(conn, WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
'SELECT AgeAtDep, AVG(DepDelay) FROM temp_query WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep NOT IN (-2, -1, 2005, 2006) GROUP BY AgeAtDep')
# not working?
# Justify outliers (-1, -2, 2005, 2006)
# shows only 2 planes account for outliers.
# avg_delay_ageatdep = cur.fetchall()
# avg_delay_ageatdep = {k: v for k,v in avg_delay_ageatdep}
# 
