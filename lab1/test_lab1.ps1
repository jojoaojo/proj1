# Script de testes rápidos para Lab1 (Windows PowerShell)
# Como usar: .\test_lab1.ps1 [opcao]

param(
    [Parameter(Position=0)]
    [string]$Comando = "help"
)

# Nome da imagem (MUDAR AQUI!)
$IMAGE_NAME = "sd2526-lab1-xxxxx-yyyyy"

function Print-Header {
    param([string]$Text)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  $Text" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Print-Success {
    param([string]$Text)
    Write-Host "✅ $Text" -ForegroundColor Green
}

function Print-Error {
    param([string]$Text)
    Write-Host "❌ $Text" -ForegroundColor Red
}

function Print-Info {
    param([string]$Text)
    Write-Host "ℹ️  $Text" -ForegroundColor Yellow
}

# Função: Compilar e criar imagem
function Build-Project {
    Print-Header "COMPILANDO E CRIANDO IMAGEM DOCKER"
    
    Print-Info "Executando: mvn clean compile assembly:single docker:build"
    mvn clean compile assembly:single docker:build
    
    if ($LASTEXITCODE -eq 0) {
        Print-Success "Compilação e imagem criadas com sucesso!"
        docker images | Select-String "sd2526-lab1"
    } else {
        Print-Error "Falha na compilação!"
        exit 1
    }
}

# Função: Criar rede
function Setup-Network {
    Print-Header "CONFIGURANDO REDE DOCKER"
    
    # Verificar se rede já existe
    $networkExists = docker network ls | Select-String "sdnet"
    
    if ($networkExists) {
        Print-Info "Rede 'sdnet' já existe"
    } else {
        docker network create -d bridge sdnet
        Print-Success "Rede 'sdnet' criada"
    }
}

# Função: Teste Discovery
function Test-Discovery {
    Print-Header "TESTE 1: MÚLTIPLOS DISCOVERY CONTAINERS"
    
    Setup-Network
    
    Print-Info "Comandos para iniciar 3 containers Discovery..."
    Print-Info "Execute cada comando em uma JANELA POWERSHELL DIFERENTE:"
    Write-Host ""
    Write-Host "Terminal 1:" -ForegroundColor Cyan
    Write-Host "docker run --rm -h disc1 --name disc1 --network sdnet $IMAGE_NAME" -ForegroundColor White
    Write-Host ""
    Write-Host "Terminal 2:" -ForegroundColor Cyan
    Write-Host "docker run --rm -h disc2 --name disc2 --network sdnet $IMAGE_NAME" -ForegroundColor White
    Write-Host ""
    Write-Host "Terminal 3:" -ForegroundColor Cyan
    Write-Host "docker run --rm -h disc3 --name disc3 --network sdnet $IMAGE_NAME" -ForegroundColor White
    Write-Host ""
    Print-Info "Pressione Ctrl+C em cada terminal para parar"
    Print-Info "Você deve ver cada container recebendo anúncios dos outros!"
}

# Função: Teste TCP
function Test-Tcp {
    Print-Header "TESTE 2: TCPSERVER + TCPCLIENT"
    
    Setup-Network
    
    Print-Info "Comandos para testar servidor e cliente..."
    Write-Host ""
    Write-Host "Execute em 2 JANELAS POWERSHELL DIFERENTES:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Terminal 1 (Servidor):" -ForegroundColor Cyan
    Write-Host "docker run -it --rm -h srv --name srv --network sdnet ``" -ForegroundColor White
    Write-Host "    $IMAGE_NAME ``" -ForegroundColor White
    Write-Host "    java -cp /home/sd/sd.jar sd.lab1.TcpServer" -ForegroundColor White
    Write-Host ""
    Write-Host "Terminal 2 (Cliente):" -ForegroundColor Cyan
    Write-Host "docker run -it --rm -h cli --name cli --network sdnet ``" -ForegroundColor White
    Write-Host "    $IMAGE_NAME ``" -ForegroundColor White
    Write-Host "    java -cp /home/sd/sd.jar sd.lab1.TcpClient" -ForegroundColor White
    Write-Host ""
    Print-Info "Cliente deve descobrir servidor automaticamente!"
    Print-Info "Digite mensagens no cliente e veja aparecerem no servidor"
    Print-Info "Digite '!quit' para terminar"
}

# Função: Cleanup
function Cleanup-Environment {
    Print-Header "LIMPANDO AMBIENTE"
    
    Print-Info "Parando todos containers..."
    $containers = docker ps -q
    if ($containers) {
        docker kill $containers 2>$null
    }
    
    Print-Info "Removendo containers parados..."
    docker container prune -f 2>$null | Out-Null
    
    Print-Info "Removendo rede sdnet..."
    docker network rm sdnet 2>$null | Out-Null
    
    Print-Success "Ambiente limpo!"
}

# Função: Status
function Show-Status {
    Print-Header "STATUS DO AMBIENTE"
    
    Write-Host "📦 Imagens Docker:" -ForegroundColor Yellow
    $images = docker images | Select-String "sd2526-lab1"
    if ($images) {
        $images
    } else {
        Write-Host "  Nenhuma imagem encontrada" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🐳 Containers em execução:" -ForegroundColor Yellow
    $containers = docker ps --format "table {{.Names}}`t{{.Image}}`t{{.Status}}"
    if ($containers.Count -gt 1) {
        $containers
    } else {
        Write-Host "  Nenhum container rodando" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "🌐 Redes:" -ForegroundColor Yellow
    $networks = docker network ls | Select-String "sdnet"
    if ($networks) {
        $networks
    } else {
        Write-Host "  Rede 'sdnet' não existe" -ForegroundColor Gray
    }
}

# Função: Ajuda
function Show-Help {
    Write-Host ""
    Write-Host "LAB1 - Service Discovery - Script de Testes (Windows)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Uso: .\test_lab1.ps1 [opcao]" -ForegroundColor White
    Write-Host ""
    Write-Host "Opções:" -ForegroundColor Yellow
    Write-Host "  build       - Compilar projeto e criar imagem Docker"
    Write-Host "  network     - Criar rede Docker 'sdnet'"
    Write-Host "  discovery   - Instruções para testar Discovery"
    Write-Host "  tcp         - Instruções para testar TcpServer+TcpClient"
    Write-Host "  status      - Ver status (imagens, containers, redes)"
    Write-Host "  cleanup     - Limpar ambiente (parar containers, remover rede)"
    Write-Host "  help        - Mostrar esta ajuda"
    Write-Host ""
    Write-Host "Exemplos:" -ForegroundColor Yellow
    Write-Host "  .\test_lab1.ps1 build      # Compilar tudo"
    Write-Host "  .\test_lab1.ps1 discovery  # Ver comandos para teste Discovery"
    Write-Host "  .\test_lab1.ps1 tcp        # Ver comandos para teste TCP"
    Write-Host "  .\test_lab1.ps1 cleanup    # Limpar tudo"
    Write-Host ""
}

# Main
switch ($Comando.ToLower()) {
    "build" {
        Build-Project
    }
    "network" {
        Setup-Network
    }
    "discovery" {
        Test-Discovery
    }
    "tcp" {
        Test-Tcp
    }
    "status" {
        Show-Status
    }
    "cleanup" {
        Cleanup-Environment
    }
    "help" {
        Show-Help
    }
    default {
        Print-Error "Opção inválida: $Comando"
        Show-Help
        exit 1
    }
}
