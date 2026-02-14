#!/bin/env bash

THUMB="/tmp/hyde-mpris.png"
ART_INFO="/tmp/hyde-mpris.inf"

# 1. Obtener URL y Info
artUrl=$(playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null)
song_info=$(playerctl metadata --format '{{title}}  {{artist}}' 2>/dev/null)

if [[ -z "$song_info" ]]; then
    echo ""
    rm -f "$THUMB" "$ART_INFO"
    exit 0
fi

echo "$song_info"
[[ -z "$artUrl" ]] && exit 0

# 2. Optimización: ¿Cambió la canción?
if [[ -f "$ART_INFO" && "$(cat "$ART_INFO")" == "$artUrl" && -f "$THUMB" ]]; then
    exit 0
fi

# 3. Manejo de la ruta (Decodificación de %20, %28, etc.)
if [[ "$artUrl" == file://* ]]; then
    # Quitamos el prefijo file:// y decodificamos la URL
    cleanPath=$(printf '%b' "${artUrl#file:////}" | sed 's/%\([0-9A-F][0-9A-F]\)/\\x\1/g' | xargs -0 printf)
    # Si la ruta decodificada no funciona, intentamos la ruta con el prefijo corregido
    realPath="/${artUrl#file://localhost/}"
    realPath="${realPath#file:///}"
    
    # Intentamos copiar usando una versión decodificada por Python (más fiable para espacios)
    decodedPath=$(python3 -c "import sys, urllib.parse; print(urllib.parse.unquote(sys.argv[1]))" "${artUrl#file://}" 2>/dev/null)

    if [[ -f "$decodedPath" ]]; then
        cp "$decodedPath" "$THUMB"
    elif [[ -f "$realPath" ]]; then
        cp "$realPath" "$THUMB"
    else
        # Si no encontramos la imagen local, no borramos la anterior para no dejar el hueco
        exit 0
    fi
else
    # Caso URL de internet (Spotify)
    curl -sSL "$artUrl" -o "$THUMB" || exit 0
fi

# 4. Finalizar
echo "$artUrl" > "$ART_INFO"
pkill -USR2 hyprlock
