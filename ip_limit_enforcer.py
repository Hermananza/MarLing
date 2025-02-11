import requests
import time
from collections import defaultdict

XRAY_API = "http://127.0.0.1:6270"
USER_IP_LIMIT = 2  # Max allowed IPs per user

def get_active_connections():
    try:
        res = requests.get(f"{XRAY_API}/stats").json()
        return res.get("stat", [])
    except:
        return []

def enforce_ip_limits():
    connections = get_active_connections()
    user_ips = defaultdict(set)

    # Track IPs per user
    for conn in connections:
        if conn["name"].startswith("user>>>"):
            user = conn["name"].split(">>>")[1]
            ip = conn["dest"].split(":")[0]
            user_ips[user].add(ip)

    # Enforce limits (e.g., disconnect excess IPs)
    for user, ips in user_ips.items():
        if len(ips) > USER_IP_LIMIT:
            print(f"User {user} exceeded IP limit. Disconnecting...")
            # Use Marzban's API to revoke user sessions (custom logic required)

while True:
    enforce_ip_limits()
    time.sleep(60)  # Check every 60 seconds
