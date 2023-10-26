FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y ngspice libgtk-3-dev build-essential wget xterm graphicsmagick ghostscript git screen python3 python3-matplotlib python3-scipy python3-numpy python3-prettytable python3-pandas

RUN install -d /usr/local/share/{sky130_fd_pr,xschem_sky130sky130_fd_sc_hd}

RUN git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_fd_sc_hd /usr/local/share/sky130_fd_sc_hd/
RUN git clone https://github.com/StefanSchippers/xschem_sky130 /usr/local/share/xschem_sky130
RUN git clone https://foss-eda-tools.googlesource.com/skywater-pdk/libs/sky130_fd_pr /usr/local/share/sky130_fd_pr

RUN mkdir /asic

CMD ["/bin/bash"]
