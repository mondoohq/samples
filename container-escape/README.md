# Container escape

The dvwa and gitlab demo have the following hacking procedure

- hack the web application with a vulnerability
- do a privilege escalation to gain root rights within the container
- do a container escape to get a root shell on the container host

![Attack picture](images/attack-graph.png)

## Disclaimer

This or previous program is for Educational purpose ONLY. Do not use it without permission. The usual disclaimer applies, especially the fact that we (Mondoo Inc) is not liable for any damages caused by direct or indirect use of the information or functionality provided by these programs. The author or any Internet provider bears NO responsibility for content or misuse of these programs or any derivatives thereof. By using these programs you accept the fact that any damage (dataloss, system crash, system compromise, etc.) caused by the use of these programs is not Mondoo Inc's responsibility.
