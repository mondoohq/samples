# Mondoo Hacking Demos

This Repo contains a couple Demo/Hacks to have some nice Mondoo demos

- [container-escape](container-escape): contains two different demos for a container escape within a kubernetes cluster
  - [dvwa-example](container-escape/dvwa-example/): Damn vulnerable application with container escape in minikube/ eks and gke
  - [gitlab-example](container-escape/gitlab-example/): Vulnerable gitlab application with container escape in minikube
  - [terraform to deploy eks with container escape demo](container-escape/terraform/aws/): Terraform template to deploy a eks kubernetes cluster in aws with the dvwa container escape demo
- [dod](dod-amsterdam-hacklab): Contains terraform template to deploy a vulnerable Windows 2016, ubuntu 20.04 with minikube and a kali machine
- [mondoo-tf-static-analysis-demo](mondoo-tf-static-analysis-demo): Mondoo Terraform template scanning demo
- [pwnkit-CVE-2021-4034](pwnkit-CVE-2021-4034): Mondoo Demo for pwnkit vulnerablity

## Contributors + Kudos

* Scott Ford [scottford-io](https://github.com/scottford-io)
* Yvo Vandoorn [yvovandoorn](https://github.com/yvovandoorn)
* Dominik Richter [arlimus](https://github.com/arlimus)
* Christoph Hartmann [chris-rock](https://github.com/chris-rock)
* Patrick Münch [atomic111](https://github.com/atomic111)

Thanks to all of you!!

## License and Author

* Author:: Mondoo Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## Disclaimer

This or previous program is for Educational purpose ONLY. Do not use it without permission. The usual disclaimer applies, especially the fact that we (Mondoo Inc) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (dataloss, system crash, system compromise, etc.) caused by the use of these programs is not Mondoo Inc's responsibility.
