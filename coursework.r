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
besthour <- dbGetQuery(conn, 'SELECT DepTime, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 AND Month=4 AND DayOfWeek=2 GROUP BY DepTime')
besthour1 <- besthour[-which(besthour$DepTime>2400),] # ignore 2 flights of dirty data showing time as 2400+. 
besthour1$DepTime_perhour <- floor(besthour1$DepTime/100)+1
mean_dep <- vector()
for(i in 1:24){
  mean_dep[i] <- mean(besthour1$`AVG(DepDelay)`[which(besthour1$DepTime_perhour==i)])
}
which.min(mean_dep) $answer is hour 6 which is 0500-0600 as no flights 0400-0500
png(file='c:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/HourR.png', height=1000, width=1000)
barplot(mean_dep, names.arg=1:24, cex.names = 0.7, col = "lightblue", main = "Best Hour on Tuesdays in April 05 & 06", xlab = "Delay(mins)", ylab = "Hour")
dev.off()
#
# -------------------------------------------
# QUERY 2. Do older plane suffer more delays?
#
# setup
p <- read.csv("C:\\users\\surface\\documents\\programming\\coursework\\dataverse\\plane-data.csv")
f05 <- read.csv("C:\\users\\surface\\documents\\programming\\coursework\\dataverse\\2005.csv")
f06 <- read.csv("C:\\users\\surface\\documents\\programming\\coursework\\dataverse\\2006.csv")
#
# age of planes
age_2005 <- 2005-as.numeric(p$year)
p2 <- cbind(p, age_2005)
age_2006 <- 2006-as.numeric(p$year)
p3 <- cbind(p2, age_2006)
av_age <- 2005.5-as.numeric(p$year)
p4 <- cbind(p3, av_age)
p_clean <- p4 %>% drop_na()
p_final <- subset(p_clean, !(p_clean$age_2005 %in% c(-3, -2, -1, 2005, 2006)))
#
# dep delay per tail number
by_tail <- dbGetQuery(conn, 'SELECT TailNum, AVG(DepDelay) from flights WHERE Cancelled=0 AND DepDelay >=0 GROUP BY TailNum')

# avg_dep_delay_tailnum <-aggregate(Flights_2005$DepDelay, list(Flights_2005$TailNum), mean)

flights05_tailnum <- intersect(plane.data$tailnum, unique(Flights_2005$TailNum))
tailnum_2005_planedata <- plane.data$tailnum %in% flights05_tailnum
tailnum_2005_flightdata <- avg_dep_delay_tailnum$Group.1 %in% flights05_tailnum
age_2005_depdelay <- data.frame(tailnum=flights05_tailnum, 
                                age=age_2005[tailnum_2005_planedata], 
                                avgddelay= avg_dep_delay_tailnum$x[tailnum_2005_flightdata])
age_2005_depdelay1 <- age_2005_depdelay[complete.cases(age_2005_depdelay), ]
age_2005_depdelay2 <- age_2005_depdelay1[which(age_2005_depdelay1$age >=0),]
age_2005_depdelay3 <- age_2005_depdelay2[-which(age_2005_depdelay2$age ==2005),]

age_05_avg_ddelay <- aggregate(age_2005_depdelay3$avgddelay, list(age_2005_depdelay3$age), mean)
age_05_avg_ddelay1 <- data.frame(age=as.factor(age_05_avg_ddelay$Group.1), avgddelay=age_05_avg_ddelay$x)
age_05_avg_ddelay2 <- data.frame(avgddelay=age_05_avg_ddelay$x)
rownames(age_05_avg_ddelay2) <- age_05_avg_ddelay1$age

barplot(age_05_avg_ddelay2$avgddelay) 












# need to join flights with plane-data on tail number
# calculate ageatdep = flights.year - plane-data.year
# AVG(DepDelay) per Age
# ignore dirty data
# plot best fit & give line equation
#
# original python. age <- dbGetQuery(conn, WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
# python 'SELECT AgeAtDep, AVG(DepDelay) FROM temp_query WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep NOT IN (-2, -1, 2005, 2006) GROUP BY AgeAtDep')
# mod. age <- dbGetQuery(conn, 'SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year != 'NA')'
# not working?
# Justify outliers (-1, -2, 2005, 2006)
# shows only 2 planes account for outliers.
# avg_delay_ageatdep = cur.fetchall()
# avg_delay_ageatdep = {k: v for k,v in avg_delay_ageatdep}
# 
