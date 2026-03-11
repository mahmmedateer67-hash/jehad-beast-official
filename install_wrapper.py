import os
import subprocess
import sys

# Remote Control Check (Kill Switch)
REMOTE_CONTROL_URL = "https://raw.githubusercontent.com/mahmmedateer67-hash/jehad-beast-control/main/status.txt"

def check_status():
    try:
        import requests
        res = requests.get(REMOTE_CONTROL_URL, timeout=5)
        if res.text.strip().lower() == "off":
            print("\033[91m[!] This script has been disabled by the developer.\033[0m")
            sys.exit(1)
    except:
        pass # If offline, continue but log or handle as needed

def run_install():
    # This will execute the main install logic
    # In a real scenario, the bash content would be embedded or compiled
    subprocess.run(["bash", "/etc/jehad/install.sh"])

if __name__ == "__main__":
    check_status()
    run_install()
