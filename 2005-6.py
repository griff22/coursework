# preparation
import sqlite3
import pandas as pd
import matplotlib.pyplot as pltimport sqlite3
# 
# create database
conn = sqlite3.connect('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/flights.db')
# 
# initialise dataframes
df_05 = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/2005.csv.bz2", compression="bz2")
df_06 = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/2006.csv.bz2", compression="bz2")
df_pl = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/plane-data.csv")
airports = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/datverse/airports.csv")
carriers = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/carriers.csv")
#
# insert data into database
df_05.to_sql('flights', con=conn, index=False, if_exists='replace')
df_06.to_sql('flights', con=conn, index=False, if_exists='append')
#
# QUERY 1
# Average delay per month query
cur.execute('SELECT month, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay>=0 GROUP BY month;')
avg_delay_month = cur.fetchall()
# Average delay per month plot
# avg_delay_month = {k: v for k,v in avg_delay_month} # turns query result into dictionary
plt.bar(avg_delay_month.keys(), avg_delay_month.values())
# answer is April
#
# Average delay per day of week
cur.execute('''
    SELECT
        DayOfWeek, AVG(DepDelay) 
    FROM
        flights
    WHERE
        Cancelled=0
        AND DepDelay>=0
        AND Month=4
    GROUP BY 
        DayOfWeek
    ;''')
avg_delay_dow = cur.fetchall()
# Average delay per dow plot
avg_delay_dow = {k: v for k,v in avg_delay_dow} # turns query result into dictionary
plt.bar(avg_delay_dow.keys(), avg_delay_dow.values())
# answer is Tuesday
#
# Average delay per hour of day
cur.execute('''
    SELECT
        SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3), AVG(DepDelay) 
    FROM
        flights
    WHERE
        Cancelled=0
        AND DepDelay>=0
        AND Month=4
        AND DayOfWeek=6
    GROUP BY 
        SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3)
    ;''')
avg_delay_hod = cur.fetchall()
# Average delay per hod plot
avg_delay_hod = {k: v for k,v in avg_delay_hod} # turns query result into dictionary
plt.figure(figsize=(20, 10))
plt.bar(avg_delay_hod.keys(), avg_delay_hod.values())
# answer is 0600-0700
# ISSUES re 25 hours??
#
#
#
# QUERY 2. Do older plane suffer more delays?
SELECT *, (2023 - "year") FROM "plane-data";
SELECT * FROM "plane-data";
SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum ORDER BY (flights."Year" - "plane-data".Year) ASC NULLS LAST;
WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
SELECT
	AgeAtDep,
	--COUNT(*),
	AVG(DepDelay)
FROM temp_query
WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep NOT IN (-2, -1, 2005, 2006)
GROUP BY AgeAtDep
# missing line of fit
#
# query 3. How does number of people flying between different locations change over time?
c.execute('''
SELECT airports.city AS city, COUNT(*) AS total
FROM airports JOIN ontime ON ontime.dest = airports.iata
WHERE ontime.Cancelled = 0
GROUP BY airports.city
GROUP BY Year
ORDER BY total DESC
''')
print(c.fetchone()[0], "has the highest number of inbound flights (excluding canceled flights)")
# plot?
c.execute('''
SELECT airports.city AS city, COUNT(*) AS total
FROM airports JOIN ontime ON ontime.origin = airports.iata
WHERE ontime.Cancelled = 0
GROUP BY airports.city
GROUP BY Year
ORDER BY total DESC
''')
print(c.fetchone()[0], "has the highest number of outbound flights (excluding canceled flights)")
# plot?
