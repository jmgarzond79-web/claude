<#
  usar-ethernet.ps1
  Hace que Windows use el internet del cable Ethernet y NO el que comparte el
  celular por USB (anclaje USB / RNDIS que crea AudioRelay).
  La red local con el celular se mantiene, asi que AudioRelay sigue funcionando
  como parlante y microfono.

  Uso: clic derecho -> "Ejecutar con PowerShell" (como administrador),
       o en una consola de PowerShell como administrador:
         powershell -ExecutionPolicy Bypass -File .\usar-ethernet.ps1
#>

# --- Pedir permisos de administrador si no los tiene ---
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Start-Process powershell -Verb RunAs -ArgumentList "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# --- Encontrar el adaptador USB del celular (RNDIS / anclaje USB) ---
$usb = Get-NetAdapter | Where-Object {
    $_.Status -eq 'Up' -and (
        $_.InterfaceDescription -match 'Remote NDIS|RNDIS|USB Ethernet|Internet Sharing' -or
        $_.Name -match 'USB'
    )
}

# --- Encontrar el adaptador Ethernet por cable (fisico, no USB, no Wi-Fi) ---
$eth = Get-NetAdapter -Physical | Where-Object {
    $_.Status -eq 'Up' -and
    $_.MediaType -eq '802.3' -and
    $_.InterfaceDescription -notmatch 'Remote NDIS|RNDIS|USB|Internet Sharing'
}

if (-not $usb) {
    Write-Host "No encontre el adaptador USB del celular. Conecta AudioRelay por USB y vuelve a ejecutar." -ForegroundColor Yellow
    Write-Host "`nAdaptadores activos:"
    Get-NetAdapter | Where-Object Status -eq 'Up' | Format-Table Name, InterfaceDescription, ifIndex -AutoSize
    Read-Host "Enter para salir"; exit 1
}
if (-not $eth) {
    Write-Host "Aviso: no encontre un adaptador Ethernet por cable activo." -ForegroundColor Yellow
}

foreach ($a in $usb) {
    Write-Host "Celular (USB): $($a.Name) - $($a.InterfaceDescription)" -ForegroundColor Cyan

    # 1) Prioridad minima: metrica muy alta (fija, no automatica)
    Set-NetIPInterface -InterfaceIndex $a.ifIndex -AutomaticMetric Disabled -InterfaceMetric 9999 -ErrorAction SilentlyContinue

    # 2) Quitar la ruta por defecto (salida a internet) por el celular.
    #    La ruta de la red local (192.168.42.x) se queda, asi AudioRelay sigue conectado.
    Get-NetRoute -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue |
        Where-Object { $_.DestinationPrefix -in '0.0.0.0/0', '::/0' } |
        Remove-NetRoute -Confirm:$false -ErrorAction SilentlyContinue

    # 3) Que Windows no use los DNS del celular
    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @() -ErrorAction SilentlyContinue
    Set-DnsClient -InterfaceIndex $a.ifIndex -RegisterThisConnectionsAddress $false -ErrorAction SilentlyContinue
}

foreach ($e in $eth) {
    Write-Host "Ethernet:      $($e.Name) - $($e.InterfaceDescription)" -ForegroundColor Green
    # Prioridad maxima para el cable
    Set-NetIPInterface -InterfaceIndex $e.ifIndex -AutomaticMetric Disabled -InterfaceMetric 5 -ErrorAction SilentlyContinue
}

Clear-DnsClientCache

Write-Host "`nRutas a internet que quedaron (deberia salir solo el Ethernet):"
Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Format-Table InterfaceAlias, NextHop, RouteMetric, InterfaceMetric -AutoSize

Write-Host "Listo. Internet por Ethernet; el celular sigue como parlante/microfono por USB." -ForegroundColor Green
Read-Host "Enter para salir"
