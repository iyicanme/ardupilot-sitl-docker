FROM alpine:3.20.3 AS sitl

# Install git, python3 and bash 
RUN apk update && apk upgrade && apk add --update --no-cache git python3 py3-pip bash
RUN git config --global url."https://github.com/".insteadOf git://github.com/

# Clone ardupilot repository
ARG GIT_TAG=master
RUN git clone -b ${GIT_TAG} --depth=1 https://github.com/ArduPilot/ardupilot.git ardupilot
WORKDIR ardupilot

# Initialize git submodules (following http://ardupilot.org/dev/docs/setting-up-sitl-on-linux.html)
RUN git submodule update --init --recursive

# Install prerequisites
RUN Tools/environment_install/install-prereqs-alpine.sh -y

# Build project (following https://github.com/ArduPilot/ardupilot/blob/master/BUILD.md)
RUN ./waf distclean
RUN ./waf configure --board sitl
RUN ./waf copter

FROM sitl

# Expose TCP 5760
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

# Run sitl
ENTRYPOINT /ardupilot/Tools/autotest/sim_vehicle.py \
    --vehicle ${VEHICLE} \
    -I${INSTANCE} \
    --custom-location=${LAT},${LON},${ALT},${DIR} \
    -w \
    --frame ${MODEL} \
    --no-rebuild \
    --no-mavproxy \
    --speedup ${SPEEDUP}
