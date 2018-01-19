set -ex

rm -rf *_run
ln -sf /usr/bin/python3 /usr/bin/python

for cfg in pip3 anaconda3 intel3
do
    if [ "$cfg" != "pip3" ]; then
        source /envs/$cfg/bin/activate /envs/$cfg/
    fi
    python3 -V
    perl hardening_check.pl $(which python3) | tee security_$cfg.txt

    for run in 1 2 3 4 5
    do
        echo "Starting run $run at $(date)"

        [ -d bs_run ] || mkdir -p bs_run
        pushd BlackScholes_bench
        python3 bs_erf_numpy.py |& tee ../bs_run/${cfg}_${run}.txt
        popd

        [ -d numpy_run ] || mkdir -p numpy_run
        python3 numpy-benchmarks/run.py -t python |& tee numpy_run/${cfg}_${run}.txt

        [ -d python_run ] || mkdir python_run
        pyperformance run -o python_run/${cfg}_${run}.json 2>&1
    done
done
