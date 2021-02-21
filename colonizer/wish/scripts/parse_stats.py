import argparse
import csv
from os import listdir
import os
from os.path import isfile, join, splitext
import re

#workloads = ['100R_0U', '90R_10U', '80R_20U', '50R_50U', '0R_100U']
workloads = ['90R_10U']

def getStat(key, inputs):
    value = "0"
    for x in inputs:
        if x.startswith(key):
            value = x.replace(key, "").strip()
    return value

def formatTime(time):
    return splitext(time)[0]

def getStartEndFromFile(f):

    stat_file = splitext(f)[0]+".stats"
    result = None
    with open(stat_file) as inputs:
        lines = inputs.read().splitlines()
        start = getStat("Test started at: ", lines)
        end = getStat("Test completed at: ", lines)
        result = [formatTime(start), formatTime(end)]
        #print(result)
    return result

def getHostFromFileName(index, f):
    #all_ycsb_stats/ip-10-1-1-127.ap-southeast-2.compute.internal/1_mongos_workload_0_0_2.ycsb.stdout
    if index is None:
        return []
    else:
        return [f.split("/")[index]]


def getStatsFromFileName(f):
    m = re.search("(\d+)_mongos_workload_(\d+)_(\d+)_(\d+)\.ycsb\.stdout", f)
    n_m = m.group(1)
    w = m.group(2)
    n_t = m.group(4)
    return [n_m, workloads[int(w)], n_t, n_m + ' mongos, ' + workloads[int(w)] + ', ' + n_t + 'threads/shard']

def getStatsFromFile(f):
    result = None
    with open(f) as inputs:
        stats = inputs.read().splitlines()
        tp = getStat("[OVERALL], Throughput(ops/sec),", stats)
        time = getStat("[OVERALL], RunTime(ms),", stats)
        r_t = getStat("[READ], Operations,", stats)
        r_a = getStat("[READ], AverageLatency(us),", stats)
        r_95 = getStat("[READ], 95thPercentileLatency(us),", stats)
        r_99 = getStat("[READ], 99thPercentileLatency(us),",stats)
        r_min = getStat("[READ], MinLatency(us),",stats)
        r_max = getStat("[READ], MaxLatency(us),", stats)
        r_err = getStat("[READ], Return=ERROR,", stats)
        u_t = getStat("[UPDATE], Operations,", stats)
        u_a = getStat("[UPDATE], AverageLatency(us),", stats)
        u_95 = getStat("[UPDATE], 95thPercentileLatency(us),", stats)
        u_99 = getStat("[UPDATE], 99thPercentileLatency(us),", stats)
        u_min = getStat("[UPDATE], MinLatency(us),", stats)
        u_max = getStat("[UPDATE], MaxLatency(us),", stats)
        u_err = getStat("[UPDATE], Return=ERROR,", stats)

        #convert//
        r_t = str(float(r_t) * 1000 / float(time))
        u_t = str(float(u_t) * 1000 / float(time))
        result = [tp, r_t, r_a, r_95, r_99, r_min, r_max, r_err, u_t, u_a, u_95, u_99, u_min, u_max, u_err]
    return result

def only_files(mypath):
    return [val for sublist in [[os.path.join(i[0], j) for j in i[2]] for i in os.walk(mypath)] for val in sublist]

def sort_files(files):
    return sorted(files, key=lambda f: os.path.basename(f))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--result_dir', help='directory for the test results')
    parser.add_argument('-i', '--ip_index', help='directory for the test results')
    args = parser.parse_args()

    if args.result_dir:
        result_dir = args.result_dir

    if args.ip_index:
        ip_index = int(args.ip_index)
    else :
        ip_index = None



    #stats_files = [f for f in listdir(result_dir) if (isfile(join(result_dir, f)) & bool(re.match("\d+_mongos_workload_\d+_\d+_\d+\.ycsb\.stdout", f)))]
    stats_files = sort_files([ i for i in only_files(result_dir) if i.endswith("stdout") ])

    #for i in stats_files :
        #print(i)

    header = [
        "Number of mongos",
        "Workload",
        "Number of threads per shard",
        "Case",
        "Start Time",
        "End Time",
        "Throughput (ops/sec)",
        "Read throughput (ops/sec)",
        "Read Average Latency (us)",
        "Read-95th (us)",
        "Read-99th (us)",
        "Read-min (us)",
        "Read-max (us)",
        "Read-errors",
        "Update-throughput (ops/sec)",
        "Update Average Latency (us)",
        "Update-95th (us)",
        "Update-99th (us)",
        "Update-min (us)",
        "Update-max (us)",
        "Update-errors"
    ]

    if ip_index is not None:
        header = ["Host"] + header

    with open(result_dir + '/ycsb_stats.csv', 'w') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(header)
        for index, mv in enumerate(stats_files):
            result = getHostFromFileName(ip_index, mv)+getStatsFromFileName(mv) + getStartEndFromFile(mv)+getStatsFromFile(mv)
            #print(result)
            writer.writerow(result)
    print('ycsb stats in csv format is saved to: ' + result_dir + '/ycsb_stats.csv')
