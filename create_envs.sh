#!/bin/bash
set -ex

apt-get update
apt-get install -y perl python3 python3-pip curl

/usr/bin/pip3 install numpy==1.13.3 scipy performance perf

fname="Miniconda3-latest-Linux-x86_64.sh"
curl -LO https://repo.continuum.io/miniconda/$fname
bash -x $fname -bfp /opt/conda
/opt/conda/bin/conda clean -ptiy
rm -rf Miniconda*

/opt/conda/bin/conda create -y -p /envs/anaconda3 python=3.5 numpy=1.13 scipy
source /envs/anaconda3/bin/activate
/envs/anaconda3/bin/pip install performance perf
source /envs/anaconda3/bin/deactivate
/opt/conda/bin/conda create -y -c intel -p /envs/intel3 python=3.5 numpy=1.13 scipy
source /envs/intel3/bin/activate
/envs/intel3/bin/pip install performance perf
source /envs/intel3/bin/deactivate
/opt/conda/bin/conda clean -ay
