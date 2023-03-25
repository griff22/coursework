# preparation queries 1 to 4
import sqlite3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import networkx as nx
# -------------------------------------------
# create database
conn = sqlite3.connect('C:/flights.db')
# -------------------------------------------
# initialise dataframes
df_05 = pd.read_csv("C:/dataverse/2005.csv.bz2", compression="bz2")
df_06 = pd.read_csv("C:/dataverse/2006.csv.bz2", compression="bz2")
df_pl = pd.read_csv("C:/dataverse/plane-data.csv")
df_ap = pd.read_csv("C:/dataverse/airports.csv")
df_ca = pd.read_csv("C:/dataverse/carriers.csv")
df_vd = pd.read_csv("C:/dataverse/variable-descriptions.csv")
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
plt.savefig('C:/COURSEWORK/monthPY.png')
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
plt.savefig('C:/COURSEWORK/dayPY.png')
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
plt.savefig('C:/COURSEWORK/hourPY.png')
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
# shows only 2 planes account for outliers.
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
plt.savefig('C:/COURSEWORK/agePY.png')
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
plt.savefig('C:/COURSEWORK/05nodesPY.png')
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
plt.savefig('C:/COURSEWORK/06nodesPY.png')
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
plt.savefig('C:/COURSEWORK/Top_Ten_05nodesPY.png')
# top 10 2005 are 2 sub-networks (LGA, BOS, DCA, ORD) and (LAX, LAS & SAN)
# DCA is Washington, LGA is NY, ORD is Chicago, LAS is Las Vegas)
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
plt.savefig('C:/COURSEWORK/Top_Ten_06nodesPY.png')
# top 10 2006 are 3 sub-networks (LGA, BOS, DCA) and (LAX, LAS & SAN) and (OGG & HNL)
# HNL is Honolulu and OGG is Kahului
# Hawaii airports make into top networks in 2006, relegating Chicago from 2005
# perhaps Hawaii holidays back in vogue in 2006 after War on Terror subdued
# need to improve graphs
#
# answer: there is no significant difference between the years in pattern of travel although Hawaii becomes more popular in 2006 and Washington less popular.
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
plt.savefig('C:/COURSEWORK/cascadePY.png')
# answer is yes, there are cascading failures with 34% of the original delay cascading into its next flight and 66% of the delay caught up.
#
#
# -----------------------
# QUERY 5. MODELLING
# setup. needed bigger computer!
import sklearn
from sklearn.model_selection import train_test_split
from sklearn.linear_model import LinearRegression
from sklearn.linear_model import LogisticRegression # only binary
from sklearn.ensemble import RandomForestClassifier
from sklearn.ensemble import RandomForestRegressor
from sklearn import svm
from sklearn.ensemble import HistGradientBoostingClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.impute import SimpleImputer
from sklearn.metrics import mean_absolute_error, mean_squared_error, median_absolute_error, explained_variance_score, r2_score
from sklearn import preprocessing
from sklearn.datasets import make_classification
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn import metrics
#
# initialise dataframes
df = pd.concat([pd.read_csv("C:/dataverse/2005.csv.bz2", compression="bz2"), pd.read_csv("C:/dataverse/2006.csv.bz2", compression="bz2")], ignore_index=True)
df = df[df.Cancelled != 1]
df = df[['Month', 'DayOfWeek', 'CRSDepTime', 'CRSArrTime', 'FlightNum', 'Distance', 'DepDelay']]
# check all there
len(df) # 14 million
df.head() # Month	DayOfWeek	CRSDepTime	CRSArrTime	FlightNum	Distance	DepDelay
#
# LINEAR REGRESSION.
# Imputer & define x as features and y as response
X = SimpleImputer().fit_transform(df[['Month', 'DayOfWeek', 'CRSDepTime', 'CRSArrTime', 'FlightNum', 'Distance']])
y = SimpleImputer().fit_transform(np.array(df['DepDelay']).reshape(-1, 1))
#
# Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1)
#
# Train linear regression model
reg = LinearRegression().fit(X_train, y_train)
len(y_test), len(reg.predict(X_test)) # check lengths equal
#
# plot LM
plt.title(label='Dep Delay Predict v Actual', fontsize=15)
plt.xlabel("Actual Dep Delay (Mins)")
plt.ylabel("Predict Dep Delay (Mins)")
plt.scatter(y_test, reg.predict(X_test))
plt.savefig('C:/COURSEWORK/LM_PY.png') # doesn't work well!
#
# LM errors. large!
median_absolute_error(y_test, reg.predict(X_test)), mean_squared_error(y_test, reg.predict(X_test))
explained_variance_score(y_test, reg.predict(X_test))
r2_score(y_test, reg.predict(X_test))
y_test, reg.predict(X_test)
#
# RANDOM FORESTS attempt
print(df.isnull().sum()) # Checking that no missing data exists 






# LOGISTIC REGRESSION attempt - reduce sample size for memory - but only for binary!
# predictor & response varaibles
df_log = df[1:100000]
X = df_log[['Month', 'DayOfWeek', 'CRSDepTime', 'CRSArrTime', 'FlightNum', 'Distance']]
y = df_log['DepDelay']
#
# Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=0)
#
# Fitting
#log_regression = LogisticRegression()
#
# Scaling needed
scaler = preprocessing.StandardScaler().fit(X_train)
X_scaled = scaler.transform(X_train)
X, y = make_classification(random_state=42)
X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=42)
pipe = make_pipeline(StandardScaler(), LogisticRegression())
pipe.fit(X_train, y_train)  # apply scaling on training data
pipe.score(X_test, y_test) # 0.96
#
# Fitting 2
#log_regression.fit(X_train,y_train)
# max iters reached!
# y_train = np.ravel(y_train)
y_pred = log_regression.predict(X_test)
#
# Diagnostics - tell me something isn't right!
#cnf_matrix = metrics.confusion_matrix(y_test, y_pred)
#cnf_matrix
#print("Accuracy:",metrics.accuracy_score(y_test, y_pred)) #1 cannot be!
#y_pred_proba = log_regression.predict_proba(X_test)[::,1]
#fpr, tpr, _ = metrics.roc_curve(y_test,  y_pred_proba)
#auc = metrics.roc_auc_score(y_test, y_pred_proba)
#plt.plot(fpr,tpr,label="AUC="+str(auc))
#plt.legend(loc=4)
#plt.show()
#
# RANDOM FORESTS attempt





