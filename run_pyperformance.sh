set -ex

for cfg in pip3 anaconda3 intel3
do

    bash set_python_envs.sh $cfg
    if [ "$cfg" == "pip3" ]; then
        source $HOME/envs/$cfg/bin/activate
    else
        source $HOME/envs/$cfg/bin/activate $HOME/envs/$cfg/
    fi
    python -V
    time pyperformance run -o ${cfg}.json 2>&1
done

wait
python3 -m perf compare_to pip3.json anaconda3.json intel3.json --table
