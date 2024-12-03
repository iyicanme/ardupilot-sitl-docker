# SITL in Docker

It is aimed to be able to run ArduPilot SITL simulator on Docker so it is possible to develop UAV agent programs without hardware.

## Run image

Clone git repository https://github.com/iyicanme/ardupilot-sitl-docker

```
git clone https://github.com/iyicanme/ardupilot-sitl-docker.git
```

Build the image

```
docker build -t sitl .
```

Run the image

```
docker run -v ./tmp:/tmp -p 55760:5760 sitl
```

This command mounts the `/tmp` directory of the container in the `tmp` directory inside current directory.
This allows reading the SITL logs.

It also binds 5760 TCP port of container to the 55760 TCP port to host.

## Connecting to SITL

Creating a Mavlink connection to host port 55760 TCP port will cause the SITL to start sending constant UAV updates, such as position, battery level, memory information, mission, etc.

Easiest way to create a Mavlink connection is through MavProxy.

MavProxy is available through PyPI, it can be installed as follows.

Create a Python virtual environment

```
python3 -m virtualenv venv
```

This creates a virtual environment in the folder `venv`.

This assumes Python package `virtualenv` is installed.

Install `mavproxy` package

```
venv/bin/pip install mavproxy
```

Run `mavproxy` connection to the SITL instance listening on TCP port 55760

```
venv/bin/mavproxy.py --master=tcp:127.0.0.1:55760
```

Mavproxy can complain about ModemManager possibly interfering with MavProxy.
It can be beneficial to remove the package if an LTE connection is not being made use of. 

## Inspect SITL logs

Logs can be accessed at `./tmp/ArduCopter.log`

```
less tmp/ArduCopter.log
```

## Inspecting the Mavlink traffic

It is possible to use Wireshark to inspect Mavlink messages

To do that, Mavlink parser plugin needs to be generated for Wireshark

Clone the `mavlink` repository at https://github.com/mavlink/mavlink

```
git clone --recursive https://github.com/mavlink/mavlink.git
```

Enter the directory

```
cd mavlink
```

Run the generation script

```
python3 -m pymavlink.tools.mavgen --lang=WLua --wire-protocol=2.0 --output=mavlink.lua message_definitions/v1.0/common.xml 
```

Copy the plugin to Wireshark plugin directory

```
cp mavlink.lua $WIRESHARK_PLUGIN_PATH
```

On Fedora, the path is `/usr/lib64/wireshark/plugins`

The directory can be found by opening Wireshark, under `Help > About Wireshark > Folders > Global Lua Plugins`

Restart Wireshark and check if plugin is loaded correctly, checking if `mavlink.xml.lua` exists under `Help > About Wireshark > Plugins`

The Mavlink traffic can be seen by listening to loopback device, and decoding messages sent from TCP port 55760 as `MAVLINK_PROTO`
