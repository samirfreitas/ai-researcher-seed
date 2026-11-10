# Liga a instancia Cloud SQL e espera ela ficar pronta (estado RUNNABLE).
# Use antes de testar a aplicacao, rodar o seed ou fazer deploy.
#
# Uso:  .\scripts\gcp-ligar.ps1                      (projeto padrao do gcloud)
#       .\scripts\gcp-ligar.ps1 -Projeto meu-projeto
param(
    [string]$Projeto = (gcloud config get-value project 2>$null),
    [string]$Instancia = 'ai-researcher-db'
)
$ErrorActionPreference = 'Stop'

if (-not $Projeto) { throw 'Nenhum projeto informado e nenhum projeto padrao no gcloud.' }
Write-Host "Projeto: $Projeto | Instancia: $Instancia"

$estado = gcloud sql instances describe $Instancia --project=$Projeto --format='value(state)'
if ($LASTEXITCODE -ne 0) { throw 'Nao consegui consultar a instancia.' }

if ($estado -eq 'RUNNABLE') {
    Write-Host 'A instancia ja esta ligada. Nada a fazer.'
    exit 0
}

Write-Host "Estado atual: $estado. Ligando (costuma levar de 2 a 5 minutos)..."
# --async: o spinner de espera do gcloud pode travar no terminal mesmo com a operacao
# ja concluida no Google, entao a espera e feita aqui, consultando o estado.
gcloud sql instances patch $Instancia --project=$Projeto --activation-policy=ALWAYS --quiet --async | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falha ao ligar a instancia.' }

for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 10
    $estado = gcloud sql instances describe $Instancia --project=$Projeto --format='value(state)'
    if ($estado -eq 'RUNNABLE') { break }
    Write-Host "  ainda $estado, aguardando..."
}

Write-Host "Pronto. Estado agora: $estado"
