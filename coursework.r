# preparation
if(!require(tidyverse)) install.packages('tidyverse')
library('tidyverse')
if(!require(RSQLite)) install.packages('RSQLite')
library('RSQLite')
if(!require(DBI))install.packages('DBI')
library('DBI')
if(!require(ggplot2))install.packages('ggplot2')
library('ggplot2')
if(!require(lubridate))install.packages("lubridate")
library(lubridate)
if(!require(dbplyr))install.packages("dbplyr")
library(dbplyr)
#
# connect to DB already set up
setwd('c:/')
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
png(file='c:/coursework/MonthR.png', width=600)
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
png(file='c:/coursework/DayR.png', height=1000, width=1000)
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
which.min(mean_dep) #answer is hour 6 which is 0500-0600 as no flights 0400-0500
png(file='c:/coursework/HourR.png', height=1000, width=1000)
barplot(mean_dep, names.arg=1:24, cex.names = 0.7, col = "lightblue", main = "Best Hour on Tuesdays in April 05 & 06", xlab = "Delay(mins)", ylab = "Hour")
dev.off()
#
# -------------------------------------------
# QUERY 2. Do older plane suffer more delays?
#
# setup
p <- read.csv("C:\\dataverse\\plane-data.csv")
f05 <- read.csv("C:\\dataverse\\2005.csv")
f06 <- read.csv("C:\\dataverse\\2006.csv")
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
#
# join
joined_tail <- merge(by_tail, p_final, by.x="TailNum", by.y="tailnum")
# flights05_tailnum <- intersect(plane.data$tailnum, unique(Flights_2005$TailNum))
# tailnum_2005_planedata <- plane.data$tailnum %in% flights05_tailnum
# tailnum_2005_flightdata <- avg_dep_delay_tailnum$Group.1 %in% flights05_tailnum
# age_2005_depdelay <- data.frame(tailnum=flights05_tailnum, age=age_2005[tailnum_2005_planedata], avgddelay= avg_dep_delay_tailnum$x[tailnum_2005_flightdata])
# age_2005_depdelay1 <- age_2005_depdelay[complete.cases(age_2005_depdelay), ]
# age_2005_depdelay2 <- age_2005_depdelay1[which(age_2005_depdelay1$age >=0),]
# age_2005_depdelay3 <- age_2005_depdelay2[-which(age_2005_depdelay2$age ==2005),]
# age_05_avg_ddelay <- aggregate(age_2005_depdelay3$avgddelay, list(age_2005_depdelay3$age), mean)
# age_05_avg_ddelay1 <- data.frame(age=as.factor(age_05_avg_ddelay$Group.1), avgddelay=age_05_avg_ddelay$x)
# age_05_avg_ddelay2 <- data.frame(avgddelay=age_05_avg_ddelay$x)
# rownames(age_05_avg_ddelay2) <- age_05_avg_ddelay1$age
#
# plots
# barplot(age_05_avg_ddelay2$avgddelay) 
png(file='c:/coursework/AgeR.png', height=1000, width=1000)
plot(joined_tail$av_age, joined_tail$`AVG(DepDelay)`, main='Av Delay per Aircraft Age in 05 & 06', xlab='Age (years)', ylab='Delay(mins)')
abline(lm(joined_tail$`AVG(DepDelay)` ~ joined_tail$av_age), col='orange')
summary(lm(joined_tail$`AVG(DepDelay)` ~ joined_tail$av_age))$coefficients
# answer. intercept 24.2 minutes, gradient = 0.05 minutes/ year.
text(x=40, y=70, "y = mx + c is y mins=0.05x + 24.2", col="red")
dev.off()
#
# ----------------------------------------------------------
# QUERY 3: How do number of people flying between destinations change over time
#
# use igraph
if(!require(igraph)) install.packages("igraph") 
library(igraph)
if(!require(igraphdata)) install.packages("igraphdata") 
library(igraphdata)
#
# year 2005 random 1,000 flights anymore & graph too crowded
f05_sub <- f05[sample(1:nrow(f05), 1000),]
# f05_sub <- f05[1:50000,]
destinations <- union(unique(f05_sub$Dest), unique(f05_sub$Origin))
mat <- matrix(0, nrow = length(destinations), ncol = length(destinations))
rownames(mat) <- colnames(mat) <- destinations
for (i in 1:length(destinations)) {
  for (j in 1:length(destinations)) {
    mat[i,j] <- length(which(f05_sub$Origin==destinations[i] & 
                        f05_sub$Dest==destinations[j]))
  }
}
network <- graph_from_incidence_matrix(mat, directed = TRUE)
network_groups05 <- cluster_label_prop(network)
coords <- layout_in_circle(network,
                           order =
                             order(membership(network_groups05))
)
V(network)$label <- sub("Actor ", "", V(network)$name)
V(network)$label.color <- membership(network_groups05)
V(network)$shape <- "none"
E(network)$weight <- edge.betweenness(network)/10000
png(file='c:/coursework/Network05R.png', height=1000, width=1000)
plot(network, layout = coords, edge.width=E(network)$weight, main = "Network 2005 random 1,000 flights")
dev.off()
#
# year 2006 random 1,000 flights anymore & graph too crowded
f06_sub <- f06[sample(1:nrow(f05), 1000),]
# f06_sub <- f06[1:50000,]
destinations <- union(unique(f06_sub$Dest), unique(f06_sub$Origin))
mat <- matrix(0, nrow = length(destinations), ncol = length(destinations))
rownames(mat) <- colnames(mat) <- destinations
for (i in 1:length(destinations)) {
  for (j in 1:length(destinations)) {
    mat[i,j] <- length(which(f06_sub$Origin==destinations[i] & 
                        f06_sub$Dest==destinations[j]))
  }
}
network <- graph_from_incidence_matrix(mat, directed = TRUE)
network_groups06 <- cluster_label_prop(network)
coords <- layout_in_circle(network,
                           order =
                             order(membership(network_groups06))
)
V(network)$label <- sub("Actor ", "", V(network)$name)
V(network)$label.color <- membership(network_groups06)
V(network)$shape <- "none"
E(network)$weight <- edge.betweenness(network)/10000
png(file='c:/coursework/Network06R.png', height=1000, width=1000)
plot(network, layout = coords, edge.width=E(network)$weight, main = "Network 2006 random 1,000 flights")
dev.off()
# conclusion: on comparing plots, no major change between 2005 & 2006
#
# -----------------------------------------------------------------
# QUERY 4: are there cascading failures as delays between airports?
#
# test data 
f05_1000 <- f05[1:1000,]
f05a <- f05_1000[which(f05_1000$Cancelled==0 & f05_1000$DepDelay>=0),]
#
# dep delay at leaving airport
average_delay_dest <- aggregate(f05a$DepDelay, by = list(f05a$Dest), mean)
data_for_ori_dest <- aggregate(data.frame(f05a$DepDelay), 
                               by = list(f05a$Year, f05a$Month, f05a$DayofMonth, f05a$Origin, f05a$Dest), 
                               function(x)  list(x))
colnames(data_for_ori_dest) <- c("Year", "Month", "DayofMonth", "Origin", "Dest", "DepDelay")
#
# find dep delay at origin airport
origin_unique <- unique(data_for_ori_dest$Origin)                               
res <- vector()
for (i in 1:length(origin_unique)) {
  xx <- which(data_for_ori_dest$Dest==origin_unique[i])
  if(length(xx)>0){
    new_data <- data_for_ori_dest[xx,]
    new_data$DepDelay <- unlist(lapply(new_data$DepDelay, mean))
    new_data1 <- aggregate(new_data$DepDelay, by = list(new_data$Year, new_data$Month, new_data$DayofMonth), mean)
    res <- rbind(res, data.frame(new_data1, Dest = rep(origin_unique[i], nrow(new_data1))))
  }
  else{
    next
  }
}
colnames(res) <- c("Year", "Month", "DayofMonth", "DepDelay_for_origin", "Origin")
data_for_ori_dest1 <- aggregate(data.frame(f05a$DepDelay), 
                                by = list(f05a$Year, f05a$Month, f05a$DayofMonth, f05a$Origin), 
                                mean)
colnames(data_for_ori_dest1) <- c("Year", "Month", "DayofMonth", "Origin", "DepDelay_for_dest")
DepDelay_for_origin <- vector()
for (i in 1:nrow(data_for_ori_dest1)) {
  line_info <-   which(
      res$Year == data_for_ori_dest1$Year[i] &      
      res$Month == data_for_ori_dest1$Month[i] & 
      res$DayofMonth == data_for_ori_dest1$DayofMonth[i] & 
      res$Origin == data_for_ori_dest1$Origin[i]
  )
  if(length(line_info)>0){
    DepDelay_for_origin[i] <- res$DepDelay_for_origin[line_info]
  }
  else{
    DepDelay_for_origin[i] <- 0
  }
}
final_res <- data.frame(data_for_ori_dest1, DepDelay_for_origin)     
final2 <- final_res[final_res$DepDelay_for_origin != 0, ]
#
# plot
png(file='c:/coursework/CascadeR2.png', height=1000, width=1000)
ggplot(final2, aes(x=DepDelay_for_dest, y=DepDelay_for_origin)) + 
  theme_bw() +
  geom_text(label=final2$Origin, size = 3) +
  geom_smooth(method = "lm", se = FALSE) + 
  labs(title = "Cascading delays between airports", x = "Delay at the destination airport", y = "Departure delay at the origin airport")
dev.off()
