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
# f05_1000 <- f05
f0506 <- rbind(f05, f06)
f0506a <- f0506[which(f0506$Cancelled==0 & f0506$DepDelay>=0),]
#
# dep delay at leaving airport
average_delay_dest <- aggregate(f0506$DepDelay, by = list(f0506$Dest), mean)
data_for_ori_dest <- aggregate(data.frame(f0506$DepDelay), 
                               by = list(f0506$Year, f0506$Month, f0506$DayofMonth, f0506$Origin, f0506$Dest), 
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
data_for_ori_dest1 <- aggregate(data.frame(f0506$DepDelay), 
                                by = list(f0506$Year, f0506$Month, f0506$DayofMonth, f0506$Origin), 
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
png(file='c:/coursework/CascadeRall0506.png', height=1000, width=1000)
ggplot(final2, aes(x=DepDelay_for_dest, y=DepDelay_for_origin)) + 
  theme_bw() +
  geom_text(label=final2$Origin, size = 3) +
  stat_poly_line() +
  stat_poly_eq(aes(label = paste(after_stat(eq.label),
                                 after_stat(rr.label), sep = "*\", \"*"))) +
  geom_point() +                           
  labs(title = "Cascading delays between airports", x = "Delay at the destination airport", y = "Departure delay at the origin airport")
dev.off()
summary(lm(final2$DepDelay_for_origin ~ final2$DepDelay_for_dest))$coefficients
# answer for test 05 data. intercept 11.4 minutes, gradient = 0.41 minutes. similar answer to Python but R took much longer to run                              
# answer for all 05 & 06. intercept 5.2 minutes, gradient = 0.54 minutes. looks odd with warning messages and many negative dep delays.
# final answer. yes, there are cascading delays with approx 50% of the delay cascading into subsequent flight of airplane & 50% caught up.
# -------------------------------------------------------------
# QUERY 5. MODEL.
#
# data. note my computer could not handle all 2005 data of 7 million flights. necessary to restrict data.                         
f05_100k <- f05[1:100000,]
f05ML <- f05_100k[which(f05_100k$Cancelled==0),]
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
# on test 1000 [1] "Year"             "Month"            "UniqueCarrier"    "Cancelled"        "CancellationCode" "Diverted"        
# on test 1000 [7] "CarrierDelay"     "WeatherDelay"     "NASDelay"         "SecurityDelay"
# on test all 2005 [1] "Year"              "Cancelled"         "CancellationCode"  "Diverted"          "CarrierDelay"      "WeatherDelay"      "NASDelay"          "SecurityDelay"    
# on test all 2005 [9] "LateAircraftDelay"
# on 100k flights [1] "Year"              "Month"             "Cancelled"         "CancellationCode"  "Diverted"          "CarrierDelay"      "WeatherDelay"      "NASDelay"         
# on 100k flights [9] "SecurityDelay"     "LateAircraftDelay"
#                              
# select variables & ignore NAs
ML_flight_data <- f05ML[,c("DepDelay", "DayOfWeek", "DepTime", "ArrDelay", "Origin", "Dest")]
ML_flight_data <- ML_flight_data[complete.cases(ML_flight_data),]
#
# data prep with 90% in training set
inTrain <- createDataPartition(ML_flight_data$DepDelay, p = 0.9)[[1]]
training <- ML_flight_data[inTrain,]
testing  <- ML_flight_data[-inTrain,]
#
# Linear regression
train_result_lm <- train(DepDelay~., 
  data = training,
  method = "lm",
  preProc = c("center","scale"))
test_pred_lm  <- predict(train_result_lm, newdata=testing[,-1])
post_lm <- postResample(pred = test_pred_lm, obs = testing[,1])
#
#
# visualisations LM #
plot_data <- data.frame(pred_result = test_pred, actual_truth = testing[,1])
ggplot(plot_data, aes(x=actual_truth, y=pred_result)) + 
  geom_point() +
  theme_bw() +
  #geom_text(label=final_res$Origin, size = 3) +
  geom_smooth(method = "lm", se = FALSE) + 
  labs(title = "Departure delay prediction (Linear regression)",
       x     = "Actual truth", 
       y     = "Prediction results")

var_imp_res <- varImp(train_result_lm)
variable   <- rownames(var_imp_res$importance)[1:10]
importance <- var_imp_res$importance[1:10,1]
data_res   <- data.frame(variable, importance)
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


# Random forest
train_result_rf <- train(DepDelay~., 
                         data = training,
                         method = "rf",
                         ntree = 1000,
                         preProc = c("center","scale"),
                         tuneGrid = expand.grid(.mtry=c(sqrt(ncol(training)))))

test_pred_rf  <- predict(train_result_rf, newdata=testing[,-1])
post_rf <- postResample(pred = test_pred_rf, obs = testing[,1])


### Visualizations ####
plot_data <- data.frame(pred_result = test_pred, actual_truth = testing[,1])
ggplot(plot_data, aes(x=actual_truth, y=pred_result)) + 
  geom_point() +
  theme_bw() +
  #geom_text(label=final_res$Origin, size = 3) +
  geom_smooth(method = "lm", se = FALSE) + 
  labs(title = "Departure delay prediction (Random forest)",
       x     = "Actual truth", 
       y     = "Prediction results")

var_imp_res <- varImp(train_result_rf)
variable   <- rownames(var_imp_res$importance)[1:10]
importance <- var_imp_res$importance[1:10,1]
data_res   <- data.frame(variable, importance)
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


rbind(post_lm, post_rf)
                               
                               
                               
                               
                               
                               
                               
                               
                               # use mlr3 and skimr for reports
if(!require(mlr3))install.packages("mlr3")
library(mlr3)
if(!require(skimr))install.packages("skimr")
library(skimr) 
if(!require(mlr3learners))install.packages("mlr3learners")
library(mlr3learners) 
if(!require(mlr3pipelines))install.packages("mlr3pipelines")
library(mlr3pipelines)                           
#
                               
