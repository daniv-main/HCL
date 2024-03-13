from cassandra.cluster import Cluster
import time
import random

# Conexión a la bd
cluster = Cluster(['localhost'])
session = cluster.connect()

session.execute("CREATE KEYSPACE IF NOT EXISTS prueba WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 }")

session.set_keyspace('prueba')

session.execute("USE prueba")

session.execute("CREATE TABLE IF NOT EXISTS tabla_prueba (id INT PRIMARY KEY, valor INT)")

# Añadimos 100.000 registros
start = time.time()

for i in range(100000): 
    session.execute(f"INSERT INTO tabla_prueba (id, valor) VALUES ({i}, {random.randint(0, 100000)})")
    
end = time.time()

# Tiempo que ha tardado
print(f"Tiempo para cassandra: {end - start}")

# Cerramos conexión
session.execute("TRUNCATE tabla_prueba") 
session.execute("DROP TABLE tabla_prueba") 
session.execute("DROP KEYSPACE prueba") 

cluster.shutdown()

