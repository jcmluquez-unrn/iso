#!/bin/bash

# Verificador de Laboratorio ISO - UNRN V3
# Incluye validación de expansión y migración opcional

HID=$(hostid)

#TOKEN=$(curl -s --token $(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600") http://169.254.169.254/latest/meta-data/instance-id || echo "local")

# --- Obtención de Metadatos de AWS ---
#Solicita token de sesion
TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
#Utiliza token anterior para pedir id_instancia (ej. i-085f7e822...)
ID_INSTANCIA=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)


{
    echo "=== INFORME DE VALIDACIÓN ISO - UNRN ==="
    echo "ID Host: $HID"
    echo "Instancia Actual: $TOKEN"
	echo "Instancia: $ID_INSTANCIA"  # Se agregó el ID_INSTANCIA
    echo "Fecha: $(date)"
    echo "Firma: $(echo "${HID}${TOKEN}" | sha256sum | cut -d' ' -f1)"
    echo "----------------------------------------"

    echo "[CHEQUEO 1] Montaje y Expansión:"
    # Buscar si está montado en alguna de las dos carpetas posibles
    MONTAJE=$(lsblk -o MOUNTPOINT | grep -E '/mnt/mi_disco|/mnt/disco_recuperado' | head -n 1)
    
    if [ -n "$MONTAJE" ]; then
        SIZE_GB=$(df -BG "$MONTAJE" --output=size | tail -n 1 | tr -d 'G ')
        echo "Estado: Montado en $MONTAJE"
        echo "Tamaño detectado: ${SIZE_GB}GB"
        if [ "$SIZE_GB" -ge 2 ]; then
            echo "Resultado: EXPANSIÓN EXITOSA"
        else
            echo "Resultado: PENDIENTE DE EXPANSIÓN"
        fi
    else
        echo "Estado: ERROR - No se detecta el disco montado."
    fi

    echo ""
    echo "[CHEQUEO 2] Persistencia (Nivel Avanzado):"
    FILE_PATH="$MONTAJE/archivo_importante.txt"
    if [ -f "$FILE_PATH" ]; then
        echo "Estado: ARCHIVO DE EVIDENCIA DETECTADO"
        echo "Contenido: $(cat "$FILE_PATH")"
        echo "Resultado: PERSISTENCIA COMPROBADA"
    else
        echo "Resultado: FASE AVANZADA NO REALIZADA O ARCHIVO NO ENCONTRADO"
    fi

    echo ""
    echo "[ESTADO DEL KERNEL - TABLA DE PARTICIONES]"
    lsblk -p /dev/nvme1n1 2>/dev/null || lsblk -p /dev/xvdf 2>/dev/null

}