import pymongo
import time
import random

# Conectamos a mongo
client = pymongo.MongoClient("mongodb://admin:adminpass@localhost:27017/")
db = client["prueba"]
collection = db["coleccion"]

# Añadimos 100.000 registros y a ver lo que tarda
start = time.time()

for i in range(100000): 
    data = [
        {"name": "John", "age": random.randint(0, 100)},
        {"name": "Jane", "age": random.randint(0, 100)}
    ]
    collection.insert_many(data)

end = time.time()

print(f"Tiempo para mongo: {end - start}")

collection.delete_many({}) 
collection.drop() 

client.close()

