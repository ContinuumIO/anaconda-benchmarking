set -ex

#
# for cfg in pip3 anaconda3 intel3
# do

cfg=intel3

bash set_python_envs.sh $cfg
if [ "$cfg" == "pip3" ]; then
    source $HOME/envs/$cfg/bin/activate
else
    source $HOME/envs/$cfg/bin/activate $HOME/envs/$cfg/
fi
python -V
pushd /repos/numpy_benchmarks
python run.py -t python
#done


# python3 -m perf compare_to pip3.json anaconda3.json intel3.json --table
