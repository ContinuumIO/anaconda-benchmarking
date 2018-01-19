set -ex

rm -rf *_run
ln -sf /usr/bin/python3 /usr/bin/python

for cfg in pip3 anaconda3 intel3
do
    if [ "$cfg" != "pip3" ]; then
        source /envs/$cfg/bin/activate /envs/$cfg/
    fi
    python3 -V

    #for run in 1 2 3 4 5
    for run in 1 2
    do
        echo "Starting run $run at $(date)"

        [ -d blas_gemm_run ] || mkdir -p blas_gemm_run
	pushd blas-benchmarks/benchmarks
        python3 benchmark_gemm.py -t python |& tee ../../blas_gemm_run/${cfg}_${run}.txt
        popd

        [ -d blas_ufunc_run ] || mkdir -p blas_ufunc_run
	pushd blas-benchmarks/benchmarks
        python3 benchmark_gemm.py -t python |& tee ../../blas_ufunc_run/${cfg}_${run}.txt
        popd
    done
done
