-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (COMBAT PRO)
-- Zero Piscar + Assistente de Vida/Fome + Radar 250m
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")

if not hud then
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

-- Configura alta resolução sem buffer incompatível
hud.setSize(100, 50)
local w, h = hud.getSize()

-- ==========================================
-- CONFIGURAÇÕES DA EQUIPE
-- ==========================================
local meuNick = "redgames132"
local raioAlerta = 250
local baseX, baseY, baseZ = -573, 57, -1446

local aliados = {
    ["redgames132"] = true,
    ["KAIOX_NEGROX"] = true,
    ["goonerstickle69"] = true,
    ["cadipadi"] = true
}

-- Cores
local C_FUNDO = 0
local C_VERMELHO = colors.red
local C_CINZA = colors.gray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0
local compass = "-"
local frame = 0
local startTime = os.clock()

local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

local function formatUptime(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

local function getDirection(dx, dz)
    if dx == 0 and dz == 0 then return compass end
    if math.abs(dx) > math.abs(dz) then return dx > 0 and "L" or "O"
    else return dz > 0 and "S" or "N" end
end

-- Pontos do Minimapa 2D
local radarCX, radarCY = 14, 9
local visualRadius = 7
local circlePoints = {}
for i = 0, 359, 10 do
    local rad = math.rad(i)
    local px = radarCX + math.floor(math.cos(rad) * visualRadius * 1.5)
    local py = radarCY + math.floor(math.sin(rad) * visualRadius)
    table.insert(circlePoints, {x = px, y = py})
end

-- ==========================================
-- DESENHO DIRETO (ZERO FLICKER)
-- ==========================================
local function drawHUD()
    -- Apaga e redesenha no mesmo tick do jogo para não piscar
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local myHealth, myFood = 20, 20 -- Valores padrão
    local players = {}
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaInimigo = 99999
    
    if detector then
        -- Tenta puxar a posição e dados do jogador
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and type(myPos) == "table" and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            speedTicks = speedTicks + 1
            if speedTicks >= 10 then 
                local dx, dy, dz = myX - lastX, myY - lastY, myZ - lastZ
                speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                if speed > 0 then compass = getDirection(dx, dz) end
                lastX, lastY, lastZ = myX, myY, myZ
                speedTicks = 0
            end
        end

        -- Tenta puxar metadados de Vida/Fome do jogador (se o mod permitir)
        if detector.getMetaByName then
            local okMeta, meta = pcall(detector.getMetaByName, meuNick)
            if okMeta and type(meta) == "table" then
                if meta.health then myHealth = meta.health end
                if meta.foodLevel then myFood = meta.foodLevel end
            end
        end

        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then players = pList end
    end

    local distBase = math.floor(math.sqrt((myX - baseX)^2 + (myY - baseY)^2 + (myZ - baseZ)^2))

    -- Mapeia Inimigos
    for _, p in ipairs(players) do
        if not aliados[p] then
            local sP, pos = pcall(detector.getPlayerPos, p)
            if sP and type(pos) == "table" and pos.x then
                local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                local d = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                if d <= raioAlerta then
                    inimigosProximos = inimigosProximos + 1
                    if d < menorDistanciaInimigo then
                        menorDistanciaInimigo = d
                        inimigoMaisProximo = p
                    end
                end
            end
        end
    end

    -- ALARME DO JUÍZO FINAL (Inimigos no perímetro)
    if inimigosProximos > 0 and speaker then
        if frame % 10 == 0 then speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 10 == 5 then 
            speaker.playSound("block.bell.resonate", 3.0, 0.5)
            speaker.playSound("entity.ghast.scream", 3.0, 0.6)
        end
    end

    local hexCode = string.format("0x%04X", math.random(0, 65535))
    local colorTheme = inimigosProximos > 0 and C_VERMELHO or C_CYAN

    -- ==========================================
    -- 1. CENTRO DA TELA (MIRA + TARGET LOCK)
    -- ==========================================
    local midX = math.floor(w/2)
    local midY = math.floor(h/2)
    
    hud.setTextColour(colorTheme)
    hud.setCursorPos(midX - 10, midY - 2) hud.write("/")
    hud.setCursorPos(midX - 12, midY)     hud.write("[")
    hud.setCursorPos(midX - 10, midY + 2) hud.write("\\")
    
    hud.setCursorPos(midX + 10, midY - 2) hud.write("\\")
    hud.setCursorPos(midX + 12, midY)     hud.write("]")
    hud.setCursorPos(midX + 10, midY + 2) hud.write("/")

    -- Trava de Alvo se tiver inimigo próximo
    if inimigoMaisProximo then
        hud.setCursorPos(midX - 12, midY - 3)
        hud.setTextColour(C_ALERTA)
        hud.write("ALVO: " .. inimigoMaisProximo .. " (" .. menorDistanciaInimigo .. "m)")
    end

    -- ==========================================
    -- 2. CANTO SUPERIOR ESQUERDO (MINIMAPA)
    -- ==========================================
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("+--[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("MINIMAPA (" .. raioAlerta .. "m)")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]--+")

    hud.setTextColour(C_CINZA)
    for _, pt in ipairs(circlePoints) do
        hud.setCursorPos(pt.x, pt.y)
        hud.write(".")
    end
    
    hud.setCursorPos(radarCX, radarCY)
    hud.setTextColour(C_BRANCO)
    hud.write("+")
    hud.setCursorPos(radarCX, radarCY - visualRadius) hud.setTextColour(C_CINZA) hud.write("N")
    hud.setCursorPos(radarCX, radarCY + visualRadius) hud.write("S")

    local radarLog = {}
    for _, p in ipairs(players) do
        if p ~= meuNick then
            local sP, pos = pcall(detector.getPlayerPos, p)
            if sP and type(pos) == "table" and pos.x then
                local dx, dz = pos.x - myX, pos.z - myZ
                local dist = math.floor(math.sqrt((dx*dx) + ((pos.y - myY)^2) + (dz*dz)))
                
                if dist <= raioAlerta then
                    local scale = visualRadius / raioAlerta
                    local plotX = radarCX + math.floor(dx * scale * 1.5)
                    local plotY = radarCY + math.floor(dz * scale)
                    
                    hud.setCursorPos(plotX, plotY)
                    if aliados[p] then
                        hud.setTextColour(C_VERDE)
                        hud.write("O")
                    else
                        hud.setTextColour(C_ALERTA)
                        hud.write("X")
                    end
                    table.insert(radarLog, {nome = p, d = dist, aliado = aliados[p]})
                end
            end
        end
    end

    -- ==========================================
    -- 3. CANTO INFERIOR ESQUERDO (COMBAT ASSIST)
    -- ==========================================
    local blY = h - 7
    hud.setCursorPos(1, blY)
    hud.setTextColour(C_VERMELHO)
    hud.write("+--[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("ASSISTENTE DE COMBATE")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]")

    -- Alerta de Comida / Regeneração
    hud.setCursorPos(1, blY + 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("| ")
    
    if myHealth <= 10 then
        hud.setTextColour(C_ALERTA)
        hud.write("[!] DANO CRITICO: RECUPERE VIDA!")
        if speaker and frame % 5 == 0 then
            speaker.playSound("entity.experience_orb.pickup", 2.0, 0.5)
        end
    elseif myFood <= 6 then
        hud.setTextColour(C_ALERTA)
        hud.write("[!] FOME ALTA: COMA AGORA!")
    elseif menorDistanciaInimigo <= 30 then
        hud.setTextColour(C_ALERTA)
        hud.write("[!] INIMIGO PROXIMO: PREPARE COMIDA!")
    else
        hud.setTextColour(C_VERDE)
        hud.write("STATUS VITAL: OK")
    end

    -- Barra de Status do Radar
    local row = 2
    for i, alvo in ipairs(radarLog) do
        if row <= 5 then
            hud.setCursorPos(1, blY + row)
            hud.setTextColour(C_VERMELHO)
            hud.write("| ")
            if alvo.aliado then
                hud.setTextColour(C_VERDE)
                hud.write(string.format("[O] %-14s %-5s", alvo.nome, alvo.d.."m"))
            else
                hud.setTextColour(C_ALERTA)
                hud.write(string.format("[X] %-14s %-5s", alvo.nome, alvo.d.."m"))
            end
            row = row + 1
        end
    end
    if #radarLog == 0 then
        hud.setCursorPos(1, blY + 2)
        hud.setTextColour(C_VERMELHO)
        hud.write("| ")
        hud.setTextColour(C_CINZA)
        hud.write("PERIMETRO LIMPO.")
    end

    -- ==========================================
    -- 4. CANTO SUPERIOR DIREITO (TELEMETRIA)
    -- ==========================================
    local trX = w - 30
    hud.setCursorPos(trX, 1)
    hud.setTextColour(colorTheme)
    hud.write("[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("DADOS DO TRAJE")
    hud.setTextColour(colorTheme)
    hud.write(" ]--+")

    hud.setCursorPos(trX, 2)
    hud.setTextColour(C_CINZA)
    hud.write("  XYZ   : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-21s", myX .. "," .. myY .. "," .. myZ))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 3)
    hud.setTextColour(C_CINZA)
    hud.write("  VELOC : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-12s", speed .. " b/s"))
    hud.setTextColour(C_CYAN)
    hud.write(string.format("%-9s", compass))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 4)
    hud.setTextColour(C_CINZA)
    hud.write("  D.BASE: ")
    hud.setTextColour(C_ALERTA)
    hud.write(string.format("%-21s", distBase .. "m"))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 5)
    hud.setTextColour(C_CINZA)
    hud.write("  ARMOR : ")
    hud.setTextColour(C_VERDE)
    hud.write(string.format("%-21s", "100% [||||||||]"))
    hud.setTextColour(colorTheme)
    hud.write("|")

    hud.setCursorPos(trX, 6)
    hud.write("-------------------------+")

    -- ==========================================
    -- 5. CANTO INFERIOR DIREITO (SISTEMA CORE)
    -- ==========================================
    local brY = h - 4
    local brX = w - 30

    hud.setCursorPos(brX, brY)
    hud.setTextColour(C_VERMELHO)
    hud.write("[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("SISTEMA CORE_OS")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]--+")

    hud.setCursorPos(brX, brY + 1)
    hud.setTextColour(C_CINZA)
    hud.write("  SYNC : ")
    hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-21s", "IRL " .. os.date("%H:%M") .. " | MC " .. formatTime(os.time())))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(brX, brY + 2)
    hud.setTextColour(C_CINZA)
    hud.write("  UPT  : ")
    hud.setTextColour(C_CYAN)
    hud.write(string.format("%-21s", formatUptime(os.clock() - startTime)))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(brX, brY + 3)
    hud.setTextColour(C_CINZA)
    hud.write("  PING : ")
    hud.setTextColour(C_VERDE)
    hud.write(string.format("%-21s", math.random(12, 18) .. "ms"))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")

    hud.setCursorPos(brX, brY + 4)
    hud.setTextColour(C_CINZA)
    hud.write("  HASH : ")
    hud.setTextColour(C_ALERTA)
    hud.write(string.format("%-21s", hexCode))
    hud.setTextColour(C_VERMELHO)
    hud.write("|")
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: COMBAT OS PRO")
print("======================================")
term.setTextColor(colors.white)
print(" > Erro na Linha 91 corrigido com sucesso.")
print(" > Assistente de Combate & Comida Ativo.")
print(" > Pressione [Q] para DESLIGAR.")

local running = true
local timer = os.startTimer(0.1)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        drawHUD()
        frame = frame + 1
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

hud.setBackgroundColour(C_FUNDO)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor de Combate encerrado.")
