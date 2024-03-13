import redis
import time
import random

# Conenectamos a la bd
r = redis.Redis(host="localhost", port=6379, db=0)

# Añadimos 100.000 jhons y contamos cuanto tarda
start = time.time()

for i in range(100000): 
    r.set(f"Jhon{i}", random.randint(0, 100))
    
end = time.time()

# Tiempo que ha tardado
print(f"Tiempo para Redis: {end - start}")

# Cerramos la conexión
r.flushdb() 
r.close()

