# prisms-candi
Compile &amp; install dependencies for PRISMS Center softwares on linux-based systems.

## Quickstart
The following commands download the latest stable release of PRISMS-PF and install the minimum prerequisites.

Make sure perl is installed
```
which perl
```
Install the required perl modules with cpan
```
cpan
install Config::Tiny
```
Install common linux packages with
```
sudo apt-get install lsb-release git subversion wget bc libgmp-dev \
build-essential autoconf automake cmake libtool gfortran python3 \
libboost-all-dev zlib1g-dev \
openmpi-bin openmpi-common libopenmpi-dev \
libblas3 libblas-dev liblapack3 liblapack-dev libsuitesparse-dev
```
Clone the repo
```
git clone https://github.com/landinjm/prisms-candi.git
cd prisms-candi
./candi.pl
```

## Extended Usage
TODO
