-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (ULTRACLEAN)
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")

if not hud then
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES (MUITO IMPORTANTE)
-- ==========================================
-- COLOQUE O SEU NICK EXATO DO MINECRAFT AQUI:
local meuNick = "SEU_NICK_AQUI"

-- Raio de alerta em blocos
local raioAlerta = 50 

-- Cores do Tema (Vermelho Tático)
local C_FUNDO = 0 -- Transparente
local C_PRIM = colors.red
local C_SEC = colors.lightGray
local C_TEXTO = colors.white
local C_ALERTA = colors.orange

-- Variáveis de Animação
local frame = 0
local spinners = {"-", "\\", "|", "/"}

-- Formata a hora do jogo (ticks) para "00:00"
local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

-- Função para desenhar uma divisória estilizada
local function drawDivider(y, title, col)
    local w, _ = hud.getSize()
    local t = " " .. title .. " "
    local startX = math.floor((w - #t) / 2) + 1
    
    hud.setCursorPos(1, y)
    hud.setTextColour(C_SEC)
    hud.write(string.rep("-", startX - 2) .. "]")
    
    hud.setCursorPos(startX, y)
    hud.setTextColour(col)
    hud.write(t)
    
    hud.setCursorPos(startX + #t, y)
    hud.setTextColour(C_SEC)
    hud.write("[" .. string.rep("-", w - (startX + #t)))
end

-- ==========================================
-- DESENHO DO HUD (SISTEMA VISUAL ULTRACLEAN)
-- ==========================================
local function drawHUD()
    -- Começa do zero com fundo transparente
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    -- 1. CABEÇALHO TÁTICO
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_PRIM)
    hud.write("] ")
    hud.setTextColour(C_BRANCO)
    hud.write("RED_OS_LITE")
    hud.setTextColour(C_PRIM)
    hud.write(" [ ")
    
    -- Status Animado (Spinner)
    local animFrame = spinners[(frame % #spinners) + 1]
    hud.setTextColour(colors.lime)
    hud.write("ON " .. animFrame)
    
    -- 2. SEÇÃO DO SISTEMA
    drawDivider(2, "SYSTEM", C_SEC)
    
    hud.setCursorPos(2, 3)
    hud.setTextColour(C_TEXTO)
    hud.write("Dia: " .. os.day())
    
    hud.setCursorPos(2, 4)
    hud.write("Hor: " .. formatTime(os.time()))
    
    -- Coordenadas do Jogador (Fallback para coordenadas fixas da base)
    local myX, myY, myZ = -573, 57, -1446 
    
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and myPos and myPos.x then
            myX = math.floor(myPos.x)
            myY = math.floor(myPos.y)
            myZ = math.floor(myPos.z)
        end
    end
    
    hud.setCursorPos(2, 5)
    hud.setTextColour(C_SEC)
    hud.write("POS: ")
    hud.setTextColour(C_TEXTO)
    hud.write(myX .. ", " .. myY .. ", " .. myZ)

    -- 3. RADAR DE PROXIMIDADE 360
    drawDivider(7, "RADAR", C_PRIM)

    if detector then
        local suc, players = pcall(detector.getOnlinePlayers)
        if suc and type(players) == "table" then
            local contagemVisivel = 0
            local row = 8
            
            for _, p in ipairs(players) do
                -- Não lista o próprio jogador no radar
                if p ~= meuNick then
                    local sP, pos = pcall(detector.getPlayerPos, p)
                    if sP and pos and pos.x then
                        local dx = pos.x - myX
                        local dy = pos.y - myY
                        local dz = pos.z - myZ
                        local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                        
                        hud.setCursorPos(2, row)
                        
                        -- Lógica de Alerta de Proximidade (Vermelho se perto)
                        if dist <= raioAlerta then
                            hud.setTextColour(C_ALERTA)
                            hud.write("> ! " .. p .. " (" .. dist .. "m)")
                        else
                            hud.setTextColour(C_SEC)
                            hud.write("> - " .. p .. " (" .. dist .. "m)")
                        end
                        
                        row = row + 1
                        contagemVisivel = contagemVisivel + 1
                        
                        -- Limita a 10 nomes na tela para não poluir
                        if contagemVisivel >= 10 then break end
                    end
                end
            end
            
            if contagemVisivel == 0 then
                hud.setCursorPos(2, row)
                hud.setTextColour(colors.gray)
                hud.write("- Sem sinais")
            end
        else
            hud.setCursorPos(2, 8)
            hud.setTextColour(colors.red)
            hud.write("ERRO DE SENSOR")
        end
    else
        hud.setCursorPos(2, 8)
        hud.setTextColour(colors.gray)
        hud.write("SENSOR OFFLINE")
    end

    -- 4. BARRAS DE MÉTRICA (CPU ANIMADO - Lado Direito)
    local w, h = hud.getSize()
    drawDivider(h - 4, "CPU_METRICS", colors.orange)
    
    local maxBars = 10
    local activeBars = (frame % maxBars) + 1
    
    for i = 1, maxBars do
        hud.setCursorPos(w - 2, h - i - 5)
        if i <= activeBars then
            hud.setTextColour(C_PRIM)
        else
            hud.setTextColour(colors.gray)
        end
        hud.write("|")
    end
end

-- ==========================================
-- INICIALIZAÇÃO E LOOP DE ATUALIZAÇÃO
-- ==========================================
term.clear()
term.setCursorPos(1,1)
print("==============================")
print("  RED_INDUSTRIES HUD - LITE")
print("==============================")
print("> Transmissao visual limpa.")
print("> Oculos online.")
print("> Pressione [CTRL + T] para encerrar.")

while true do
    drawHUD()
    frame = frame + 1
    os.sleep(0.25)
end
