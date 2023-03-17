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
install.packages("dbplyr")
library(dbplyr)
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
day <- day %>% recode(`1`= "Mon", `2`="Tue", `3`= "Wed", '4'="Thu", '5'="Fri", '6'="Sat", '7'="Sun")
png(file='c:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/DayR.png', height=1000, width=1000)
barplot(avg.dep.delay.day, names.arg = day, main = 'Av Dep Delay per Day in April 05 & 06', xlab='Day', ylab ='Delay (mins)')
dev.off()
#
# Average delay per hour of day
# original python. besthour <- dbGetQuery(conn, 'SELECT SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3), AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 AND DayOfWeek=2 GROUP BY SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3)')
besthour <- dbGetQuery(conn, 'SELECT DepTime, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 AND DayOfWeek=2 GROUP BY DepTime')
besthour1 <- besthour[-which(besthour$DepTime>2400),]
besthour1$DepTime_perhour <- floor(besthour1$DepTime/100)+1
mean_dep <- vector()
for(i in 1:24){
  mean_dep[i] <- mean(besthour1$`AVG(DepDelay)`[which(besthour1$DepTime_perhour==i)])
}
which.min(mean_dep)
# categories <- c('1-59', '100-159', '200-259', '300-359', '400-459', '500-559', '600-659', '700-759', '800-859', '900-959', '1000-1059', '1100-1159', '1200-1259', '1300-1359', '1400-1459', '1500-1559', '1600-1659', '1700-1759', '1800-1859', '1900-1959', '2000-2059', '2100-2159', '2200-2259', '2300-2359')
# hours <-mutate(besthour, clock=DepTime/100)
# besthour_cats <-cut(hours$clock, seq(0,25,1))
# hours_range <- hours %>%
#  mutate(ranges = cut(clock, seq(0, 24, 1))) %>% 
#  group_by(ranges) %>% 
#  summarize(means=mean(avg(depdelay))) %>%
#  as.data.frame
# aggregate(hours_range, by list(hours_range$ranges))
doesn't like it?
#
# -------------------------------------------
# QUERY 2. Do older plane suffer more delays?
# original python. age <- dbGetQuery(conn, WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
# python 'SELECT AgeAtDep, AVG(DepDelay) FROM temp_query WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep NOT IN (-2, -1, 2005, 2006) GROUP BY AgeAtDep')
# mod. age <- dbGetQuery(conn, 'SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year != 'NA')'
# not working?
# Justify outliers (-1, -2, 2005, 2006)
# shows only 2 planes account for outliers.
# avg_delay_ageatdep = cur.fetchall()
# avg_delay_ageatdep = {k: v for k,v in avg_delay_ageatdep}
# 
