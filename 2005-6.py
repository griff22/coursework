# preparation
import sqlite3
import pandas as pd
import os
# 
# create database
conn = sqlite3.connect ('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/flights0506.db')
# 
# create tables base data
2005 = pd.read_csv('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/2005.csv')
2006 = pd.read_csv('C:/Users/Surface/Documents/PROGRAMMING/COURSEWORK/2006.csv')
2005.to_sql('2005', con = conn, index = False)
2006.to_sql('2006', con = conn, index = False)
#
# create table master combined
c = conn.cursor()
c.execute('''
CREATE TABLE combo (
