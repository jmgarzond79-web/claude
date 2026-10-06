# AudioRelay por USB sin usar el internet del celular

Cuando AudioRelay se conecta por USB, el celular activa el **anclaje USB** (adaptador
"Remote NDIS based Internet Sharing Device"). Windows lo ve como otra red con salida a
internet y a veces la prefiere sobre el cable Ethernet.

`usar-ethernet.ps1` arregla eso **sin desconectar** el celular:

1. Pone el adaptador USB del celular con prioridad mínima (métrica 9999).
2. Le quita la ruta por defecto (0.0.0.0/0 y ::/0) → el PC ya no sale a internet por ahí.
   La red local con el celular (192.168.42.x) queda intacta, así que AudioRelay sigue
   funcionando como parlante y micrófono.
3. Quita los DNS del celular.
4. Pone el Ethernet con prioridad máxima (métrica 5).

## Uso

1. Conecta el celular por USB y abre AudioRelay (que ya esté conectado).
2. Clic derecho en `usar-ethernet.ps1` → **Ejecutar con PowerShell** (pedirá permisos de administrador).
3. Al final muestra las rutas a internet: solo debería aparecer el Ethernet.

La métrica se guarda, pero la ruta por defecto vuelve cada vez que se reconecta el USB,
así que ejecuta el script **cada vez que conectes el celular** (o crea una tarea programada
que lo ejecute al iniciar sesión).

## Hacerlo a mano (sin script)

Panel de control → Redes → **Cambiar opciones del adaptador** → clic derecho en el adaptador
del celular (Remote NDIS) → Propiedades → **Protocolo de Internet versión 4** → Propiedades →
Opciones avanzadas → desmarca **Métrica automática** y escribe `9999`. Repite con IPv6.
En el adaptador Ethernet haz lo mismo pero con `5`.
