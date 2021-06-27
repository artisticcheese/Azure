# escape=`

ARG WINDOWS_VERSION=ltsc2019

#
# Builder Image - Windows Server Core
#
FROM mcr.microsoft.com/windows/servercore:$WINDOWS_VERSION as builder

# The FLUENTBIT_VERSION ARG must be after the FROM instruction
ARG FLUENTBIT_VERSION=1.7.9

#
# Basic setup
#
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

RUN Write-Host ('Creating folders'); `
   New-Item -Type Directory -Path /local; `
   New-Item -Type Directory -Path /fluent-bit;

WORKDIR /local

#
# Install Fluent Bit
#
RUN Write-Host ('Installing Fluent Bit'); `
   $majorminor = ([Version]::Parse("$env:FLUENTBIT_VERSION")).toString(2); `
   Invoke-WebRequest -Uri "https://fluentbit.io/releases/$($majorminor)/td-agent-bit-$($env:FLUENTBIT_VERSION)-win64.zip" -OutFile td-agent-bit.zip; `
   Expand-Archive -Path td-agent-bit.zip -Destination /local/fluent-bit; `
   Move-Item -Path /local/fluent-bit/*/* -Destination /fluent-bit/;

#
# Technique from https://github.com/StefanScherer/dockerfiles-windows/blob/master/mongo/3.6/Dockerfile
#
ADD https://aka.ms/vs/15/release/vc_redist.x64.exe /local/vc_redist.x64.exe

RUN Write-Host ('Installing Visual C++ Redistributable Package'); `
   Start-Process /local/vc_redist.x64.exe -ArgumentList '/install', '/quiet', '/norestart' -NoNewWindow -Wait; `
   Copy-Item -Path /Windows/System32/msvcp140.dll -Destination /fluent-bit/bin/; `
   Copy-Item -Path /Windows/System32/vccorlib140.dll -Destination /fluent-bit/bin/; `
   Copy-Item -Path /Windows/System32/vcruntime140.dll -Destination /fluent-bit/bin/;

#
# Runtime Image - Windows Server Nano
#
FROM mcr.microsoft.com/windows/servercore:$WINDOWS_VERSION as runtime

COPY --from=builder /fluent-bit /fluent-bit

RUN setx /M PATH "%PATH%;C:\fluent-bit\bin"

ENTRYPOINT ["fluent-bit.exe", "-i", "dummy", "-o", "stdout"]