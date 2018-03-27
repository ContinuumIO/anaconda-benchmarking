set -ex

ln -sf /usr/bin/python3 /usr/bin/python

for cfg in pip3 anaconda3 intel3
do
    if [ "$cfg" != "pip3" ]; then
        source /opt/conda/bin/activate /envs/$cfg/
        conda install -y numexpr
    else
        pip3 install numexpr
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

        [ -d python_run ] || mkdir python_run
        pyperformance run -o python_run/${cfg}_${run}.json 2>&1

        [ -d mkl_run_${run} ] || mkdir mkl_run_${run}
        pushd mkl_run_${run}
        python3 ../mkl-optimizations-benchmarks/bench.py $cfg 2>&1
        popd
    done
done
