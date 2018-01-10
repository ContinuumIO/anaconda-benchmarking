set -ex

rm -rf *_run

for cfg in pip3 anaconda3 intel3
do
    bash set_python_envs.sh $cfg
    if [ "$cfg" == "pip3" ]; then
        source $HOME/envs/$cfg/bin/activate
    else
        source $HOME/envs/$cfg/bin/activate $HOME/envs/$cfg/
    fi
    python -V
    perl hardening_check.pl $(which python) | tee security_$cfg.txt

    for run in 1 2 3 4 5
    do
        echo "Starting run $run at $(date)"
        [ -d bs_run ] || mkdir -p bs_run
        time python bs_erf_numpy.py | tee bs_run/${cfg}_${run}.txt

        [ -d numpy_run ] ||mkdir -p numpy_run
        python numpy-benchmarks/run.py -t python | tee numpy_run/${cfg}_${run}.txt

        [ -d python_run ] || mkdir python_run
        pyperformance run -o python_run/${cfg}_${run}.json 2>&1
    done
done
