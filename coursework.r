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
# check all there
dbListTables(conn)
dbListFields(conn, 'Flights')
# how count?
# -------------------------------------------
# QUERY 1
# Average delay per month query
month <- dbGetQuery(conn, 'SELECT month, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 GROUP BY month')
# Average delay per month plot
