#!/bin/bash
stty -echo
tput civis
clear

cat << EOF
exit: [ q ]                                             [ w ]
                                Shell F1            [ a ][ s ][ d ]
EOF
read -s -n 1

TOP=3
BOTTOM=35
LEFT=0
RIGHT=80
HORIZON=$(($TOP + 5))
CAR_SIZE_X=5
CAR_SIZE_Y=4
BIKE_SIZE_X=3
BIKE_SIZE_Y=3
score=0
DELAY=0.1

x_car=38
y_car=29
road_moving=0

y_enemy1=11
x_enemy1=39

y_enemy2=11
x_enemy2=39

function draw_horizon
{
    tput cup $(($TOP+1)) $(($LEFT+1))
    echo "                 __      /\\  /\\  /\\      __      /\\        __"
    tput cup $(($TOP+2)) $(($LEFT+1))
    echo "                /  \\    /  \\/  \\/  \\    /  \\    /  \\  /\\  /  \\"
    tput cup $(($TOP+3)) $(($LEFT+1))
    echo "               /    \\  /    \\  /    \\  /    \\  /    \\/  \\/    \\"
    tput cup $(($TOP+4)) $(($LEFT+1))
    echo "              /      \\/      \\/      \\/      \\/      \\__/      \\"
}


function draw_enemy
{
    tput cup $y_enemy1 $x_enemy1
    if [[ $y_enemy1 -lt $BOTTOM ]]
    then
        echo "|0|"
    fi
    tput cup $(( $y_enemy1 + 1 )) $x_enemy1 
    if [[ $(($y_enemy1 + 1)) -lt $BOTTOM ]]
    then
        echo "|*|"
    fi
    tput cup $(( $y_enemy1 + 2 )) $x_enemy1 
    if [[ $(($y_enemy1 + 2)) -lt $BOTTOM ]]
    then
        echo "|0|"
    fi
}

function check_colision
{
    for ((i=0; i<$CAR_SIZE_X; i++ ))
    do
        if [[ $(($y_enemy1 + $BIKE_SIZE_Y - 1)) -eq $y_car && $(($x_enemy1+$BIKE_SIZE_X-1)) -eq $(($x_car+$i)) ]]
        then
            my_exit
        fi
        if [[ $(($y_enemy1 + $BIKE_SIZE_Y - 1)) -eq $y_car && $x_enemy1 -eq $(($x_car+$i)) ]]
        then
            my_exit
        fi
    done

    for ((i=0; i<$CAR_SIZE_Y; i++ ))
    do
        if [[ $y_enemy1 -eq $(($y_car+$i)) && $x_enemy1 -eq $(($x_car+$CAR_SIZE_X-1)) ]]
        then
            my_exit
        fi
        if [[ $y_enemy1 -eq $(($y_car+$i)) && $(($x_enemy1+$BIKE_SIZE_X-1)) -eq $(($x_car)) ]]
        then
            my_exit
        fi
    done
}

function my_exit
{
            trap exit ALRM
            tput cup 20 36
            echo "END OF GAME" 
            tput cup 21 37
            echo "Score: $score"
            stty echo
            tput cvvis
}

function move_enemy
{
    ((y_enemy1++))
    draw_enemy
    tput cup $(( $y_enemy1 - 1 )) $x_enemy1
    echo "   "
    if [[ $y_enemy1 -eq $BOTTOM ]]
    then
        y_enemy1=11
        x_enemy1=39
    fi

    check_colision
}

function move_road
{   
    road_moving_x=1
    intermittence=2
    for (( left_road_y=$HORIZON; left_road_y<$BOTTOM; left_road_y++))
    do
        if [[ intermittence -eq 3 && $(($left_road_y+$road_moving)) -lt $BOTTOM ]]
        then
        tput cup $(($left_road_y+$road_moving)) $(((($RIGHT - $LEFT)/2)-$road_moving_x-1-$road_moving))
        echo "."
        tput cup $(($left_road_y+$road_moving)) $(((($RIGHT - $LEFT)/2)+$road_moving_x+1+$road_moving))
        echo "."
        tput cup $(($left_road_y+$road_moving-1)) $(((($RIGHT - $LEFT)/2)-$road_moving_x-$road_moving))
        echo " "   
        tput cup $(($left_road_y+$road_moving-1)) $(((($RIGHT - $LEFT)/2)+$road_moving_x+$road_moving))
        echo " "   
        ((road_moving_x++))
        intermittence=0
        else
            ((intermittence++))
            ((road_moving_x++))
        fi
    done
    ((road_moving++))
    if [[ $road_moving -eq 4 ]]
    then
        road_moving=0
    fi
}

function draw_road
{   
    road_x=1
    for (( left_road_y=$HORIZON; left_road_y<$BOTTOM; left_road_y++))
    do
        tput cup $left_road_y $(((($RIGHT - $LEFT)/2)-$road_x))
        echo "."
        tput cup $left_road_y $(((($RIGHT - $LEFT)/2)+$road_x))
        echo "."
        ((road_x++))
    done
}

function draw_map
{
    for (( x=$LEFT+1; x<$RIGHT; x++))
    do
        tput cup $TOP $x
        echo "-"
        tput cup $BOTTOM $x
        echo "-"   
    done

    for (( i=$TOP; i<=$BOTTOM; i++))
    do
        tput cup $i $LEFT
        echo "|"  
        tput cup $i $RIGHT
        echo "|" 
    done
}

function draw_car
{   
    tput cup $y_car $x_car
    echo "O/*\O"
    tput cup $(( $y_car + 1 )) $x_car 
    echo "|---|"
    tput cup $(( $y_car + 2 )) $x_car 
    echo "|---|"
    tput cup $(( $y_car + 3 )) $x_car 
    echo "O|*|O"
}

function move
{
    (sleep $DELAY && kill -ALRM $$) &
    move_enemy
    move_road
    tput cup 2 0
    echo "Score: $score"
    ((score++))
}

draw_horizon
draw_road
draw_car
draw_map

trap move ALRM
move

while :
do
    read -s -n 1 key
    case "$key" in 
        w)  if (( $y_car > $HORIZON + 1))
            then
                ((y_car--))
                draw_car
                tput cup $(( $y_car + $CAR_SIZE_Y )) $x_car
                echo "     "
            fi
            ;;
        s)  
            if (( $y_car < $BOTTOM - $CAR_SIZE_Y))
            then
                ((y_car++))
                draw_car
                tput cup $(( $y_car - 1 )) $x_car
                echo "     "
            fi
            ;;
        a)
            if (( $x_car > $LEFT + 1))
            then
                ((x_car--))
                draw_car
                for (( i=$y_car; i<$(($y_car + $CAR_SIZE_Y)); i++))
                do
                    tput cup $i $(( $x_car + $CAR_SIZE_X ))
                    echo " "
                done
            fi
            ;;
        d)  
            if (( $x_car < $RIGHT - $CAR_SIZE_X))
                then
                ((x_car++))
                draw_car
                for (( i=$y_car; i<$(($y_car+4)); i++))
                do
                    tput cup $i $(( $x_car - 1 ))
                    echo " "
                done
            fi
            ;;
        q) 
            echo "Bye"
            tput cvvis
            stty echo
            exit 0
            ;;
    esac
done

