-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (COMPACTO)
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")

if not hud then
    print("ERRO: HUD Modem nao encontrado!")
    return
end

-- ==========================================
-- CONFIGURAÇÕES (MUITO IMPORTANTE)
-- ==========================================
-- COLOQUE O SEU NOME EXATO DO MINECRAFT AQUI:
local meuNick = "SEU_NICK_AQUI"

-- Raio de alerta em blocos
local raioAlerta = 50 

-- Cores
local C_FUNDO = 0
local C_PRIM = colors.red
local C_SEC = colors.gray
local C_TEXTO = colors.white
local C_ALERTA = colors.orange

local spinners = {"-", "\\", "|", "/"}
local frame = 0

local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

-- ==========================================
-- DESENHO DO HUD (MINIMALISTA)
-- ==========================================
local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    -- 1. Cabeçalho Compacto
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_PRIM)
    hud.write("[")
    hud.setTextColour(C_TEXTO)
    hud.write("RED_OS")
    hud.setTextColour(C_PRIM)
    hud.write("] ")
    
    -- Status Animado
    hud.setTextColour(C_SEC)
    hud.write("SYS:")
    hud.setTextColour(colors.lime)
    hud.write("ON " .. spinners[(frame % 4) + 1])

    -- 2. Ciclo e Tempo
    hud.setCursorPos(1, 2)
    hud.setTextColour(C_SEC)
    hud.write("CLK: ")
    hud.setTextColour(C_TEXTO)
    hud.write(formatTime(os.time()))

    -- 3. Rastreamento Dinâmico (Sua Posição)
    -- Fallback: Coordenadas da base caso o sensor perca você de vista
    local myX, myY, myZ = -573, 57, -1446 
    
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and myPos and myPos.x then
            myX = math.floor(myPos.x)
            myY = math.floor(myPos.y)
            myZ = math.floor(myPos.z)
        end
    end

    hud.setCursorPos(1, 3)
    hud.setTextColour(C_SEC)
    hud.write("POS: ")
    hud.setTextColour(C_TEXTO)
    hud.write(myX .. ", " .. myY .. ", " .. myZ)

    -- 4. Sensor Biométrico e Proximidade
    hud.setCursorPos(1, 5)
    hud.setTextColour(C_PRIM)
    hud.write("] RADAR 360")

    if detector then
        local suc, players = pcall(detector.getOnlinePlayers)
        if suc and type(players) == "table" then
            local row = 6
            local contagemVisivel = 0
            
            for _, p in ipairs(players) do
                -- Não lista você mesmo no radar
                if p ~= meuNick then
                    local sP, pos = pcall(detector.getPlayerPos, p)
                    if sP and pos and pos.x then
                        -- Calcula a distância exata entre você e o alvo
                        local dx = pos.x - myX
                        local dy = pos.y - myY
                        local dz = pos.z - myZ
                        local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                        
                        hud.setCursorPos(1, row)
                        
                        -- Sistema de Alerta de Proximidade (50 blocos)
                        if dist <= raioAlerta then
                            hud.setTextColour(C_ALERTA)
                            hud.write("! " .. p .. " (" .. dist .. "m)")
                        else
                            hud.setTextColour(C_SEC)
                            hud.write("- " .. p .. " (" .. dist .. "m)")
                        end
                        
                        row = row + 1
                        contagemVisivel = contagemVisivel + 1
                        
                        -- Limita a 8 nomes na tela para não poluir a sua visão
                        if contagemVisivel >= 8 then break end
                    end
                end
            end
            
            if contagemVisivel == 0 then
                hud.setCursorPos(1, row)
                hud.setTextColour(C_SEC)
                hud.write("- Sem sinais")
            end
        else
            hud.setCursorPos(1, 6)
            hud.setTextColour(colors.red)
            hud.write("FALHA NO SENSOR")
        end
    else
        hud.setCursorPos(1, 6)
        hud.setTextColour(colors.gray)
        hud.write("SENSOR OFFLINE")
    end
end

-- ==========================================
-- INICIALIZAÇÃO
-- ==========================================
term.clear()
term.setCursorPos(1,1)
print("==============================")
print("  RED_INDUSTRIES HUD - LITE")
print("==============================")
print("> Transmissao limpa.")
print("> Oculos online.")
print("> Pressione [CTRL + T] para encerrar.")

while true do
    drawHUD()
    frame = frame + 1
    os.sleep(0.25)
end
