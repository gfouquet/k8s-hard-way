from pprint import pprint
import json
from jinja2 import Template

with open('../environments/dev/terraform.tfstate') as f:
    tfstate = json.load(f)

outputs = tfstate['modules'][0]['outputs']

kube_public_ip = outputs['kube_public_ip']['value']
# pprint(kube_public_ip)

masters = outputs['kube_masters']['value']
kube_masters = [
    {
        'name': name,
        'public_ip': masters['public_ips'][i],
        'private_ip': masters['private_ips'][i],
        'name_underscore': name.replace('-', '_')
    }
    for i, name in enumerate(masters['names'])
]
# pprint(kube_masters)

workers = outputs['kube_workers']['value']
kube_workers = [
    {
        'name': name,
        'public_ip': workers['public_ips'][i],
        'private_ip': workers['private_ips'][i],
        'pod_cidr': workers['pod_cidrs'][i],
        'name_underscore': name.replace('-', '_')
    }
    for i, name in enumerate(workers['names'])
]
# pprint(kube_workers)

with open('terraform.yml.j2') as tpl_file:
    template = Template(tpl_file.read())

# template.render(kube_masters)

template.stream({
    'kube_masters': kube_masters,
    'kube_workers': kube_workers,
    'kube_public_ip': kube_public_ip
}).dump('../playbooks/inventory/terraform.yml')