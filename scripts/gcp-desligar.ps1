# Desliga a instancia Cloud SQL para nao pagar computacao enquanto o projeto nao esta em uso.
# Dados, banco, usuarios e extensoes continuam intactos; so o disco segue sendo cobrado (~US$ 1,70/mes).
# Cloud Run, Firebase Hosting e o resto nao precisam ser desligados: nao custam nada parados.
#
# Uso:  .\scripts\gcp-desligar.ps1                      (projeto padrao do gcloud)
#       .\scripts\gcp-desligar.ps1 -Projeto meu-projeto
param(
    [string]$Projeto = (gcloud config get-value project 2>$null),
    [string]$Instancia = 'ai-researcher-db'
)
$ErrorActionPreference = 'Stop'

if (-not $Projeto) { throw 'Nenhum projeto informado e nenhum projeto padrao no gcloud.' }
Write-Host "Projeto: $Projeto | Instancia: $Instancia"

$estado = gcloud sql instances describe $Instancia --project=$Projeto --format='value(state)'
if ($LASTEXITCODE -ne 0) { throw 'Nao consegui consultar a instancia.' }

if ($estado -eq 'STOPPED') {
    Write-Host 'A instancia ja esta desligada. Nada a fazer.'
    exit 0
}

Write-Host "Estado atual: $estado. Desligando (costuma levar de 1 a 5 minutos)..."
# --async: o spinner de espera do gcloud pode travar no terminal mesmo com a operacao
# ja concluida no Google, entao a espera e feita aqui, consultando o estado.
gcloud sql instances patch $Instancia --project=$Projeto --activation-policy=NEVER --quiet --async | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Falha ao desligar a instancia.' }

for ($i = 0; $i -lt 60; $i++) {
    Start-Sleep -Seconds 10
    $estado = gcloud sql instances describe $Instancia --project=$Projeto --format='value(state)'
    if ($estado -eq 'STOPPED') { break }
    Write-Host "  ainda $estado, aguardando..."
}

Write-Host "Pronto. Estado agora: $estado"
Write-Host 'Enquanto estiver desligada, /api/health responde com o banco indisponivel.'
