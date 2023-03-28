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
if(!require(ggpmisc))install.packages("ggpmisc")
library(ggpmisc)
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
barplot(mean_dep, names.arg=1:24, cex.names = 0.7, main = "Best Hour on Tuesdays in April 05 & 06", xlab = "Delay(mins)", ylab = "Hour")
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
av_age <- 2005.5-as.numeric(p$year) # average age in 2005 & 06
p4 <- cbind(p3, av_age)
p_clean <- p4 %>% drop_na()
p_final <- subset(p_clean, !(p_clean$age_2005 %in% c(-3, -2, -1, 2005, 2006))) # ignore dirty data
#
# dep delay per tail number
by_tail <- dbGetQuery(conn, 'SELECT TailNum, AVG(DepDelay) from flights WHERE Cancelled=0 AND DepDelay >=0 GROUP BY TailNum')
# avg_dep_delay_tailnum <-aggregate(Flights_2005$DepDelay, list(Flights_2005$TailNum), mean)
#
# join
joined_tail <- merge(by_tail, p_final, by.x="TailNum", by.y="tailnum")
#
# plots
png(file='c:/coursework/AgeR.png', height=1000, width=1000)
plot(joined_tail$av_age, joined_tail$`AVG(DepDelay)`, main='Av Delay per Aircraft Age in 05 & 06', xlab='Age (years)', ylab='Delay(mins)')
abline(lm(joined_tail$`AVG(DepDelay)` ~ joined_tail$av_age), col='orange')
summary(lm(joined_tail$`AVG(DepDelay)` ~ joined_tail$av_age))$coefficients
# answer. intercept 24.19 minutes, gradient = 0.05 minutes/ year.
text(x=40, y=70, "y = mx + c is y mins=0.05x + 24.19", col="red", cex=2)
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
# all data 2005 & 2006 data
# f05_1000 <- f05[1:1000,]
f0506 <- rbind(f05, f06)
f0506a <- f0506[which(f0506$Cancelled==0 & f0506$DepDelay>=0, f0506$TailNum!=0),]
order_num <- order(f0506a$Year, f0506a$Month, f0506a$DayofMonth, f0506a$DepTime)
f0506b <- f0506a[order_num,]
#average_delay_dest <- aggregate(f_05a$DepDelay, by = list(f_05a$Dest), mean)
data_for_ori_dest <- aggregate(data.frame(f0506b$DepDelay), 
                               by = list(f0506b$Year, f0506b$Month, f0506b$DayofMonth, f0506b$TailNum), 
                               function(x)  list(x))
data_for_ori_dest2 <- data_for_ori_dest[which(unlist(lapply(data_for_ori_dest$f0506b.DepDelay, length))>1),]
max(unlist(lapply(data_for_ori_dest2$f0506b.DepDelay, length))) #20 flights in one day by one plane!
depdelay <- matrix(NA, nrow = nrow(data_for_ori_dest2), ncol=3)
for (i in 1:nrow(data_for_ori_dest2)) {
  depdelay[i,1] <- data_for_ori_dest2$f0506b.DepDelay[[i]][1]
  depdelay[i,2] <- data_for_ori_dest2$f0506b.DepDelay[[i]][2]
  depdelay[i,3] <- data_for_ori_dest2$f0506b.DepDelay[[i]][3]
}
colnames(depdelay) <- c("Flight_1_delay", "Flight_2_delay", "Flight_3_delay")
data_for_ori_dest3 <- data.frame(data_for_ori_dest2[,-5],depdelay)
mean(data_for_ori_dest3$Flight_1_delay) #16.9 mins
mean(data_for_ori_dest3$Flight_2_delay) #21.0 mins
mean(data_for_ori_dest3$Flight_3_delay, na.rm = TRUE) #24.8 mins
# this shows that on average, delays accumulate and increase as a plane goes from one airport to another. This seems reasonable. 
#
# ----------------------------------------------------------------------------------------------------------------------------------------
# QUERY 5. MODEL.
#
# data. note my computer could not handle all 2005 data of 7 million flights. necessary to restrict data to 10k flights in 2005                      
f05_10k <- f05[1:10000,]
f05ML <- f05_10k[which(f05_10k$Cancelled==0),]
#
# use caret package                            
if(!require(caret)) install.packages("caret") 
library(caret)
#
# parallel computing if needed
if(!require(parallel)) install.packages("parallel")
library(parallel)
if(!require(doParallel)) install.packages("doParallel")
library(doParallel)
#                             
# see what variables don't matter
colnames(f05ML)[nearZeroVar(f05ML)]
# on 1k flights [1] "Year"             "Month"            "UniqueCarrier"    "Cancelled"        "CancellationCode" "Diverted"        
# on 1k flights [7] "CarrierDelay"     "WeatherDelay"     "NASDelay"         "SecurityDelay"
# on 100k flights [1] "Year"              "Month"             "Cancelled"         "CancellationCode"  "Diverted"          "CarrierDelay"      "WeatherDelay"      "NASDelay"         
# on 100k flights [9] "SecurityDelay"     "LateAircraftDelay"
#                              
# select variables & ignore NAs
# ML_flight_data <- f05ML[,c("DepDelay", "DayOfWeek", "DayofMonth", "DepTime", "ArrDelay")]
ML_flight_data <- f05ML[,c("DepDelay", "DayOfWeek", "DayofMonth", "CRSDepTime")]
ML_flight_data <- ML_flight_data[complete.cases(ML_flight_data),]
#
# data prep with 90% in training set
inTrain <- createDataPartition(ML_flight_data$DepDelay, p = 0.9)[[1]]
training <- ML_flight_data[inTrain,]
testing  <- ML_flight_data[-inTrain,]
#
# LINEAR REGRESSION.
train_result_lm <- train(DepDelay~., 
  data = training,
  method = "lm",
  preProc = c("center","scale"))
test_pred_lm  <- predict(train_result_lm, newdata=testing[,-1])
post_lm <- postResample(pred = test_pred_lm, obs = testing[,1])
#
# vis LM prediction v actual
png(file='c:/coursework/modelLMpVa3.png', height=1000, width=1000)                              
plot_data <- data.frame(pred_result = test_pred_lm, actual_result = testing[,1])
ggplot(plot_data, aes(x=actual_result, y=pred_result)) + 
  geom_point() +
  theme_bw() +
  #geom_text(label=final_res$Origin, size = 3) +
  geom_smooth(method = "lm", se = FALSE) + 
  labs(title = "Departure delay prediction (Linear regression)",
       x     = "Actual result", 
       y     = "Predicted result")
dev.off()
# 
# vis LM variables of importance
var_imp_res <- varImp(train_result_lm)
variable   <- rownames(var_imp_res$importance)
importance <- var_imp_res$importance[,1]
data_res   <- data.frame(variable, importance)
png(file='c:/coursework/modelLMimportance3.png', height=1000, width=1000)                              
ggplot(data_res, aes(x=reorder(variable,importance), y=importance,fill=importance, width = .5))+ 
  geom_bar(stat="identity", position="dodge")+ coord_flip()+
  geom_text(aes(label = round(importance)), hjust = -0.2, color = "black", size = 5) + 
  ylab("Variable Importance (Linear regression)")+ 
  xlab("")+ ylim(0,110) + 
  theme_bw() +
  theme(axis.text.x = element_text(face="bold", size= 15), 
        axis.text.y = element_text(face="bold", size= 15)) + 
  guides(fill=F) +
  scale_fill_gradient2(low="yellow2", mid = "orange", high="hotpink", midpoint = 50)
dev.off()
#
# RANDOM FOREST. Tuning takes up a lot of memory and time even on 10k flights & 1000 trees!
if(!require(randomForest)) install.packages("randomForest") 
library(randomForest)
train_result_rf <- train(DepDelay~., 
                         data = training,
                         method = "rf",
                         ntree = 1000,
                         preProc = c("center","scale"),
                         tuneGrid = expand.grid(.mtry=c(sqrt(ncol(training)))))
test_pred_rf  <- predict(train_result_rf, newdata=testing[,-1])
post_rf <- postResample(pred = test_pred_rf, obs = testing[,1])
#
# vis RF prediction v actual
png(file='c:/coursework/modelRFpVa3.png', height=1000, width=1000)  
plot_data <- data.frame(pred_result = test_pred_rf, actual_result = testing[,1])
ggplot(plot_data, aes(x=actual_result, y=pred_result)) + 
  geom_point() +
  theme_bw() +
  #geom_text(label=final_res$Origin, size = 3) +
  geom_smooth(method = "lm", se = FALSE) + 
  labs(title = "Departure delay prediction (Random forest)",
       x     = "Actual result", 
       y     = "Prediction result")
dev.off()
#
# vis RF variables of importance
var_imp_res <- varImp(train_result_rf)
variable   <- rownames(var_imp_res$importance)
importance <- var_imp_res$importance[,1]
data_res   <- data.frame(variable, importance)
png(file='c:/coursework/modelRFimportance3.png', height=1000, width=1000) 
ggplot(data_res, aes(x=reorder(variable,importance), y=importance,fill=importance, width = .5))+ 
  geom_bar(stat="identity", position="dodge")+ coord_flip()+
  geom_text(aes(label = round(importance)), hjust = -0.2, color = "black", size = 5) + 
  ylab("Variable Importance (Random forest)")+ 
  xlab("")+ ylim(0,110) + 
  theme_bw() +
  theme(axis.text.x = element_text(face="bold", size= 15), 
        axis.text.y = element_text(face="bold", size= 15)) + 
  guides(fill=F) +
  scale_fill_gradient2(low="yellow2", mid = "orange", high="hotpink", midpoint = 50)
dev.off()
#
# summary LM v RF
rbind(post_lm, post_rf)
# final answer is RF gives an improved result over LM but takes much longer.
# -----------RMSE  Rsquared       MAE
# post_lm 36.78911 0.1139163 23.61412
# post_rf 35.14620 0.2033085 21.52686
# END
---------------------------------------------------------------------------------------------
                               
                               
                               
