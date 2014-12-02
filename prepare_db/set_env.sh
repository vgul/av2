
export MAV2SOURCE='-u  av2source -pavS12 -h newskyline.org '
export MAV2SOURCE0="${MAV2SOURCE} -D a1_kiev"

export MAV2TARGET='-u  av2target -pavT14 -h newskyline.org '
export MAV2TARGET0="${MAV2TARGET} -D av2_kiev"

## for devel
export MAV2TARGET='-u  root -h localhost '
export MAV2TARGET0="${MAV2TARGET} -D av2_kiev"
