# preparation
import sqlite3
import pandas as pd
import os
# 
# create database
conn = sqlite3.connect ('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/flights0506.db')
# 
# create tables supp info
airports = pd.read_csv('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/airports.csv')
carriers = pd.read_csv('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/carriers.csv')
planes = pd.read_csv('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/plane-data.csv')
airports.to_sql('airports', con = conn, index = False)
carriers.to_sql('carriers', con = conn, index = False)
planes.to_sql('planes', con = conn, index = False)
#
# create table main data ontime
c = conn.cursor()
c.execute('''
CREATE TABLE ontime (
  Year int,
  Month int,
  DayofMonth int,
  DayOfWeek int,
  DepTime  int,
  CRSDepTime int,
  ArrTime int,
  CRSArrTime int,
  UniqueCarrier varchar(5),
  FlightNum int,
  TailNum varchar(8),
  ActualElapsedTime int,
  CRSElapsedTime int,
  AirTime int,
  ArrDelay int,
  DepDelay int,
  Origin varchar(3),
  Dest varchar(3),
  Distance int,
  TaxiIn int,
  TaxiOut int,
  Cancelled int,
  CancellationCode varchar(1),
  Diverted varchar(1),
  CarrierDelay int,
  WeatherDelay int,
  NASDelay int,
  SecurityDelay int,
  LateAircraftDelay int
)
''')
conn.commit()
for year in range(2005, 2006):
    ontime = pd.read_csv('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/'+str(year)+'.csv')
    ontime.to_sql('ontime', con = conn, if_exists = 'append', index = False)
conn.commit()
#
# query 1. When is best time of day/ day of week/ time of year to minimise delays?
