#!/bin/bash

# Verificador de Laboratorio ISO - UNRN
# Sistema de Archivos y Expansión de EBS

OUT="informe_almacenamiento_ISO.txt"
HID=$(hostid)
# Obtener Instance ID de AWS de forma segura
IID=$(curl -s --token $(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") http://169.254.169.254/latest/meta-data/instance-id || echo "no-aws-id")

echo "Generando informe de validación..."

{
    echo "=== RESULTADO DE LABORATORIO: SISTEMAS DE ARCHIVOS ==="
    echo "Identificador Único (HostID): $HID"
    echo "Instancia AWS ID: $IID"
    echo "Fecha de ejecución: $(date)"
    echo "Firma Digital: $(echo "${HID}${IID}" | sha256sum | cut -d' ' -f1)"
    echo "------------------------------------------------------"
    
    echo "[PASO 1] Verificando Punto de Montaje /mnt/mi_disco:"
    if mountpoint -q /mnt/mi_disco; then
        echo "ESTADO: OK (Montado)"
    else
        echo "ESTADO: ERROR (No montado)"
    fi

    echo ""
    echo "[PASO 2] Verificando Tamaño del Sistema de Archivos:"
    SIZE_GB=$(df -BG /mnt/mi_disco --output=size | tail -n 1 | tr -d 'G ')
    echo "Espacio Total Detectado: ${SIZE_GB} GB"
    if [ "$SIZE_GB" -ge 2 ]; then
        echo "ESTADO: EXPANSIÓN EXITOSA (>= 2GB)"
    else
        echo "ESTADO: PENDIENTE DE EXPANSIÓN (< 2GB)"
    fi

    echo ""
    echo "[PASO 3] Tipo de Sistema de Archivos:"
    df -Th /mnt/mi_disco | tail -n 1 | awk '{print "Formato detectado: " $2}'

    echo ""
    echo "[PASO 4] Tabla de Particiones Actual (Detalle):"
    lsblk /dev/nvme1n1 -o NAME,SIZE,TYPE,MOUNTPOINT

} > "$OUT"

echo "Informe generado con éxito en: $OUT"
echo "Asegúrese de que el informe indique 'EXPANSIÓN EXITOSA' antes de entregarlo."
