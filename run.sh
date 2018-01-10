set -ex
bash set_python_envs.sh $1
if [ "$1" == "pip3" ]; then
    source $HOME/envs/$1/bin/activate
else
    source $HOME/envs/$1/bin/activate $HOME/envs/$1/
fi
python -V
python bs_erf_numpy.py
