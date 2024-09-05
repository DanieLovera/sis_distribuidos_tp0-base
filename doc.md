# Resolución de pasos

Observación: Los ejercicos estan resueltos por rama, de forma secuencial se mergearon los cambios a la rama master a medida
se fueron resolviendo, por lo tanto, para no llenar de commits nuevos sincronizando todas las ramas y simplificar la revision, las correcciones
que se realizaron a las ramas no estan en master sino en su respectiva rama y no en las siguientes.

## Parte I
### Ejercicio I (git checkout ej1)
Se crea un un script de bash que llama a un script de python con la logica de configuración del Docker Compose para cada cliente.

Uso:  
`./generar-compose.sh docker-compose-dev.yaml 5`

### Ejercicio II (git checkout ej2)
Se utilizó "bind mounts" en lugar de "volumes" para montar los archivos de configuracion del cliente y servidor en los contenedores de docker.  

Modificar estos archivos evitará que se reconstruya la imagen porque no se detectaran difencias en las capas.

### Ejercicio III (git checkout ej3)
Se crea un contenedor intermedio a través del script, este se une a la red en donde se encuentran los clientes y servidores y luego envia un mensaje
al servidor, este mensaje se captura en el script y compara con el original para comprobar que respondio con el mismo mensaje.

Se debe levantar la aplicación antes de correr el script con `make docker-compose-up`  

Uso:  
`./validar-echo-server`

### Ejercicio IV (git checkout ej4)
Para manejar la señal de SIGTERM se hizó uso de librerias propias de cada lenguaje para controlar señales

Si el programa no termina de forma exitosa el codigo de error cera distinto de cero al momento de pedirle a docker que detenga los contenedores en ejecución. Para
comprobar el ejercicio se debe:
1. Levantar un contenedor con el comando `make docker-compose-up`
2. Abrir una linea de comando en paralelo
3. En la nueva terminar ejecutar el comando `make docker-compose-logs` para ver los logs de los contenedores
4. Detener los contenedores con `make docker-compose-down`
5. Observar los códigos de respuesta de cada contenedor en el terminal abierto con logs

## Parte II
### Ejercicio V (git checkout ej5)
Para implementar la lógica de agencias enviando apuestas y un servidor central recibiendolas se estableció el siguiente protocolo de
comunicación de texto:  

| 2 BYTES (tamaño del mensaje) | TEXTO DEL PROTOCOLO |  

| TEXTO DEL PROTOCOLO | = | HEADER | + \n + | CONTENT |  

| HEADER | = | TAG1: VALUE1\n ... TAGN: VALUEN\n |  

Siempre se enviaran dos bytes iniciales para que cada parte sepa cuantos bytes en total va a recibir y luego el mensaje completo que se divide en dos partes, un encabezado 
y contenido, el cliente y el servidor se comunican de la misma forma aunque pueden haber mas o menos campos en el encabezado dependiendo de las necesidades de cada parte 
y el contenido sera específíco de cada mensaje que se quiera trasmitir, no hay un esquema defininido. Por ejemplo: al transmitir una apuesta los campos relevantes de la misma
viajan separados por coma, pero esto es propio de el tipo de operación que se deba realizar.  

Adicionalmente, la transmisión de los ***dos primeros bytes deben ser en formato de red (big endian)*** y el ***texto del protocolo debe ser utf-8***

### Ejercicio VI (git checkout ej6)
Para implementar el batch de apuestas se consideró un ***máximo de 8kb*** en el paquete enviado ademas del ***máximo de apuestas*** enviadas en un único batch. Si el máximo
de apuestas es suficientemente grande para que el intento de envió sea superior a los 8kb entonces se particionaran en un valor menor para cumplir con esa restricción, viceversa
con el máximo de 8kb, ambas restricciones son excluyentes. Para que el protocolo de comunicación soporte varias apuestas de un mismo cliente se definió un mensaje específico para
indicar el fin de la transmisión (bien pudo haber sido un carácter especifico en lugar de un mensaje particular)

### Ejercicio VII (git checkout ej7)
Para que el servidor pudiera reconocer cuando comenzar a dar los resultados de los ganadores se establecio un número fijo de clientes (5), cuando recibe el cierre de carga de 
apuestas de todas las agencias podrá empezar a responder a los clientes por los resultados. Para ello se estableció un nuevo mensaje para obtener a los ganadores, en este caso
como el servidor cierra la conexión con el cliente luego de la carga, el cliente hace polling de los resultados al servidor cada N segundos, una vez
el servidor responda con los resultado se cierra el proceso cliente.

## Parte III
### Ejercicio VIII (git checkout ej8)
Para convertir el servidor en un proceso que acepte multiples clientes se usaron hilos para separar cada proceso cliente del hilo principal que paso a ser el socket que se 
encuentra escuchando conexiones de clientes. Los hilos de clientes son mantenidos en un pool que conforme van terminando su tarea se liberan. Se considero el caso en donde el servidor
recibe la señal de SIGTERM, para ello el servidor debe empezar a cerrar por lo tanto cierra de forma abrupta la comunicación con cada cliente sin esperar a que se terminen de procesar
los resultados, luego libera los recursos consumidos y cierra normalmente.  

Para evitar el acceso a recursos compartidos entre hilos se utilizan locks. Principalmente sobre la abstracción que mantiene el registro de resultados (gracias a que esta lógica se implemento
en una clase aparte se puedo utilizar una estructura de monitor para proteger los accesos concurrentes), como último paso se tenía que proteger el acceso de todos los clientes a disco por lo
tanto se coloco un lock sobre la función que realiza el procesamiento.
