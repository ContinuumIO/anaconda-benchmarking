#!/bin/bash -x
# Copyright (c) 2017, Intel Corporation
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Intel Corporation nor the names of its contributors
#       may be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#export ACCEPT_INTEL_PYTHON_EULA=yes
apt-get update
apt-get install -y perl python3 python3-pip python3-venv
ln -s $(ls /usr/bin/python3.*) /usr/bin/python3
DIR=$HOME/miniconda3
CONDA=$DIR/bin/conda
mkdir -p $DIR
mkdir -p $HOME/envs

# System reference
if [ "$1" == "pip3" ]; then
    [ -d $HOME/envs/pip3 ] || (
        python3 -m venv $HOME/envs/pip3
        source $HOME/envs/pip3/bin/activate
        pip install numpy==1.13.3 scipy scikit-learn toolz numexpr dask performance perf
    )
else
    [ -x $CONDA ] || (
         [ -f Miniconda3-latest-Linux-x86_64.sh ] || curl -O https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
         bash ./Miniconda3-latest-Linux-x86_64.sh -b -p $DIR -f
         [ -x $CONDA ] || exit 1
    )
    # Anaconda reference
    if [ "$1" == "anaconda3" ]; then
        [ -d $HOME/envs/anaconda3 ] || $CONDA create -y -p $HOME/envs/anaconda3 python=3 numpy numexpr scipy dask cython
    else
        # Intel reference
        [ -d $HOME/envs/intel3 ] || $CONDA create -y -p $HOME/envs/intel3 -c intel python=3 numpy numexpr scipy dask cython
    fi
    $HOME/envs/$1/bin/pip install performance perf
fi
