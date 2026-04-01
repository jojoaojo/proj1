#!/bin/bash
# Script de testes rápidos para Lab1
# Como usar: ./test_lab1.sh [opcao]

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Nome da imagem (MUDAR AQUI!)
IMAGE_NAME="sd2526-lab1-xxxxx-yyyyy"

print_header() {
    echo -e "${CYAN}"
    echo "═══════════════════════════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════════════════════════"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

# Função: Compilar e criar imagem
build() {
    print_header "COMPILANDO E CRIANDO IMAGEM DOCKER"
    
    print_info "Executando: mvn clean compile assembly:single docker:build"
    mvn clean compile assembly:single docker:build
    
    if [ $? -eq 0 ]; then
        print_success "Compilação e imagem criadas com sucesso!"
        docker images | grep sd2526-lab1
    else
        print_error "Falha na compilação!"
        exit 1
    fi
}

# Função: Criar rede
setup_network() {
    print_header "CONFIGURANDO REDE DOCKER"
    
    # Verificar se rede já existe
    if docker network ls | grep -q sdnet; then
        print_info "Rede 'sdnet' já existe"
    else
        docker network create -d bridge sdnet
        print_success "Rede 'sdnet' criada"
    fi
}

# Função: Teste Discovery (múltiplos containers)
test_discovery() {
    print_header "TESTE 1: MÚLTIPLOS DISCOVERY CONTAINERS"
    
    setup_network
    
    print_info "Iniciando 3 containers Discovery..."
    print_info "Pressione Ctrl+C em cada terminal para parar"
    echo ""
    echo "Execute em 3 TERMINAIS DIFERENTES:"
    echo -e "${CYAN}Terminal 1:${NC} docker run --rm -h disc1 --name disc1 --network sdnet $IMAGE_NAME"
    echo -e "${CYAN}Terminal 2:${NC} docker run --rm -h disc2 --name disc2 --network sdnet $IMAGE_NAME"
    echo -e "${CYAN}Terminal 3:${NC} docker run --rm -h disc3 --name disc3 --network sdnet $IMAGE_NAME"
    echo ""
    print_info "Você deve ver cada container recebendo anúncios dos outros!"
}

# Função: Teste TcpServer + TcpClient
test_tcp() {
    print_header "TESTE 2: TCPSERVER + TCPCLIENT"
    
    setup_network
    
    print_info "Comandos para testar servidor e cliente..."
    echo ""
    echo "Execute em 2 TERMINAIS DIFERENTES:"
    echo ""
    echo -e "${CYAN}Terminal 1 (Servidor):${NC}"
    echo "docker run -it --rm -h srv --name srv --network sdnet \\"
    echo "    $IMAGE_NAME \\"
    echo "    java -cp /home/sd/sd.jar sd.lab1.TcpServer"
    echo ""
    echo -e "${CYAN}Terminal 2 (Cliente):${NC}"
    echo "docker run -it --rm -h cli --name cli --network sdnet \\"
    echo "    $IMAGE_NAME \\"
    echo "    java -cp /home/sd/sd.jar sd.lab1.TcpClient"
    echo ""
    print_info "Cliente deve descobrir servidor automaticamente!"
}

# Função: Cleanup
cleanup() {
    print_header "LIMPANDO AMBIENTE"
    
    print_info "Parando todos containers..."
    docker ps -q | xargs -r docker kill 2>/dev/null
    
    print_info "Removendo containers parados..."
    docker ps -aq | xargs -r docker rm 2>/dev/null
    
    print_info "Removendo rede sdnet..."
    docker network rm sdnet 2>/dev/null
    
    print_success "Ambiente limpo!"
}

# Função: Status
status() {
    print_header "STATUS DO AMBIENTE"
    
    echo -e "${YELLOW}📦 Imagens Docker:${NC}"
    docker images | grep sd2526-lab1 || echo "  Nenhuma imagem encontrada"
    
    echo ""
    echo -e "${YELLOW}🐳 Containers em execução:${NC}"
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" || echo "  Nenhum container rodando"
    
    echo ""
    echo -e "${YELLOW}🌐 Redes:${NC}"
    docker network ls | grep sdnet || echo "  Rede 'sdnet' não existe"
}

# Função: Ajuda
show_help() {
    echo ""
    echo "LAB1 - Service Discovery - Script de Testes"
    echo ""
    echo "Uso: ./test_lab1.sh [opcao]"
    echo ""
    echo "Opções:"
    echo "  build       - Compilar projeto e criar imagem Docker"
    echo "  network     - Criar rede Docker 'sdnet'"
    echo "  discovery   - Instruções para testar Discovery"
    echo "  tcp         - Instruções para testar TcpServer+TcpClient"
    echo "  status      - Ver status (imagens, containers, redes)"
    echo "  cleanup     - Limpar ambiente (parar containers, remover rede)"
    echo "  help        - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  ./test_lab1.sh build      # Compilar tudo"
    echo "  ./test_lab1.sh discovery  # Ver comandos para teste Discovery"
    echo "  ./test_lab1.sh tcp        # Ver comandos para teste TCP"
    echo "  ./test_lab1.sh cleanup    # Limpar tudo"
    echo ""
}

# Main
case "$1" in
    build)
        build
        ;;
    network)
        setup_network
        ;;
    discovery)
        test_discovery
        ;;
    tcp)
        test_tcp
        ;;
    status)
        status
        ;;
    cleanup)
        cleanup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Opção inválida: $1"
        show_help
        exit 1
        ;;
esac
