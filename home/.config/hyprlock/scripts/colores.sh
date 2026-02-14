wall=$(swww query | sed -n 's/.*image: //p')

rgb=$(magick "$wall" -resize 1x1 -format "%[fx:int(255*r)],%[fx:int(255*g)],%[fx:int(255*b)]" info:)

IFS=',' read -r r g b <<< "$rgb"

brightness=$(( (r + g + b) / 3 ))

echo "RGB promedio: $r $g $b"
echo "Brillo promedio: $brightness"

if [ "$brightness" -gt 127 ]; then
    echo "Fondo claro → texto negro"
else
    echo "Fondo oscuro → texto blanco"
fi
