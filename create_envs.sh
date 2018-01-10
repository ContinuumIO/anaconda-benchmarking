python3 -m venv /envs/pip3
source /envs/pip3/bin/activate
pip install numpy==1.13.3 scipy scikit-learn toolz numexpr dask performance perf
source deactivate

/opt/conda/bin/conda create -y -p /envs/anaconda3 python=3.5 numpy=1.13
source /envs/anaconda3/bin/activate
pip install performance perf
source /envs/anaconda3/bin/deactivate
/opt/conda/bin/conda create -y -c intel -p /envs/intel3 python=3.5 numpy=1.13
source /envs/intel3/bin/activate
pip install performance perf
source /envs/intel3/bin/deactivate
conda clean -ay
