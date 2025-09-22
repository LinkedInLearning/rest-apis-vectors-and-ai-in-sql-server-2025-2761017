# SQL Server
# Download and create ISO
if((Test-Path 'c:\temp') -eq $false) { mkdir c:\temp }
Invoke-WebRequest -Uri 'https://go.microsoft.com/fwlink/?linkid=2314611' -OutFile 'C:\Temp\SQL2025.exe'
c:\temp\sql2025.exe /ACTION=DOWNLOAD /MediaType=ISO /Language=en-US /MediaPath=C:\Temp /quiet
# Mount and install
Mount-DiskImage C:\temp\SQLServer2025-x64-ENU.iso
$drive = (Get-Volume | Where-Object { $_.DriveType -eq 'CD-ROM' } | Sort-Object DriveLetter | Select-Object -First 1).DriveLetter
$adminuser=[System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$setup_cmd="$drive`:\setup.exe /Q /INDICATEPROGRESS /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=MSSQLSERVER /TCPENABLED=1 /SQLSYSADMINACCOUNTS=""" + $adminuser + """"
Invoke-Expression $setup_cmd

# Install Choco
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install Tools
choco install ollama -y 
choco install openssl -y
choco install nginx -y --params '"/installLocation:C:\nginx"'

# Refresh Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Let's generate some config files
if (Test-Path C:\config) { Remove-Item C:\config -Recurse -Force }
mkdir C:\Config

@'
worker_processes auto;

events {
    worker_connections 1024;
}

http {
    upstream ollama {
        server 127.0.0.1:11434; 
    }

    server {
        listen 443 ssl;
        server_name ollama.my-linkedin-ai-course.local;

        ssl_certificate "C:/certs/nginx.crt";
        ssl_certificate_key "C:/certs/nginx.key";
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!MD5;

        location / {
            proxy_pass http://ollama;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Origin '';
            proxy_set_header Referer '';
            proxy_connect_timeout 300;
            proxy_send_timeout 300;
            proxy_read_timeout 300;
            send_timeout 300;
        }
    }
}
'@ | Set-Content C:\config\nginx.conf 

@'
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = US
ST = MS
L = Somewhere
O = IT
OU = DBATeam
CN = my-linkedin-ai-course.local

[v3_req]
subjectAltName = @alt_names

[alt_names]
IP.1 = 127.0.0.1
DNS.1 = localhost
DNS.2 = ollama.my-linkedin-ai-course.local
'@ | Set-Content C:\config\openssl.cnf

# Certs
mkdir C:\Certs
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout C:\certs\nginx.key -out C:\certs\nginx.crt -config C:\config\openssl.cnf
$certPath = "C:\Certs\nginx.crt"
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store "Root", "LocalMachine"
$store.Open("ReadWrite")
$certificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $certPath
$store.Add($certificate)
$store.Close()

# nginx
$nginxDir = (Get-ChildItem -Path "C:\nginx" -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1).FullName
copy-item C:\config\nginx.conf $nginxDir\conf\nginx.conf
nssm restart nginx

# Add models to Ollama
ollama pull nomic-embed-text
ollama pull mxbai-embed-large
ollama pull mistral

# Test
$body = @{
    model = "nomic-embed-text"
    prompt = "test"
}  | ConvertTo-Json -Compress
# Ollama direct
(Invoke-WebRequest -Uri "http://localhost:11434/api/embeddings" -Method POST -Body $body).Content
# Ollama through reverse SSL
(Invoke-WebRequest -Uri "https://localhost/api/embeddings" -Method POST -Body $body).Content

# Test the SQL install
Invoke-SQLcmd -Query "SELECT @@ServerName,@@Version" -TrustServerCertificate

# Install addl. Tools
choco install vscode -y
choco install sql-server-management-studio -y
choco install dotnet-9.0-sdk -y

# Refresh Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
Install-PackageProvider -Name NuGet -Force
code --install-extension ms-toolsai.jupyter
code --install-extension ms-dotnettools.dotnet-interactive-vscode
code --install-extension ms-mssql.mssql