from glob import glob
import os
import re
import numpy as np

# https://regex101.com/r/d25Akk/1
parse_tests_re = re.compile(r'^\|\s([\w\d]+)\s*\|\s((?:[\d.]+\s[mnsu]\w+?)|(?:not\s\w+?))\s*\|\s((?:[\d.]+\s[mnsu]\w+?:\s.*?)|(?:not\s\w+?))\s*\|\s((?:[\d.]+\s[mnsu]\w+?:\s.*?)|(?:not\s\w+?))\s*\|',
                            re.M)

multipliers = {
    'sec': 1,
    'ms': 1/1000.0,
    'us': 1/1.0E6,
    'ns': 1/1.0E9,
    }


def parse_time(time_str):
    if time_str.startswith('not'):
        value = None
    else:
        time = time_str.split(':')[0]
        number, units = time.split()
        value = float(number) * multipliers[units]
    return value


def get_test_times(tests_dict, text_block):
    matches = parse_tests_re.findall(text_block)
    for match in matches:
        key = match[0]
        vals = tests_dict.get(key, {})
        # ensure that the key exists
        tests_dict[key] = vals
        pip_vals = vals.get('pip', [])
        pip_vals.append(parse_time(match[1]))
        tests_dict[key]['pip'] = pip_vals
        anaconda_vals = vals.get('anaconda', [])
        anaconda_vals.append(parse_time(match[2]) or pip_vals[-1])
        tests_dict[key]['anaconda'] = anaconda_vals
        intel_vals = vals.get('intel', [])
        intel_vals.append(parse_time(match[3]) or pip_vals[-1])
        tests_dict[key]['intel'] = intel_vals


def load_files(dirname=os.getcwd()):
    files = glob(os.path.join(dirname, '*.txt'))
    for f in files:
        with open(f) as fh:
            d = fh.read()
        yield d


if __name__ == '__main__':
    tests_dict = {}
    for f in load_files():
        get_test_times(tests_dict, f)
    for k, cfgs in tests_dict.items():
        best = [min(cfgs[cfg_key]) for cfg_key in ('pip', 'anaconda', 'intel')]
        stdev = [np.std(cfgs[cfg_key]) for cfg_key in ('pip', 'anaconda', 'intel')]
        print(k, best, stdev)
