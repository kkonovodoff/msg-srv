import yaml
import sys

with open(r'./config') as file:
    config = yaml.full_load(file)
        
config["clusters"][0]["cluster"]["server"] = "https://" + str(sys.argv[1]) + ":6443"
config["clusters"][0]["name"] = "cluster-" + str(sys.argv[2])
config["contexts"][0]["context"]["cluster"] = "cluster-" + str(sys.argv[2])
config["contexts"][0]["context"]["user"] = "user-" + str(sys.argv[2])
config["contexts"][0]["name"] = str(sys.argv[2]) + "@kubernetes"
config["users"][0]["name"] = config["contexts"][0]["context"]["user"]

with open(r'./config', 'w') as file:
    document = yaml.dump(config, file)