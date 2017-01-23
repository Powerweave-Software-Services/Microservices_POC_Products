#---------------------------------------------------------------------------------------------
# This line below indicates that the base image for the current image 
# that we are building is microsoft/iis:TP5. You see the syntax for the version of
# TP5, because we are using technical preview at this time. Once Windows Server
# 2016 goes GA, we will not need the TP5 syntax. Simply put, the command below 
# will build on top a Windows server with IIS preinstalled, which is the Web server.

FROM microsoft/iis

#---------------------------------------------------------------------------------------------
# Install Chocolatey. These are the build tools that will allow us to compile
# the web application built previously (WebAPI.sln).
# Chocolatey is a Windows package manager, making it easy to install our web app

ENV chocolateyUseWindowsCompression false
RUN @powershell -NoProfile -ExecutionPolicy unrestricted -Command "(iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))) >$null 2>&1" && SET PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin

#---------------------------------------------------------------------------------------------
# Install build tools. We mentioned that we would compile WebAPI.sln.
# This provides the appropriate.net framework and the ability to compile.

RUN powershell add-windowsfeature web-asp-net45 \
&& choco install microsoft-build-tools -y --allow-empty-checksums -version 14.0.23107.10 \
&& choco install dotnet4.6-targetpack --allow-empty-checksums -y \
&& choco install nuget.commandline --allow-empty-checksums -y \
&& nuget install MSBuild.Microsoft.VisualStudio.Web.targets -Version 14.0.0.3 \
&& nuget install WebConfigTransformRunner -Version 1.0.0.1

#---------------------------------------------------------------------------------------------
# Cleanup the default web folder with the content that comes preinstalled.
# We will install our own application there at the root.

RUN powershell remove-item C:\inetpub\wwwroot\iisstart.*

#---------------------------------------------------------------------------------------------
# Install ODBC drivers. This is commented out. This is the manual way
# to install ODBC drivers. Later in this file, we will use an automated approach.

# RUN md c:\drivers
# COPY odbc.reg c:/drivers
# COPY drivers c:/drivers
# RUN reg import c:/drivers/odbc.reg

#---------------------------------------------------------------------------------------------
#Install the ODBC drivers for PostGres. This was discussed previously in this post.
RUN md c:\drivers
COPY psqlodbc_x64.msi  c:/drivers
RUN powershell Unblock-File C:/drivers/psqlodbc_x64.msi; Start-Sleep -Second 1
RUN c:/drivers/psqlodbc_x64.msi /qn /quiet /passive

#---------------------------------------------------------------------------------------------
# Create a directory to hold our utilities.
RUN md c:\build
WORKDIR c:/build
COPY . c:/build


#---------------------------------------------------------------------------------------------
# Use the previously installed binaries to compile our app.
# This is where our web app (WebAPI.sln) gets compiled and copied 
# to the root folder of IIS.
RUN nuget restore \
&& "c:\Program Files (x86)\MSBuild\14.0\Bin\MSBuild.exe" /p:Platform="Any CPU" /p:VisualStudioVersion=12.0 /p:VSToolsPath=c:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath WebAPI.sln \
&& xcopy c:\build\WebAPI\* c:\inetpub\wwwroot /s

# DEPRECATED –> ENTRYPOINT powershell .\InitializeContainer