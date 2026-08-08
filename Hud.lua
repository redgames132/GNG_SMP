-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (CORRIGIDO)
-- Tema: Cyberpunk / Vermelho Tático
-- ==========================================

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
-- A cor '0' deixa o fundo do óculos transparente
local C_FUNDO = 0 
local C_PRIM = colors.red
local C_SEC = colors.lightGray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange

-- CORREÇÃO: O mod HUD Glasses usa a resolução da tela em vez de Scale.
-- Se achar as letras na sua tela muito pequenas, tire os dois traços (--) da linha abaixo
-- e diminua os números (ex: hud.setSize(60, 20)) para dar "zoom".
-- hud.setSize(80, 28)

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

    -- 3. INFORMAÇÕES DE AMBIENTE (Relógio)
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

    -- 4. MÓDULO DE SEGURANÇA TÁTICA
    hud.setCursorPos(2, 11)
    hud.setTextColour(C_PRIM)
    hud.write("--- SENSOR BIOMETRICO ---")

    if detector then
        local success, players = pcall(detector.getOnlinePlayers)
        if success and type(players) == "table" then
            
            hud.setCursorPos(2, 12)
            hud.setTextColour(C_SEC)
            hud.write("ENTIDADES: ")
            
            -- Fica vermelho se tiver mais de 1 pessoa
            hud.setTextColour(#players > 1 and C_PRIM or C_BRANCO)
            hud.write(tostring(#players))

            -- Lista no máximo 5 nomes na tela
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
        hud.setCursorPos(2, 12)
        hud.setTextColour(colors.gray)
        hud.write("[ SENSOR OFFLINE ]")
    end

    -- 5. BARRA DE MÉTRICA DIREITA (Animação estilo CPU)
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
-- INICIALIZAÇÃO E LOOP
-- ==========================================
term.clear()
term.setCursorPos(1,1)
print("==============================")
print("  RED_INDUSTRIES HUD INICIADO")
print("==============================")
print("> Transmissao visual estabelecida.")
print("> Oculos online.")
print("> Pressione [CTRL + T] para encerrar.")

while true do
    drawHUD()
    frame = frame + 1
    os.sleep(0.25)
end
