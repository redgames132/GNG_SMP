-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS
-- Tema: Cyberpunk / Vermelho Tático
-- ==========================================

-- Procura os módulos
local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")

if not hud then
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    print("Por favor, conecte o bloco HUD Modem ao computador.")
    return
end

-- ==========================================
-- CONFIGURAÇÕES VISUAIS
-- ==========================================
-- A cor '0' é um segredo do mod CC: HUD Glasses para deixar transparente
local C_FUNDO = 0 
local C_PRIM = colors.red
local C_SEC = colors.lightGray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange

-- Ajusta a escala (pode mudar para 0.5 se achar as letras muito grandes)
hud.setTextScale(1)
local w, h = hud.getSize()

-- Variáveis de Animação
local frame = 0
local spinners = {"-", "\\", "|", "/"}

-- Transforma os ticks do Minecraft em hora legível
local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

-- ==========================================
-- DESENHO DO HUD
-- ==========================================
local function drawHUD()
    -- Aplica a transparência no fundo inteiro da tela do jogador
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    -- 1. CAIXA SUPERIOR (Título da Empresa)
    hud.setCursorPos(2, 2)
    hud.setTextColour(C_PRIM)
    hud.write(string.rep("=", 24))
    
    hud.setCursorPos(2, 3)
    hud.write("] ")
    hud.setTextColour(C_BRANCO)
    hud.write("RED_INDUSTRIES_OS")
    hud.setTextColour(C_PRIM)
    hud.write(" [")
    
    hud.setCursorPos(2, 4)
    hud.write(string.rep("=", 24))

    -- 2. STATUS E ANIMAÇÃO
    local animFrame = spinners[(frame % 4) + 1]
    hud.setCursorPos(2, 6)
    hud.setTextColour(C_SEC)
    hud.write("STATUS : ")
    hud.setTextColour(C_PRIM)
    hud.write("SISTEMA ONLINE " .. animFrame)

    -- 3. INFORMAÇÕES DE AMBIENTE (Relógio do Jogo)
    hud.setCursorPos(2, 8)
    hud.setTextColour(C_SEC)
    hud.write("CICLO  : ")
    hud.setTextColour(C_BRANCO)
    hud.write("DIA " .. tostring(os.day()))
    
    hud.setCursorPos(2, 9)
    hud.setTextColour(C_SEC)
    hud.write("HORA   : ")
    hud.setTextColour(C_BRANCO)
    hud.write(formatTime(os.time()))

    -- 4. MÓDULO DE SEGURANÇA TÁTICA (Requer Player Detector)
    hud.setCursorPos(2, 11)
    hud.setTextColour(C_PRIM)
    hud.write("--- SENSOR BIOMETRICO ---")

    if detector then
        local success, players = pcall(detector.getOnlinePlayers)
        if success and type(players) == "table" then
            
            hud.setCursorPos(2, 12)
            hud.setTextColour(C_SEC)
            hud.write("ENTIDADES: ")
            
            -- Se tiver mais de 1 pessoa (você + alguem), fica vermelho
            hud.setTextColour(#players > 1 and C_PRIM or C_BRANCO)
            hud.write(tostring(#players))

            -- Lista no máximo 5 nomes na tela para não poluir sua visão
            local limit = math.min(#players, 5)
            for i = 1, limit do
                hud.setCursorPos(2, 13 + i)
                hud.setTextColour(C_ALERTA)
                hud.write(" > " .. players[i])
            end
        else
            hud.setCursorPos(2, 12)
            hud.setTextColour(C_SEC)
            hud.write("ESCANEANDO SINAIS...")
        end
    else
        -- Se o computador do HUD não tiver detector conectado
        hud.setCursorPos(2, 12)
        hud.setTextColour(colors.gray)
        hud.write("[ SENSOR OFFLINE ]")
    end

    -- 5. BARRA DE MÉTRICA DIREITA (Apenas visual cyberpunk)
    local maxBars = math.floor(h / 3)
    local activeBars = (frame % maxBars) + 1
    
    for i = 1, maxBars do
        hud.setCursorPos(w - 2, h - i - 2)
        if i <= activeBars then
            hud.setTextColour(C_PRIM)
        else
            hud.setTextColour(colors.gray)
        end
        hud.write("|")
    end
    
    hud.setCursorPos(w - 5, h - maxBars - 4)
    hud.setTextColour(C_PRIM)
    hud.write("CPU")
end

-- ==========================================
-- INICIALIZAÇÃO
-- ==========================================
term.clear()
term.setCursorPos(1,1)
print("==============================")
print("  RED_INDUSTRIES HUD INICIADO")
print("==============================")
print("> Transmissao visual estabelecida.")
print("> Oculos online.")
print("> Pressione [CTRL + T] para encerrar.")

-- Loop infinito de atualização da tela
while true do
    drawHUD()
    frame = frame + 1
    os.sleep(0.25) -- Atualiza 4 vezes por segundo
end
