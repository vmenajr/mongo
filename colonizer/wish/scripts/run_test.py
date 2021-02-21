import json
from bson.json_util import dumps
import paramiko
import argparse
import yaml
import pymongo
import concurrent.futures
import os
import datetime
from pymongo import MongoClient
import time
import subprocess
import multiprocessing
from datetime import timedelta

os_user = 'colonizer'
# for testing
#os_user = 'ubuntu'
home_dir = '/home/' + os_user + '/'
ssh_dir = home_dir + '.ssh/'
ycsb_dir = home_dir + 'ycsb-0.12.0/'
#ycsb_dir = home_dir + 'YCSB-master/ycsb-mongodb/'
test_result_dir = 'test_results/'
dbpath = '/data'
servers = {}
servers_list = []
servers_file = 'cluster.json'
test_file = 'hosts_sharded_cluster.json'
workload_template = 'workload_template'
hosts_per_shard = 3
device_shard = '/dev/nvme0n1'
device_other = '/dev/xvdg'
all_mongodb_roles = ['configs', 'shards', 'mongos', 'replica_set', 'standalone']
all_mongodb_roles_reverse = ['standalone', 'replica_set', 'mongos', 'shards', 'configs']
all_roles = all_mongodb_roles + ['clients']
logpath = '/data/logs/'
other_client = 'false'
num_of_clients = ["4", "8", "16", "32"]
#num_of_clients = ["2", "4"]

def get_hosts():
    servers_list = []
    mongos_list = []
    with open(servers_file) as data_file:
        servers = json.load(data_file)
    with open(test_file) as tests:
        hosts = json.load(tests)
    if 'client' in servers['inventory']['value']:
        hosts['clients'] = []
        for index, mv in enumerate(servers['inventory']['value']['client'][0]['private']):
            hosts['clients'].append({'hostname' : mv})
    if 'configs' in servers['inventory']['value']:
        hosts['configs'] = []
        for index, mv in enumerate(servers['inventory']['value']['configs'][0]['private']):
            if mv not in servers_list:
                servers_list.append(mv)
            config = { 'hostname' : mv, 'port': '27017', 'dbpath': '/data', 'logpath': '/data/mongo.log', 'role': 'config' }
            hosts['configs'].append(config)
    if 'mongos' in servers['inventory']['value']:
        hosts['mongos'] = []
        for index, mv in enumerate(servers['inventory']['value']['mongos'][0]['private']):
            if mv not in servers_list:
                servers_list.append(mv)
            mongos = { 'hostname' : mv, 'port': '27017', 'dbpath': '/data', 'logpath': '/data/mongo.log', 'role': 'mongos' }
            hosts['mongos'].append(mongos)
            mongos_list.append(mv + ':' + '27017')
            #hosts['mongodbUrl' + str(index+1)] = 'mongodb://' + ','.join(mongos_list) + hosts['url_options'];
            # Adjust the test to run with 6 mongos in the connection string
            #if index == 5: 
            #    hosts['mongodbUrl' + str(index+1)] = 'mongodb://' + ','.join(mongos_list) + hosts['url_options'];
        conn_str = 'mongodb://' + ','.join(mongos_list)
        hosts['mongodbUrl'] = conn_str + hosts['url_options'];
    if 'shards' in servers['inventory']['value']:
        hosts['shards'] = []
        shards = []
        for index, mv in enumerate(servers['inventory']['value']['shards'][0]['private']):
            shard_number = index / hosts_per_shard
            i = index - shard_number * hosts_per_shard
            shard = { 'hostname' : mv, 'port': '27017', 'dbpath': '/data', 'logpath': '/data/mongo.log', 'role': 'secondary', 'priority': 1 }
            if (index % hosts_per_shard == 0):
                shard['priority'] = 5
                shard['role'] = 'primary'
                hosts['shards'].append(shards)
                shards = []
            hosts['shards'][shard_number].append(shard)
            if mv not in servers_list:
                servers_list.append(mv)
    hosts['servers_list'] = servers_list
    with open(args.test_file, 'w') as data_file:
        json.dump(hosts, data_file, indent=4, sort_keys=True)

def setup_mongodb(hosts):
    config_list = []
    shards = []
    config_str = ""

    if 'configs' in hosts:
        repl_name = hosts['cluster_name'] + '_Cfg'
        for index, mv in enumerate(hosts['configs']):
            dbpath = hosts['dbpath'] +  '/' +repl_name + '_' + str(index) + '/'
            mv['dbpath'] = dbpath
            if (hosts['config_server_type'] == 'CSRS'):
                update_mongod_config(mv, dbpath, repl_name, 'configsvr', 'wiredTiger')
                ssh_exe(mv['hostname'], 'sudo blockdev --setra 0 ' + device_other)
            else:
                update_mongod_config(mv, dbpath, '', 'configsvr', hosts['storage_engine'])
                if hosts['storage_engine'].lower() == 'wiredtiger':
                    ssh_exe(mv['hostname'], 'sudo blockdev --setra 0 ' + device_other)
                else:
                    ssh_exe(mv['hostname'], 'sudo blockdev --setra 32 ' + device_other)
            config_file_no_auth = dbpath + mv['hostname'] + '.' + mv['port'] + '.no_auth.mongod.conf'
            config_file_auth = dbpath + mv['hostname'] + '.' + mv['port'] + '.auth.mongod.conf'
            if 'user' in hosts:
                mv['config_file'] = config_file_auth
            else:
                mv['config_file'] = config_file_no_auth
            ssh_exe(mv['hostname'], 'mongod -f ' + config_file_no_auth)
            config_list.append(mv['hostname'] + ':' + mv['port'])
        if (hosts['config_server_type'] == 'CSRS'):
            print('Wait for 10 seconds before initialing CSRS')
            time.sleep(10)
            init_repl(repl_name, hosts['configs'])
            config_str = repl_name + '/' + ','.join(config_list)
        else:
            config_str = ','.join(config_list)

    if 'shards' in hosts:
        for num, mv in enumerate(hosts['shards']):
            repl_name = hosts['cluster_name'] + '_Shard_' + str(num)
            shard_list = []
            for index, nv in enumerate(hosts['shards'][num]):
                dbpath = hosts['dbpath'] + '/' + repl_name + '_' + str(index) + '/'
                nv['dbpath'] = dbpath
                update_mongod_config(nv, dbpath, repl_name, 'shardsvr', hosts['storage_engine'])
                if hosts['storage_engine'].lower() == 'wiredtiger':
                    ssh_exe(nv['hostname'], 'sudo blockdev --setra 0 ' + device_shard)
                else:
                    ssh_exe(nv['hostname'], 'sudo blockdev --setra 32 ' + device_shard)
                config_file_no_auth = dbpath + nv['hostname'] + '.' + nv['port'] + '.no_auth.mongod.conf'
                config_file_auth = dbpath + nv['hostname'] + '.' + nv['port'] + '.auth.mongod.conf'
                if 'user' in hosts:
                    nv['config_file'] = config_file_auth
                else:
                    nv['config_file'] = config_file_no_auth
                ssh_exe(nv['hostname'], 'mongod -f ' + config_file_no_auth)
                shard_list.append(nv['hostname'] + ':' + nv['port'])
            print('Wait for 10 seconds before initialing shards')
            time.sleep(10)
            init_repl(repl_name, mv)
            shard = repl_name + '/' + ','.join(shard_list)
            shards.append(shard)
            if 'user' in hosts:
                conn_str = 'mongodb://' + ','.join(shard_list) + '/replicaSet=' + repl_name
                add_user_mongo(conn_str, hosts['user'], hosts['password'])
 
    if 'mongos' in hosts:
        mongos_list = []
        for index, mv in enumerate(hosts['mongos']):
            dbpath = hosts['dbpath'] + '/' + hosts['cluster_name'] + '_' + str(index) + '/'
            mv['dbpath'] = dbpath
            update_mongos_config(mv, dbpath, config_str)
            config_file_no_auth = dbpath + mv['hostname'] + '.' + mv['port'] + '.no_auth.mongos.conf'
            config_file_auth = dbpath + mv['hostname'] + '.' + mv['port'] + '.auth.mongos.conf'
            if 'user' in hosts:
                mv['config_file'] = config_file_auth
            else:
                mv['config_file'] = config_file_no_auth
            ssh_exe(mv['hostname'], 'mongos -f ' + config_file_no_auth)
            if index == 0:
                print('Wait for 10 seconds before adding shards')
                time.sleep(10)
                init_cluster(mv['hostname'], mv['port'], shards)
            mongos_list.append(mv['hostname'] + ':' + mv['port'])
            #hosts['mongodbUrl' + str(index+1)] = 'mongodb://' + ','.join(mongos_list) + hosts['url_options'];
            #if 'user' in hosts:
            #    hosts['mongodbUrl' + str(index+1)] = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + ','.join(mongos_list) + hosts['url_options'];
        conn_str = 'mongodb://' + ','.join(mongos_list) + hosts['url_options'];
        if 'user' in hosts:
            add_user_mongo(conn_str, hosts['user'], hosts['password']) 
            conn_str = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + ','.join(mongos_list) + hosts['url_options'];
        hosts['mongodbUrl'] = conn_str
    if 'replica_set' in hosts:
        member_list = []
        for index, mv in enumerate(hosts['replica_set']):
            dbpath = hosts['dbpath'] +  '/' + hosts['replica_set_name'] + '_' + str(index) + '/'
            mv['dbpath'] = dbpath
            update_mongod_config(mv, dbpath, hosts['replica_set_name'], '', hosts['storage_engine'])
            config_file_no_auth = dbpath + mv['hostname'] + '.' + mv['port'] + '.no_auth.mongod.conf'
            config_file_auth = dbpath + mv['hostname'] + '.' + mv['port'] + '.auth.mongod.conf'
            if 'user' in hosts:
                mv['config_file'] = config_file_auth
            else:
                mv['config_file'] = config_file_no_auth
            ssh_exe(mv['hostname'], 'mongod -f ' + config_file_no_auth)
            member_list.append(mv['hostname'] + ':' + mv['port'])
        init_repl(hosts['replica_set_name'], hosts['replica_set'])
        conn_str = 'mongodb://' + ','.join(member_list) + '/replicaSet=' + hosts['replica_set_name']
        if 'user' in hosts:
            add_user_mongo(conn_str, hosts['user'], hosts['password'])
            conn_str = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + ','.join(member_list) + '/replicaSet=' + hosts['replica_set_name']
        hosts['mongodbUrl'] = conn_str
            
    if 'standalone' in hosts:
        dbpath = hosts['dbpath'] + '/'
        hosts['standalone']['dbpath'] = dbpath
        update_mongod_config(hosts['standalone'], dbpath, '', '', hosts['storage_engine'])
        config_file_no_auth = dbpath + hosts['standalone']['hostname'] + '.' + hosts['standalone']['port'] + '.no_auth.mongod.conf'
        config_file_auth = dbpath + hosts['standalone']['hostname'] + '.' + hosts['standalone']['port'] + '.auth.mongod.conf'
        if 'user' in hosts:
            hosts['standalone']['config_file'] = config_file_auth
        else:
            hosts['standalone']['config_file'] = config_file_no_auth
        ssh_exe(hosts['standalone']['hostname'], 'mongod -f ' + config_file_no_auth)
        conn_str = 'mongodb://' + hosts['standalone']['hostname'] + ':' + hosts['standalone']['port']
        if 'user' in hosts:
            add_user_mongo(conn_str, hosts['user'], hosts['password'])
            conn_str = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + hosts['standalone']['hostname'] + ':' + hosts['standalone']['port']
        hosts['mongodbUrl'] = conn_str

    with open(test_file, 'w') as data_file:
        json.dump(hosts, data_file, indent=4, sort_keys=True)
    if 'user' in hosts:
        populate_keyFile(hosts)
        shutdown_mongodb_all(hosts)
        start_mongodb_all(hosts)
    geneate_test_file(hosts, test_file)

def geneate_test_file(hosts, test_file):
    cluster_name = hosts['cluster_name']
    for index, mv in enumerate(hosts['clients']):
        hosts['mongodbUrl1'] = 'mongodb://' + hosts['mongos'][index]['hostname'] + ':' + hosts['mongos'][index]['port'] + hosts['url_options'];
        if 'user' in hosts:
             hosts['mongodbUrl1'] = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + hosts['mongos'][index]['hostname'] + ':' + hosts['mongos'][index]['port'] + hosts['url_options'];
        with open('/tmp/'+ test_file, 'w') as data_file:
            json.dump(hosts, data_file, indent=4, sort_keys=True)
        scp_file(mv['hostname'], '/tmp/' + test_file, home_dir + test_file)

        for index2, nv in enumerate(num_of_clients):
            hosts['cluster_name'] = nv + 'clients_' + cluster_name
            filename = nv + 'clients_' + test_file
            with open('/tmp/'+ filename, 'w') as data_file:
                 json.dump(hosts, data_file, indent=4, sort_keys=True)
            scp_file(mv['hostname'], '/tmp/' + filename, home_dir + filename)

def populate_keyFile(hosts):
    os.system('openssl rand -base64 756 > ' + 'keyFile')
    os.system('chmod 400 ' + 'keyFile')
    for index, mv in enumerate(hosts['servers_list']):
        scp_file(mv, 'keyFile', home_dir + 'keyFile')
    run_cmd_all(hosts, 'chmod 400 ' + home_dir + 'keyFile', False)
     
def clean_dbpath(host):
    ssh_exe(host['hostname'], 'rm -rf ' + host['dbpath'])

def clean_dbpath_all(hosts):
    func_by_roles(hosts, all_mongodb_roles, clean_dbpath)

def shutdown_mongodb(host, user, password):
    if user == "":
        cmd = 'mongo --port ' + host['port'] + ' admin --eval "db.shutdownServer({force: true});"'
    else:
        cmd = 'mongo --port ' + host['port'] + ' --username ' + user + ' --password ' + password + ' admin --eval "db.shutdownServer({force: true});"'
    ssh_exe(host['hostname'], cmd)

def shutdown_mongodb_all(hosts):
    user = password = ''
    if 'user' in hosts:
        user = hosts['user']
        password = hosts['password']
    func_by_roles(hosts, all_mongodb_roles_reverse, shutdown_mongodb, user, password)

def start_mongodb(host, options):
    if host['role'] == 'mongos':
        ssh_exe(host['hostname'], 'mongos -f ' + host['config_file'] + ' ' + options)
    else:
        ssh_exe(host['hostname'], 'mongod -f ' + host['config_file'] + ' ' + options)

def start_mongodb_all(hosts):
    func_by_roles(hosts, all_mongodb_roles, start_mongodb, '')

def scp_file(hostname, source, target):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=os_user)
    sftp = ssh.open_sftp()
    try:
        sftp.put(source, target, callback=None)
    except IOError:
        pass
    ssh.close()
    
def ssh_exe(hostname, command):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print('host: ' + hostname)
    print('command: ' + command)
    ssh.connect(hostname, username=os_user)
    stdin, stdout, stderr = ssh.exec_command(command)
    print stdout.readlines()
    ssh.close()

def update_mongod_config(host, dbpath, repl_name, role, engine):
    with open("mongod.conf", 'r') as conf_file:
        data = yaml.load(conf_file)
    try:
        data['net']['port'] = host['port']
        if (repl_name != ''):
            data['replication'] = {}
            data['replication']['replSetName'] = repl_name
        if (role != ''):
            data['sharding'] = {} 
            data['sharding']['clusterRole'] = role
        data['storage']['dbPath'] = dbpath
        if (engine == "mmapv1"):
            data['storage']['engine'] = "mmapv1"
        else:
            data['storage']['engine'] = "wiredTiger"
            # set the cache size for testing
            #data['storage']['wiredTiger'] = { 'engineConfig' : { 'cacheSizeGB' : 1 } }
        cmd = 'mkdir -p ' + dbpath
        ssh_exe(host['hostname'], cmd)
        cmd = 'mkdir -p ' + logpath
        ssh_exe(host['hostname'], cmd)
        data['systemLog']['path'] = logpath + 'mongodb.log'
    except yaml.YAMLError as exc:
        print(exc)

    mongod_conf_file_no_auth =  host['hostname'] + '.' + host['port'] + '.no_auth.mongod.conf'
    with open('/tmp/' + mongod_conf_file_no_auth, 'w') as yaml_file:
        yaml_file.write( yaml.safe_dump(data, default_flow_style=False)) 
    target = dbpath + mongod_conf_file_no_auth
    scp_file(host['hostname'], '/tmp/' + mongod_conf_file_no_auth, target)

    data['security'] = {'authorization': 'enabled', 'keyFile': home_dir + 'keyFile' }
    mongod_conf_file_auth = host['hostname'] + '.' + host['port'] + '.auth.mongod.conf'
    with open('/tmp/' + mongod_conf_file_auth, 'w') as yaml_file:
        yaml_file.write( yaml.safe_dump(data, default_flow_style=False)) 
    target = dbpath + mongod_conf_file_auth
    scp_file(host['hostname'], '/tmp/' + mongod_conf_file_auth, target)

def init_repl(repl_name, repl_hosts):
    print ('initialize replica set')
    client = MongoClient(repl_hosts[0]['hostname'], int(repl_hosts[0]['port']))
    config = {'_id': repl_name, 'members': [] }
    for index, mv in enumerate(repl_hosts):
        member = {'_id': index, 'host': mv['hostname'] + ':' + mv['port']}
        if 'priority' in mv:
            member['priority'] = mv['priority']
        config['members'].append(member)
    try:
        client.admin.command("replSetInitiate", config)
    except Exception, e:
        print(e)
    client.close()

def update_mongos_config(host, dbpath, config_str):
    with open("mongos.conf", 'r') as conf_file:
        data = yaml.load(conf_file)
    try:
        cmd = 'mkdir -p ' + dbpath
        ssh_exe(host['hostname'], cmd)
        cmd = 'mkdir -p ' + logpath
        ssh_exe(host['hostname'], cmd)
        data['net']['port'] = host['port']
        data['systemLog']['path'] = logpath + 'mongodb.log'
        data['sharding']['configDB'] = config_str
    except yaml.YAMLError as exc:
        print(exc)

    mongos_conf_file_no_auth = host['hostname'] + '.' + host['port'] + '.no_auth.mongos.conf'
    with open('/tmp/' + mongos_conf_file_no_auth, 'w') as yaml_file:
        yaml_file.write( yaml.safe_dump(data, default_flow_style=False)) 
    target = dbpath + mongos_conf_file_no_auth
    scp_file(host['hostname'], '/tmp/' + mongos_conf_file_no_auth, target)

    data['security'] = {'keyFile': home_dir + 'keyFile' }
    mongos_conf_file_auth = host['hostname'] + '.' + host['port'] + '.auth.mongos.conf'
    with open('/tmp/' + mongos_conf_file_auth, 'w') as yaml_file:
        yaml_file.write( yaml.safe_dump(data, default_flow_style=False)) 
    target = dbpath + mongos_conf_file_auth
    scp_file(host['hostname'], '/tmp/' + mongos_conf_file_auth, target)

def init_cluster(hostname, port, shards):
    client = MongoClient(hostname, int(port))
    for index, mv in enumerate(shards):
        client.admin.command("addShard", mv)
        print ('adding shard: ' + mv)
    client.close()

def add_user_mongo(conn_str, user, password):
    client = MongoClient(conn_str)
    client.admin.add_user(user, password, roles=['root'])
    client.close()

def parse_workload_file(workload_file):
    workloads = {}
    with open(workload_file) as data_file:
        for line in data_file:
            key, value = line.partition("=")[::2]
            if key.strip() != '':
                workloads[key.strip()] = value.strip()
    return workloads

def write_workload_file(file_name, workloads):
    with open(file_name, 'w') as workload_file:
        for key, value in sorted(workloads.iteritems()):
            if key != '':
                workload_file.write(key + '=' + str(value) + '\n')

def load_data(hosts):
    workloads = parse_workload_file(workload_template) 
    del workloads['maxexecutiontime']
    # for testing
    #workloads['recordcount'] = '10000'
    now = datetime.datetime.utcnow().isoformat()
    test_run_dir = test_result_dir + hosts['cluster_name'] + '_' + now + '/' 
    print(test_run_dir)
    os.system('mkdir -p ' + test_run_dir + '/workloads')
    write_workload_file(test_run_dir + '/workloads/workload_load', workloads)

    client = MongoClient(hosts['mongodbUrl'])
    try:
        client.admin.command({ 'enableSharding' : 'ycsb' })
    except Exception, e:
        print(e)
    try:
        client.admin.command({ 'shardCollection' : 'ycsb.usertable', 'key': {'_id':'hashed'}})
    except Exception, e:
        print(e)
    client.config.settings.update( { '_id': 'balancer' }, { '$set' : { 'stopped': 'true' } }, upsert=True )
    client.close()
    cmd = ycsb_dir + '/bin/ycsb load mongodb -P ' + test_run_dir + 'workloads/workload_load -p mongodb.url=' + hosts['mongodbUrl1']
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = process. communicate() 
    with open (test_run_dir + '/load.ycsb.stdout', 'w') as stdout:
        stdout.write(out)
    with open (test_run_dir + '/load.ycsb.stderr', 'w') as stderr:
        stderr.write(err)
    print("data load completed")

def run_cmd_all(hosts, cmd, client):
    if 'servers_list' not in hosts:
        servers_list = {}
        if 'mongos' in hosts:
            for index, mv in enumerate(hosts['mongos']):
                if mv['hostname'] not in servers_list:
                    servers_list.append(mv['hostname'])
        if 'configs' in hosts:
            for index, mv in enumerate(hosts['configs']):
                if mv['hostname'] not in servers_list:
                    servers_list.append(mv['hostname'])
        if 'shards' in hosts:
            for num, mv in enumerate(hosts['shards']):
                for index, nv in enumerate(hosts['shards'][num]):
                    if nv['hostname'] not in servers_list:
                        servers_list.append(nv['hostname'])
        if 'replica_set' in hosts:
            for index, mv in enumerate(hosts['replica_set']):
                if mv['hostname'] not in servers_list:
                    servers_list.append(mv['hostname'])
        if 'standalone' in hosts:
            if hosts['standalone']['hostname'] not in servers_list:
                 servers_list.append(hosts['standalone']['hostname'])
    for index, mv in enumerate(hosts['servers_list']):
        ssh_cmd = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f ' +  mv + ' ' +  cmd
        print(ssh_cmd)
        process = subprocess.Popen(ssh_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if (client == True):
        for index, mv in enumerate(hosts['clients']):
            ssh_cmd = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -f ' +  mv['hostname'] + ' ' +  cmd
            print(ssh_cmd)
            process = subprocess.Popen(ssh_cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

def rotate_mongodb_logs(host, user, password):
    host_port = host['hostname'] + ':' + host['port']
    conn_str = 'mongodb://' + host_port
    if 'user' != '':
        conn_str = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + host_port
    client = MongoClient(conn_str)
    client.admin.command("logRotate")
    client.close()

def rotate_mongodb_logs_all(hosts):
    user = password = ''
    if 'user' in hosts:
        user = hosts['user']
        password = hosts['password']
    func_by_roles(hosts, all_mongodb_roles, rotate_mongodb_logs, user, password)

def clean_mongodb_logs(host):
    ssh_exe(host['hostname'], 'rm -rf ' + logpath + '/mongodb.log.*')

def clean_mongodb_logs_all(hosts):
    func_by_roles(hosts, all_mongodb_roles, clean_mongodb_logs)

def set_slowms(host, user, password):
    host_port = host['hostname'] + ':' + host['port']
    conn_str = 'mongodb://' + host_port
    if 'user' != '':
        conn_str = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + host_port
    client = MongoClient(conn_str)
    client.admin.command('profile', 0, slowms=-1)
    client.close()

def launchRemoteSadc(hosts, maxSeconds):
    run_cmd_all(hosts, '/usr/bin/pkill -u ' + os_user + ' sadc', True)
    run_cmd_all(hosts, '/bin/rm -f /tmp/sadc.out', True)
    run_cmd_all(hosts, '/usr/lib/sysstat/sadc -S XDISK 1 ' + str(maxSeconds) + ' /tmp/sadc.out', True)

def killCaptureRemoteSadc(hosts, test_run_dir):
    run_cmd_all(hosts, '/usr/bin/pkill -u ' + os_user + ' sadc', True)
    for index, mv in enumerate(hosts['servers_list']):
        os.system('mkdir -p ' + test_run_dir + '/' + mv)
        scp_get_file(mv, '/tmp/sadc.out', test_run_dir + '/' + mv + '/sadc.out')
    for index, mv in enumerate(hosts['clients']):
        os.system('mkdir -p ' + test_run_dir + '/' + mv['hostname'])
        scp_get_file(mv['hostname'], '/tmp/sadc.out', test_run_dir + '/' + mv['hostname'] + '/sadc.out')
    #run_cmd_all(hosts, '/bin/rm -f /tmp/sadc.out', True)

def scp_get_file(hostname, remotepath, localpath):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(hostname, username=os_user)
    sftp = ssh.open_sftp()
    try:
        sftp.get(remotepath, localpath, callback=None)
    except IOError:
        pass
    ssh.close()

def scp_mongodb_logs(host, test_run_dir):
    local_log_dir = test_run_dir + '/' + host['role'] + '_' + host['hostname'] + '_' + host['port']
    os.system('mkdir -p ' + local_log_dir)
    ssh_exe(host['hostname'], 'tar -cvzf ' + '/tmp/mongodblogs.tar.gz ' + logpath)
    os.system('scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q ' + host['hostname'] + ':/tmp/mongodblogs.tar.gz ' + local_log_dir)
    #os.system('scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q ' + host['hostname'] + ':' + logpath + '/mongodb.log* ' + local_log_dir)
    if host['role'] != 'mongos':
        os.system('mkdir -p ' + local_log_dir + '/diagnostic.data')
        os.system('scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q ' + host['hostname'] + ':' + host['dbpath'] + '/diagnostic.data/* ' + local_log_dir + '/diagnostic.data/')

def scp_mongodb_logs_all(hosts, test_run_dir):
    func_by_roles(hosts, all_mongodb_roles, scp_mongodb_logs, test_run_dir)

def check_replication_lags(hosts):
    if 'shards' in hosts:
        while True:
            max_lag = 0
            max_lag_host = ''
            for num, mv in enumerate(hosts['shards']):
                hosts_ports = mv[0]['hostname'] + ':' + mv[0]['port'] + ',' + mv[1]['hostname'] + ':' + mv[1]['port']
                conn_str = 'mongodb://' + hosts_ports
                if 'user' in hosts:
                    conn_str = 'mongodb://' + hosts['user'] + ':' + hosts['password'] + '@' + hosts_ports
                client = MongoClient(conn_str)
                rsStatus = client.admin.command("replSetGetStatus")
                client.close()

                secondary_optimes = [];
                primary_optime = 0;
                for index, nv  in enumerate(rsStatus['members']):
                    if (nv['stateStr'] == "PRIMARY"):
                        primary_optime = nv['optimeDate']
                    elif ( nv['stateStr'] == "SECONDARY" ):
                        secondaryStat = {}
                        secondaryStat['name'] = nv['name']
                        secondaryStat['optime'] = nv['optimeDate']
                        secondary_optimes.append(secondaryStat)
                for index, nv in enumerate(secondary_optimes):
                    lag = timedelta.total_seconds(primary_optime - nv['optime'])
                    if (lag > max_lag): 
                        max_lag = lag
                        max_lag_host = nv['name']
            if (max_lag > 1):
                print( max_lag_host + " is lagging " + str(max_lag) + " seconds, waiting for 5 seconds")
                time.sleep(5)
            else:
                break

def collect_conn_pool_stats(host, test_run_dir, testx, user, password):

    local_log_dir = test_run_dir + '/' + host['role'] + '_' + host['hostname'] + '_' + host['port']

    host_port = host['hostname'] + ':' + host['port']
    conn_str = 'mongodb://' + host_port
    if 'user' != '':
        conn_str = 'mongodb://' + user + ':' + password + '@' + host_port
    client = MongoClient(conn_str)

    conn_pool_stats = client.admin.command('connPoolStats')
    with open (local_log_dir + '/' + testx + '_conn_pool_stats.json', 'a') as stats:
        stats.write('\n=== ' + datetime.datetime.utcnow().isoformat() + '\n')
        stats.write(dumps(conn_pool_stats, indent=4))

    shard_conn_pool_stats = client.admin.command('shardConnPoolStats')
    with open (local_log_dir + '/' + testx + '_shard_conn_pool_stats.json', 'a') as shard_stats:
        shard_stats.write('\n=== ' + datetime.datetime.utcnow().isoformat() + '\n')
        shard_stats.write(dumps(shard_conn_pool_stats, indent=4))

    client.close()

def collect_conn_pool_stats_all(hosts, test_run_dir, testx):
    user = password = ''
    if 'user' in hosts:
        user = hosts['user']
        password = hosts['password']
    while True:
        func_by_roles(hosts, ['mongos', 'shards'], collect_conn_pool_stats, test_run_dir, testx, user, password)
        time.sleep(30)

def func_by_roles(hosts, roles, func, *args):
    for role in roles:
        if role in hosts:
            if role == 'shards':
                for num, mv in enumerate(hosts[role]):
                    for index, nv in enumerate(hosts[role][num]):
                        func(nv, *args)
            else:
                for index, mv in enumerate(hosts[role]):
                    func(mv, *args)

def create_log_dir(host, test_run_dir):
    print(host)
    local_log_dir = test_run_dir + '/' + host['role'] + '_' + host['hostname'] + '_' + host['port']
    os.system('mkdir -p ' + local_log_dir)

def create_log_dir_all(hosts, test_run_dir):
    func_by_roles(hosts, all_mongodb_roles, create_log_dir, test_run_dir)

def run_workloads(hosts, test_run_dir):
    num_shard = 1
    workload_dir = test_run_dir + 'workloads/'
    os.system('mkdir -p ' + workload_dir)
    stats_dir = test_run_dir + 'stats/'
    os.system('mkdir -p ' + stats_dir)
    if 'shards' in hosts:
        num_shard = len(hosts['shards'])
    i = 1
    # Adjust this number to run the tests with 6 mongos in the connection string
    #i = 6
    while True:
        if 'mongodbUrl' + str(i) in hosts:
            if i != 1:
            # Adjust this number to run the tests with 6 mongos in the connection string
            #if i != 6:
                time.sleep(120)
            print('mongodbUrl: ' + hosts['mongodbUrl' + str(i)])
            for index1, mv in enumerate(hosts['workloads']):
                workloads = parse_workload_file(workload_template) 
                for key, value in mv.iteritems():
                    workloads[key] = value
                for index2, nv in enumerate(hosts['threads']):
                    check_replication_lags(hosts)
                    time.sleep(30)
                    if other_client != "true":
                        rotate_mongodb_logs_all(hosts)
                    workloads['threadcount'] = nv * num_shard
                    workload_file = 'workload_' + str(index1) + '_' + str(index2) + '_' + str(nv)
                    write_workload_file(workload_dir + workload_file, workloads)
                    with open (stats_dir + '/' + str(i) + '_mongos_' + workload_file + '.ycsb.stats', 'a') as stats:
                        stats.write('Test started at: ' + datetime.datetime.utcnow().isoformat() + '\n')
                    print('Running workload:' + str(index1) + ' threads: ' + str(nv))
                    if other_client != "true":
                        p = multiprocessing.Process(target=collect_conn_pool_stats_all, args=(hosts, test_run_dir, str(i) + '_mongos_' + workload_file))
                        p.start()
                    cmd = ycsb_dir + '/bin/ycsb run mongodb -P ' + workload_dir + workload_file + ' -p mongodb.url="' + hosts['mongodbUrl' + str(i)] + '"'
                    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    out, err = process. communicate() 
                    with open (stats_dir + '/' + str(i) + '_mongos_' + workload_file + '.ycsb.stdout', 'w') as stdout:
                        stdout.write(out)
                    with open (stats_dir + '/' + str(i) + '_mongos_' + workload_file + '.ycsb.stderr', 'w') as stderr:
                        stderr.write(err)
                    with open (stats_dir + '/' + str(i) + '_mongos_' + workload_file + '.ycsb.stats', 'a') as stats:
                        stats.write('Test completed at: ' + datetime.datetime.utcnow().isoformat() + '\n')
                    if other_client != "true":
                        p.terminate()
                    time.sleep(30)
            i += 1
        else:
            break

def scp_ycsb_stats(hosts, test_run_dir):
    all_ycsb_stats_dir = test_run_dir + '/all_ycsb_stats/'
    os.system('mkdir -p ' + all_ycsb_stats_dir)
    for index, mv in enumerate(hosts['clients']):
        stats_dir = all_ycsb_stats_dir + mv['hostname']
        os.system('mkdir -p ' + stats_dir)
        os.system('scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -q ' + mv['hostname'] + ':' + test_run_dir  + '/stats/* ' + stats_dir)

def run_tests(hosts):
    now = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%S-%f")
    test_run_dir = test_result_dir + hosts['cluster_name'] + '/'
    os.system('mkdir -p ' + test_run_dir)

    if other_client != "true":
        rotate_mongodb_logs_all(hosts)
        clean_mongodb_logs_all(hosts)
        launchRemoteSadc(hosts, 600000)
        create_log_dir_all(hosts, test_run_dir)
    try:
        check = raw_input('Press Enter to start the tests')
    except EOFError:
        print ("Error: EOF or empty input!")
        check = ""
    print check
    
    run_workloads(hosts, test_run_dir)

    if other_client != "true":
        killCaptureRemoteSadc(hosts, test_run_dir);
        scp_mongodb_logs_all(hosts, test_run_dir) 
        if (len(hosts['clients']) > 1): 
            scp_ycsb_stats(hosts, test_run_dir)

        print('!!!!!!!!!!!!!!!!!!!!!')
        print('Test results are in ' + hosts['clients'][0]['hostname'] + ':' + home_dir + test_run_dir + ', please copy them to a safe place otherwise they will be lost when the client machine is destroy.')
        print('!!!!!!!!!!!!!!!!!!!!!')

def get_logs(hosts, test_run_dir):
    os.system('mkdir -p ' + test_run_dir)
    killCaptureRemoteSadc(hosts, test_run_dir);
    scp_mongodb_logs_all(hosts, test_run_dir) 

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-s', '--servers_file', help='servers json file, generated by "terraform output -json"')
    parser.add_argument('-t', '--test_file', help='test json file. It includes the information for the MongoDB deployment, like storage engine, authentication, config server type, and the information related to YCSB testing, like workloads, threads')
    parser.add_argument('-a', '--actions', help='the actions: it can be get_hosts, clean, start, stop, setup_mongodb, load, run')
    parser.add_argument('-e', '--storage_engine', help='storage engine. It can be mmapv1 or wiredTiger')
    parser.add_argument('-u', '--user', help='user name for the MongoDB deployment. If specified, it will create the deployment with authentication enabled')
    parser.add_argument('-p', '--password', help='password for the MongoDB deployment. If user name is specified, but password is not specified, it will use the user name as the password')
    parser.add_argument('-c', '--config_server_type', help='the type of the config server. It can be SCCC or CSRS')
    parser.add_argument('-n', '--cluster_name', help='name for the cluster. It will be used as part of the dbpath, test result path')
    parser.add_argument('-w', '--workload_template', help='workload file')
    parser.add_argument('-o', '--other_client', help='the flag to set whether this is not the main client. If so, we will not collect stats from mongod')
    args = parser.parse_args()

    if args.servers_file:
        servers_file = args.servers_file
    if args.test_file:
        test_file = args.test_file
    with open(test_file) as tests:
        hosts = json.load(tests)

    if args.storage_engine:
        if args.storage_engine.lower() == "mmap" or args.storage_engine.lower() == "mmapv1":
            hosts['storage_engine'] = 'mmapv1'
        if args.storage_engine.lower() == "wt" or args.storage_engine.lower() == "wiredtiger":
            hosts['storage_engine'] = 'wiredTiger'

    if args.user:
        hosts['user'] = args.user
        if args.password:
            hosts['password'] = args.password
        else:
            hosts['password'] = args.user

    if args.cluster_name:
        hosts['cluster_name'] = args.cluster_name
    
    if args.config_server_type:
        if args.config_server_type.lower() == 'sccc':
            hosts['config_server_type'] = 'SCCC'
        if args.config_server_type.lower() == 'csrs':
            hosts['config_server_type'] = 'CSRS'

    if args.workload_template:
        workload_template = args.workload_template

    if args.other_client:
        other_client = args.other_client

    if args.actions:
        actions = args.actions.split(',')
        for index, mv in enumerate(actions):
            if mv == "all":
                get_hosts(hosts)
                setup_mongodb(hosts)
                load_data(hosts)
                run_tests(hosts)
            if mv == "get_hosts":
                get_hosts()
            if mv == "setup_mongodb":
                setup_mongodb(hosts)
            if mv == "start":
                start_mongodb_all(hosts)
            if mv == "shutdown":
                shutdown_mongodb_all(hosts)
            if mv == "clean":
                shutdown_mongodb_all(hosts)
                clean_dbpath_all(hosts)
            if mv == "load":
                load_data(hosts)
            if mv == "run":
                run_tests(hosts)
            if mv == "restart_mongos_no_auto_split":
                user = password = ''
                if 'user' in hosts:
                    user = hosts['user']
                    password = hosts['password']
                func_by_roles(hosts, ['mongos'], shutdown_mongodb, user, password)
                func_by_roles(hosts, ['mongos'], start_mongodb, '--noAutoSplit')
            if mv == "get_logs":
                get_logs(hosts)
            if mv == "set_slowms":
                user = password = ''
                if 'user' in hosts:
                    user = hosts['user']
                    password = hosts['password']
                func_by_roles(hosts, ['shards'], set_slowms, user, password)


