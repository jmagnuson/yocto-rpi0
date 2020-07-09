# Copyright (C) 2020 Jon Magnuson <jon.magnuson@gmail.com>
# Released under the MIT license (see COPYING.MIT for the terms)

RDEPENDS_${PN}_remove = "wireless-regdb"
RDEPENDS_${PN}_append = " wireless-regdb-static"
#RDEPENDS_${PN}_append += "hello-single"
RDEPENDS_${PN}_append = " hello-rust"
