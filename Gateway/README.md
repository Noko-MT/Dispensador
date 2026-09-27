# Gateway definitivo con Raspberry Pi 3 Model B+

La Raspberry Pi reemplaza al portatil Windows sin cambiar la URL configurada en
la ESP32:

```text
ESP32 -> 192.168.1.15:8080 -> Raspberry Pi/Nginx -> Tailscale -> 100.75.3.34:8000
```

## Datos del despliegue

```text
IP local definitiva de la Raspberry Pi: 192.168.1.15
IP Tailscale del NAS:                     100.75.3.34
Puerto local del gateway:                8080
Puerto de la API en el NAS:              8000
```

## Orden de instalacion

1. Instala Raspberry Pi OS Lite con SSH habilitado.
2. Conecta la Raspberry inicialmente con una IP DHCP diferente de
   `192.168.1.15`; el portatil todavia utiliza esa direccion.
3. Actualiza Raspberry Pi OS.
4. Instala Tailscale y autentica la Raspberry en el mismo tailnet del NAS.
5. Copia esta carpeta completa a la Raspberry.
6. Ejecuta el instalador y las pruebas.
7. Solo despues, retira el gateway Windows y transfiere la reserva DHCP
   `192.168.1.15` a la Raspberry Pi.

Nunca conectes simultaneamente el portatil y la Raspberry con la misma IP.

## Instalar Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --hostname=dispensador-gateway
sudo tailscale set --auto-update
```

El comando `tailscale up` mostrara una URL. Abrela en un navegador e inicia
sesion en el mismo tailnet del NAS.

Comprueba la conexion:

```bash
tailscale status
tailscale ping 100.75.3.34
curl --fail --show-error http://100.75.3.34:8000/health
```

## Copiar e instalar el gateway

Desde Windows, sustituye el usuario y la IP temporal de la Raspberry:

```powershell
scp -r "C:\RUTA\AL\PROYECTO\gateway\raspberry-pi" usuario@IP_TEMPORAL:/home/usuario/
```

En la Raspberry:

```bash
cd ~/raspberry-pi
chmod +x install-gateway.sh test-gateway.sh remove-gateway.sh
sudo ./install-gateway.sh
./test-gateway.sh
```

La prueba debe devolver el JSON de `food-dispenser-gateway-smoke-test` dos
veces: directamente desde el NAS y a traves de Nginx.

## Migrar la IP 192.168.1.15

1. Identifica la MAC Ethernet de la Raspberry:

   ```bash
   cat /sys/class/net/eth0/address
   ```

2. En el portatil Windows, elimina el gateway anterior desde PowerShell como
   administrador:

   ```powershell
   .\Remove-Gateway.ps1 -ListenPort 8080
   ```

3. Apaga o desconecta el portatil de esa red.
4. En el router, elimina la reserva `192.168.1.15` asociada al portatil.
5. Crea la reserva `192.168.1.15` para la MAC Ethernet de la Raspberry.
6. Reinicia la Raspberry:

   ```bash
   sudo reboot
   ```

7. Confirma la direccion:

   ```bash
   hostname -I
   ```

8. Desde un celular de la LAN, sin Tailscale, abre:

   ```text
   http://192.168.1.15:8080/health
   ```

9. Ejecuta nuevamente `gateway_smoke_test.py` en la ESP32. El archivo no debe
   modificarse porque la URL local permanece igual.

## Endurecimiento opcional despues de probar

Primero confirma que el gateway y SSH funcionan. Despues puedes limitar los
puertos entrantes a la LAN usando UFW:

```bash
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
sudo ufw allow from 192.168.1.0/24 to any port 8080 proto tcp
sudo ufw allow in on tailscale0 to any port 22 proto tcp
sudo ufw enable
sudo ufw status verbose
```

## Operacion

- Usa preferiblemente Ethernet entre la Raspberry y el router.
- Configura una fuente estable adecuada para Raspberry Pi 3 B+.
- En Tailscale Admin, desactiva la expiracion de clave para
  `dispensador-gateway`.
- Nginx y Tailscale quedan configurados para iniciar con el sistema.
- Conserva en la ESP32 los horarios esenciales para tolerar fallos de Internet,
  Tailscale o del gateway.
