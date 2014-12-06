
export MAV2SOURCE0='-u  av2source -pavS12 -h newskyline.org '
export MAV2SOURCE="${MAV2SOURCE0} -D a1_kiev"

export MAV2TARGET0='-u  av2target -pavT14 -h newskyline.org '
export MAV2TARGET="${MAV2TARGET0} -D av2_kiev"

## for devel
export MAV2TARGET0='-u  root -h localhost '
export MAV2TARGET="${MAV2TARGET} -D av2_kiev"
