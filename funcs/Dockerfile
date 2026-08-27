FROM mcr.microsoft.com/dotnet/sdk:10.0 AS installer-env

COPY . /src/dotnet-function-app
RUN cd /src/dotnet-function-app && \
    mkdir -p /home/site/wwwroot && \
    dotnet publish funcs.csproj --configuration Release --output /home/site/wwwroot

FROM mcr.microsoft.com/azure-functions/dotnet-isolated:4-dotnet-isolated10.0

ENV AzureFunctionsJobHost__Logging__Console__IsEnabled=true
ENV FUNCTIONS_WORKER_RUNTIME=dotnet-isolated

COPY --from=installer-env ["/home/site/wwwroot", "/home/site/wwwroot"]

RUN apt-get update \
    && bash /home/site/wwwroot/playwright.sh install --with-deps chromium \
    && rm -rf /var/lib/apt/lists/*
