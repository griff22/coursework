# preparation
install.packages('tidyverse')
library('tidyverse')
install.packages('RSQLite')
library('RSQLite')
install.packages('DBI')
library('DBI')
#
# connect to DB already set up
conn <- dbConnect(RSQLite::SQLite(), 'flights.db')
# check all there
dbListTables(conn)
dbListFields(conn, 'Flights')
# how count?
# -------------------------------------------
# QUERY 1
# Average delay per month query
