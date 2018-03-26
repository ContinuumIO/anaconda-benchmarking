#!/bin/bash
set -ex

apt-get update
apt-get install -y perl python3 python3-pip curl

/usr/bin/pip3 install numpy==1.14.2 scipy performance perf

fname="Miniconda3-latest-Linux-x86_64.sh"
curl -LO https://repo.continuum.io/miniconda/$fname
bash -x $fname -bfp /opt/conda
/opt/conda/bin/conda clean -ptiy
rm -rf Miniconda*

/opt/conda/bin/conda create -y -c c3i_test2 -p /envs/anaconda3 python=3.6 numpy=1.14 scipy
source /opt/conda/bin/activate /envs/anaconda3
/envs/anaconda3/bin/pip install performance perf
source /opt/conda/bin/deactivate
/opt/conda/bin/conda create -y -c intel -p /envs/intel3 python=3.6 numpy=1.14 scipy
source /opt/conda/bin/activate /envs/intel3
/envs/intel3/bin/pip install performance perf
source /opt/conda/bin/deactivate
/opt/conda/bin/conda clean -ay
