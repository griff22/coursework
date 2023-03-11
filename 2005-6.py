# preparation
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import networkx as nx
# -------------------------------------------
# create database
conn = sqlite3.connect('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/flights.db')
# -------------------------------------------
# initialise dataframes
df_05 = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/2005.csv.bz2", compression="bz2")
df_06 = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/2006.csv.bz2", compression="bz2")
df_pl = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/plane-data.csv")
df_ap = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/airports.csv")
df_ca = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/carriers.csv")
df_vd = pd.read_csv("C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/dataverse/variable-descriptions.csv")
# -------------------------------------------
# insert data into database
df_05.to_sql('flights', con=conn, index=False, if_exists='replace')
df_06.to_sql('flights', con=conn, index=False, if_exists='append')
df_pl.to_sql('plane-data', con=conn, index=False, if_exists='replace')
df_ap.to_sql('airports', con=conn, index=False, if_exists='replace')
df_ca.to_sql('carriers', con=conn, index=False, if_exists='replace')
df_vd.to_sql('variable-descriptions', con=conn, index=False, if_exists='replace')
# define cur
cur = conn.cursor()
# Checks the data is there
cur.execute('SELECT COUNT(*) FROM flights;')
cur.fetchall()
# answer = 14 million flights
# -------------------------------------------
# QUERY 1
# Average delay per month query
cur.execute('SELECT month, AVG(DepDelay) FROM flights WHERE Cancelled=0 AND DepDelay >=0 GROUP BY month;')
avg_delay_month = cur.fetchall()
avg_delay_month = {k: v for k,v in avg_delay_month}
# Average delay per month plot
plt.bar(avg_delay_month.keys(), avg_delay_month.values())
x = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
plt.xticks(np.arange(1, 13, 1), x)
plt.xlabel('Month')
plt.ylabel('Minutes Delay')
plt.title('Average Departure Delay per Month (minutes)')
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/month.png')
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
        AND DepDelay >=0
        AND Month=4
    GROUP BY 
        DayOfWeek
    ;''')
avg_delay_dow = cur.fetchall() #dow is day of week
# Average delay per dow plot
avg_delay_dow = {k: v for k,v in avg_delay_dow} # turns query result into dictionary
plt.bar(avg_delay_dow.keys(), avg_delay_dow.values())
y = ['Mon', 'Tue', 'Weds', 'Thu', 'Fri', 'Sat', 'Sun']
plt.xticks(np.arange(1, 8, 1), y)
plt.xlabel('Day')
plt.ylabel('Minutes Delay')
plt.title('Average Departure Delay in April 05 & 06 (minutes)')
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/day.png')
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
        AND DepDelay >=0
        AND Month=4
        AND DayOfWeek=2
    GROUP BY 
        SUBSTRING(SUBSTRING('00000' || DepTime, -6, 6), 0, 3)
    ;''')
avg_delay_hod = cur.fetchall() #hod is hour of day
# Average delay per hod plot
avg_delay_hod = {k: v for k,v in avg_delay_hod} # turns query result into dictionary
plt.figure(figsize=(20, 10))
plt.bar(avg_delay_hod.keys(), avg_delay_hod.values())
plt.xticks(np.arange(0, 25, 1))
plt.xlabel('Hour')
plt.ylabel('Minutes Delay')
plt.title('Average Departure Delay on Tuesdays in April 05 & 06 (minutes)')
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/hour.png')
# answer is 0500-0600
# Final answer is Tuesday in April at 0500-0600
#
#
# -------------------------------------------
# QUERY 2. Do older plane suffer more delays?
cur.execute('''
WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
SELECT
	AgeAtDep,
	AVG(DepDelay)
FROM temp_query
WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep NOT IN (-2, -1, 2005, 2006)
GROUP BY AgeAtDep;
''')
# Justify outliers (-1, -2, 2005, 2006)
# cur.execute('''
# WITH temp_query AS (SELECT (flights."Year" - "plane-data".Year) AgeAtDep, * FROM flights JOIN "plane-data" ON flights.TailNum = "plane-data".TailNum WHERE "plane-data".Year <> 'None')
# SELECT
	# temp_query.tailnum,
	# COUNT(*),
	# AgeAtDep
# FROM temp_query
# WHERE Cancelled=0 AND DepDelay>=0 AND AgeAtDep IN (-2, -1, 2005, 2006)
# GROUP BY AgeAtDep;
# ''')
# shows only 2 planes account for outliers. how show?
avg_delay_ageatdep = cur.fetchall()
avg_delay_ageatdep = {k: v for k,v in avg_delay_ageatdep}
# 
# plot & linear line of fit
x = np.array([float(key) for key in avg_delay_ageatdep.keys()])
y = np.array([float(value) for value in avg_delay_ageatdep.values()])
m, c = np.polyfit(x, y, deg=1)
plt.figure(figsize=(20, 10))
line=plt.plot(x, m * x + c, color='orange')
plt.legend(line, [f'gradient m: ~{round(m,2)}, intercept c: ~{round(c,2)}'])
plt.bar(x, y)
plt.xticks(np.arange(0, 51, 1))
plt.xlabel('Age at Departure (Years)')
plt.ylabel('Minutes Delay')
plt.title('Average Departure Delay per Age of aircraft (minutes)')
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/age.png')
# Line equation
# print(f'gradient m: ~{round(m,2)}, intercept c: ~{round(c,2)}')
# answer gradient +0.08, intercept +22.9
# answer is yes, older planes suffer more delays
# ie. each year older, adds 0.08 minute delay
# eg. 50 year old aircraft adds 50*0.08=4 minutes delay
# odd that no planes 45 years old ie. none made in 1960 & 1961 but unable to determine reason for this.
#
#
# ------------------------------------------
# QUERY 3. How does number of people flying between different locations change over time?
# 2005
year = 2005
query = f'SELECT origin, dest, count(*) weight FROM flights WHERE year={year} GROUP BY origin, dest ORDER BY origin, dest;'
cur = conn.cursor()
cur.execute(query)
df = pd.DataFrame(cur.fetchall(), columns=['Origin', 'Destination', 'Weight'])
digraph = nx.DiGraph()
# Add the nodes (airports)
for tup in df.itertuples():
    digraph.add_node(tup.Origin)
    digraph.add_node(tup.Destination)
# Add the weights (number of flights between nodes)
for tup in df.itertuples():
    digraph.add_weighted_edges_from([(tup.Origin, tup.Destination, tup.Weight)])
from matplotlib.pyplot import figure
figure(figsize=(25, 17))
plt.title(label='2005 all airports', fontsize=30)
nx.draw_circular(digraph, width=list(df[:10]['Weight'] * 0.001), with_labels=True, font_size=7)
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/05nodes.png')
#
# 2006
year = 2006
query = f'SELECT origin, dest, count(*) weight FROM flights WHERE year={year} GROUP BY origin, dest ORDER BY origin, dest;'
cur = conn.cursor()
cur.execute(query)
df = pd.DataFrame(cur.fetchall(), columns=['Origin', 'Destination', 'Weight'])
digraph = nx.DiGraph()
# Add the nodes (airports)
for tup in df.itertuples():
    digraph.add_node(tup.Origin)
    digraph.add_node(tup.Destination)
# Add the weights (number of flights between nodes)
for tup in df.itertuples():
    digraph.add_weighted_edges_from([(tup.Origin, tup.Destination, tup.Weight)])
from matplotlib.pyplot import figure
figure(figsize=(25, 17))
plt.title(label='2006 all airports\nLittle visible change from 2005', fontsize=30)
nx.draw_circular(digraph, width=list(df[:10]['Weight'] * 0.001), with_labels=True, font_size=7)
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/06nodes.png')
# comparing the two years results, no significant differences in node networks but very busy vis
#
#
# now look at top 10 for 2005
year = 2005
query = f'SELECT origin, dest, count(*) weight FROM flights WHERE year={year} GROUP BY origin, dest ORDER BY weight DESC, origin, dest LIMIT 10;'
cur = conn.cursor()
cur.execute(query)
df = pd.DataFrame(cur.fetchall(), columns=['Origin', 'Destination', 'Weight'])
digraph = nx.DiGraph()
# Add the nodes (airports)
for tup in df.itertuples():
    digraph.add_node(tup.Origin)
    digraph.add_node(tup.Destination)
# Add the weights (number of flights between nodes)
for tup in df.itertuples():
    digraph.add_weighted_edges_from([(tup.Origin, tup.Destination, tup.Weight)])
digraph.nodes()
df
from matplotlib.pyplot import figure
figure(figsize=(25, 17))
plt.title('Top networks 2005', fontsize=30)
# plt.legend(airports)
nx.draw_circular(digraph, width=list(df['Weight'] * 0.0001), with_labels=True, font_size=30)
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/Top_Ten_05nodes.png')
# top 10 2005 are 2 sub-networks (LGA, BOS, DCA, ORD) and (LAX, LAS & SAN)
# DCA is Arlington, LGA is NY, ORD is Chicago, LAS is Las Vegas)
#
# top 10 for 2006
year = 2006
query = f'SELECT origin, dest, count(*) weight FROM flights WHERE year={year} GROUP BY origin, dest ORDER BY weight DESC, origin, dest LIMIT 10;'
cur = conn.cursor()
cur.execute(query)
df = pd.DataFrame(cur.fetchall(), columns=['Origin', 'Destination', 'Weight'])
digraph = nx.DiGraph()
# Add the nodes (airports)
for tup in df.itertuples():
    digraph.add_node(tup.Origin)
    digraph.add_node(tup.Destination)
# Add the weights (number of flights between nodes)
for tup in df.itertuples():
    digraph.add_weighted_edges_from([(tup.Origin, tup.Destination, tup.Weight)])
digraph.nodes()
df
from matplotlib.pyplot import figure
figure(figsize=(25, 17))
plt.title('Top networks 2006', fontsize=30)
nx.draw_circular(digraph, width=list(df['Weight'] * 0.0001), with_labels=True, font_size=30)
# plt.legend()
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/Top_Ten_06nodes.png')
# top 10 2006 are 3 sub-networks (LGA, BOS, DCA) and (LAX, LAS & SAN) and (OGG & HNL)
# HNL is Honolulu and OGG is Kahului??
#
# need to improve graphs
#
# answer: there is no significant difference between the years in pattern of travel although Hawaii becomes more popular in 2006 and Arlington less popular?
#
#
# -------------------------
# QUERY 4. Are there cascading delays from one airport to another?
query = '''
WITH origin AS (SELECT COUNT(*) count_origin, AVG(DepDelay) avg_delay_origin, Origin airport FROM flights WHERE Cancelled=0 AND DepDelay>=0 GROUP BY Origin ORDER BY AVG(DepDelay) DESC NULLS LAST),
destination AS(SELECT COUNT(*) count_dest, AVG(DepDelay) avg_delay_dest, Dest airport FROM flights WHERE Cancelled=0 AND DepDelay>=0 GROUP BY Dest ORDER BY AVG(DepDelay) DESC NULLS LAST)
SELECT * FROM origin JOIN destination ON origin.airport = destination.airport;'''
cur.execute(query)
df = pd.DataFrame(cur.fetchall(), columns=['count_origin', 'avg_delay_dest', 'airport', 'count_dest', 'avg_delay_origin', '_'])
# plot & linefit
x, y = df['avg_delay_dest'], df['avg_delay_origin']
m, c = np.polyfit(x, y, deg=1)
# line = m * x + c
print(f'gradient m: ~{round(m,2)}, intercept c: ~{round(c,2)}')
# answer is intercept 13.5, gradient 0.34
fig, ax = plt.subplots(figsize=(10, 10))
plt.xlim([0, 80])
plt.ylim([0, 80])
ax.scatter(df['avg_delay_dest'], df['avg_delay_origin'])
line=plt.plot(x, m * x + c, color='orange')
plt.legend(line, [f'gradient m: ~{round(m,2)}, intercept c: ~{round(c,2)}'])
# ax.plot(line)
plt.xlabel("Departure Delay To (Mins)")
plt.ylabel("Departure Delay From (Mins")
for i, txt in enumerate(df['airport']):
    ax.annotate(txt, (df['avg_delay_dest'][i], df['avg_delay_origin'][i]))
# what is this last line doing?
plt.title('Cascading Delays per Airport (minutes)')
plt.savefig('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/cascade.png')
# answer is yes, there are cascading failures with 34% of the original delay cascading into its next flight and 66% of the delay caught up.
#
#
# -----------------------
# QUERY 5. MODELLING
from sklearn.metrics import plot_roc_curve
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
#
# X features and y response
# X_initial, y = DepDelay
# features = [Month, DayOfWeek, DepTime, AgeAtDep, avg_delay_origin]
# X = X_initial[features].copy()
#
# Pre-processing pipelines
# numerical_features = [AgeAtDep, avg_delay_origin]
# numerical_transformer = Pipeline(steps=[
# ('imputer', SimpleImputer()),
# ('scaler', StandardScaler())])
# categorical_features = [Month, DayOfWeek, DepTime]
# categorical_transformer = Pipeline(steps=[
# ('imputer', SimpleImputer()),
# ('onehot', OneHotEncoder(handle_unknown='ignore'))])
# data_transformer = ColumnTransformer(
# transformers=[
# ('numerical', numerical_transformer, numerical_features)
# ('Categorical', categorical_transformer, categorical_features)])
#
# Logistic Regression
# pipe_lr = Pipeline(steps=[('data_transformer', data_transformer),
# (pipe_lr', LogisticRegression(max_iter=10000))])
# X_train, X_test, y-train, y_test = train_test_split(X_initial, y, test_size=0.5, random_state=1)
# param_grid = {
# 'data_transformer__numerical__imputer__startegy': ['mean', 'median'],
# 'data_transformer__categorical__imputer__strategy': ['constant', 'most frequent']
#}
# grid_lr = GridSearchCV(pipe_lr, param_grid=param_grid)
# grid_lr.fit(X_train, y_train);
#
# Gradient Boosting & compare ROC curves...
