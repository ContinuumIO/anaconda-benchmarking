#!/bin/bash
set -euxo pipefail

fname="Miniconda3-latest-Linux-x86_64.sh"
curl -LO https://repo.continuum.io/miniconda/$fname
bash -x $fname -bfp /opt/conda
/opt/conda/bin/conda clean -ptiy
rm -rf Miniconda*
