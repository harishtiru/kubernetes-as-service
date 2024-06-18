import requests
import random

def get_available_hosts(consul_address):
    url = f"http://{consul_address}/v1/catalog/service/esxi-host"
    response = requests.get(url)
    if response.status_code == 200:
        return [host['ServiceAddress'] for host in response.json()]
    else:
        print(f"Failed to retrieve available hosts: {response.text}")
        return []

def select_host(available_hosts):
    return random.choice(available_hosts) if available_hosts else None

# Example usage
consul_address = "172.28.8.100:8500"
available_hosts = get_available_hosts(consul_address)
if available_hosts:
    selected_host = select_host(available_hosts)
    print(f"Selected host: {selected_host}")
    # Save the selected host to a file for Terraform to use
    with open('selected_host.txt', 'w') as f:
        f.write(selected_host)
else:
    print("No available hosts found.")
