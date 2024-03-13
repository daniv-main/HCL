import pymysql
import time
import random

# Nos conectamos a la bd
mydb = pymysql.connect(
    host="localhost",
    user="admin",
    password="adminpass"
)

cursor = mydb.cursor()
      
#Creamos bd y tabla
cursor.execute("CREATE DATABASE prueba2")
cursor.execute("USE prueba2")
cursor.execute("CREATE TABLE tabla_prueba (name VARCHAR(255), age INT)")

# Añadimos 100.000 registros y a ver lo que tarda
start = time.time()

for i in range(100000):
    sql = "INSERT INTO tabla_prueba (name, age) VALUES (%s, %s)"
    values = [
        ("John", 25),
        ("Jane", 30),
        ("Jim", 35),
        ("Joan", 40),
    ]
    cursor.executemany(sql, values)
    
mydb.commit()
    
end = time.time()

# Tiempo que ha tardado
print(f"Tiempo para mysql: {end - start}")

cursor.execute("DELETE FROM tabla_prueba") 
mydb.commit()
cursor.execute("DROP TABLE tabla_prueba") 
mydb.commit()
cursor.close()
mydb.close()
    