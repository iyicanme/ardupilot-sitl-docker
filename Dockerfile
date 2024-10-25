FROM alpine:3.20.3 AS alpine-packages

# install git 
RUN apk update && apk upgrade && apk add --update --no-cache git python3 py3-pip bash
RUN git config --global url."https://github.com/".insteadOf git://github.com/

FROM alpine-packages AS ardupilot

# Now grab ArduPilot from GitHub
ARG COPTER_TAG=Copter-4.5.7
RUN git clone --depth=1 https://github.com/ArduPilot/ardupilot.git ardupilot
WORKDIR ardupilot

# Now start build instructions from http://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html
RUN git submodule update --init --recursive

FROM ardupilot AS sitl

# Need USER set so usermod does not fail...
# Install all prerequisites now
RUN USER=nobody Tools/environment_install/install-prereqs-alpine.sh -y

# Continue build instructions from https://github.com/ArduPilot/ardupilot/blob/master/BUILD.md
RUN ./waf distclean
RUN ./waf configure --board sitl
RUN ./waf copter

FROM sitl

# TCP 5760 is what the sim exposes by default
EXPOSE 5760/tcp

# Variables for simulator
ENV INSTANCE 0
ENV LAT 42.3898
ENV LON -71.1476
ENV ALT 14
ENV DIR 270
ENV MODEL +
ENV SPEEDUP 1
ENV VEHICLE ArduCopter

# Finally the command
ENTRYPOINT /ardupilot/Tools/autotest/sim_vehicle.py --vehicle ${VEHICLE} -I${INSTANCE} --custom-location=${LAT},${LON},${ALT},${DIR} -w --frame ${MODEL} --no-rebuild --no-mavproxy --speedup ${SPEEDUP}
