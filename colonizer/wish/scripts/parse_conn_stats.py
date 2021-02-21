from itertools import tee, izip
import argparse,json, os, re
from os import listdir, walk
from os.path import isfile, join
from pymongo import MongoClient

def only_files(mypath):
    return [val for sublist in [[os.path.join(i[0], j) for j in i[2]] for i in os.walk(mypath)] for val in sublist]

def window(iterable, size):
    iters = tee(iterable, size)
    for i in xrange(1, size):
        for each in iters[i:]:
            next(each, None)
    return list(izip(*iters))


def file_to_lines(fname):
    with open(fname) as f:
        content = f.readlines()
    lines = [x.strip() for x in content]
    return lines


def json_indexes(lines):
    index = [i for i, j in enumerate(lines) if j.startswith('===')]
    return window(index, 2)

def normalize_key(key):
    if key.startswith('$'):
       return  key.replace('$', '_').strip()
    return key
 

def merge_ts_to_json(start, end, lines):
    ts = lines[start][4:]
    json_data = json.loads('\n'.join(lines[(start+1):end]))
    for key in json_data:
        json_data[normalize_key(key)] = json_data.pop(key)
    json_data['ts'] = 'timestamp('+ts+')'
    return json_data


def generate_json_list(indexes, lines):
    return [merge_ts_to_json(start, end, lines) for (start, end) in indexes]



def file_to_json(f):
    lines = file_to_lines(f)
    indexes = json_indexes(lines)
    return generate_json_list(indexes, lines)

def parse_file_name(folder, f):
    #"files/primary_ip-10-1-1-42.ap-southeast-2.compute.internal_27017/5_mongos_workload_4_5_256_conn_pool_stats.json"

    #print("parse  file name  : " + f)
    m = re.search(folder+"/(.+)_(.+)_(\d+)/(\d+)_mongos_workload_(\d+)_(\d+)_(\d+)_(.+).json", f)
    result = {
        "role":m.group(1),
        "host":m.group(2),
        "port":m.group(3),
        "mongos":m.group(4),
        "workload":m.group(5),
        "threads":m.group(7),
        "command":m.group(8),
    }
    return result


def is_valid_file(folder, f):
    print("checking file name is valid or not : " + f)
    m = re.search(folder+"/(.+)_(.+)_(\d+)/(\d+)_mongos_workload_(\d+)_(\d+)_(\d+)_(.+).json", f)
    return  (m is not None)

def all_valid_files(folder, fs):
    return [f for f in fs if is_valid_file(folder, f)]
 
def parse_file_and_file_name(folder, f):
    json_from_file_name = parse_file_name(folder, f)
    json_list_from_file  = file_to_json(f)
    #print ("json_from_file_name" + json_from_file_name)
    #print ("json_list_from_file" + json_list_from_file)
    return [dict(j, **json_from_file_name) for j in json_list_from_file]


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-d', '--src_dir', help='directory for the source folder')
    parser.add_argument('-m', '--mongodb_uri', help='MongoDB URI')
    args = parser.parse_args()

    if args.src_dir:
        result_dir = args.src_dir
    if args.mongodb_uri:
        uri = args.mongodb_uri

    client = MongoClient(uri)
    db = client['results']
    coll = db['coll_stats']

    for f in all_valid_files(result_dir, only_files(result_dir)):
        print("processing -->" + f)
        json_list = parse_file_and_file_name(result_dir, f)
        for j in json_list:
            #print json.dumps(j)
            coll.insert(j, check_keys=False)
    client.close()

