-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (CRISTAL)
-- Fundo Transparente + Zero Piscar
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")
local env = peripheral.find("environmentDetector") or peripheral.find("environment_detector")

if not hud then
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    return
end

hud.setSize(100, 50)
local w, h = hud.getSize()

-- ==========================================
-- CONFIGURAÇÕES
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

-- O Segredo da Visão Limpa: Fundo 100% Invisível
local C_TRANS = 0 
local C_VERMELHO = colors.red
local C_CINZA = colors.lightGray -- Deixei o cinza mais claro para dar contraste nas pedras
local C_BRANCO = colors.white
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime
local C_JARVIS = colors.lightBlue

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0
local compass = "-"
local frame = 0
local startTime = os.clock()

local jarvisDicas = {
    "JARVIS: Mantenha sua estamina alta para evasao.",
    "JARVIS: O minimapa e a sua maior vantagem.",
    "JARVIS: Recuo tatico e uma estrategia valida.",
    "JARVIS: Parametros vitais sob monitoramento.",
    "JARVIS: Fique atento a durabilidade do traje."
}
local jarvisAtual = ""
local jarvisProgresso = 0
local jarvisTempoTela = 0

local radarCX, radarCY = 14, 9
local visualRadius = 7
local circlePoints = {}
for i = 0, 359, 10 do
    local rad = math.rad(i)
    table.insert(circlePoints, {
        x = radarCX + math.floor(math.cos(rad) * visualRadius * 1.5),
        y = radarCY + math.floor(math.sin(rad) * visualRadius)
    })
end

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

-- ==========================================
-- 1. DESENHO ESTÁTICO (MOLDURAS E BORDAS)
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()

    local midX = math.floor(w/2)
    local midY = math.floor(h/2)
    
    -- Mira Central
    hud.setTextColour(C_CYAN)
    hud.setCursorPos(midX - 2, midY) hud.write("-")
    hud.setCursorPos(midX + 2, midY) hud.write("-")
    hud.setCursorPos(midX, midY - 1) hud.write("|")
    hud.setCursorPos(midX, midY + 1) hud.write("|")
    hud.setCursorPos(midX - 12, midY - 3) hud.write("_-=[")
    hud.setCursorPos(midX + 9,  midY - 3) hud.write("]=-_")
    hud.setCursorPos(midX - 12, midY + 3) hud.write("^-=[")
    hud.setCursorPos(midX + 9,  midY + 3) hud.write("]=-^")

    -- Borda Minimapa
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("+--[ ") hud.setTextColour(C_BRANCO) hud.write("MINIMAPA TÁTICO") hud.setTextColour(C_VERMELHO) hud.write(" ]--+")

    -- Borda Log Ameaças
    local blY = h - 8
    hud.setCursorPos(1, blY)
    hud.write("+--[ ") hud.setTextColour(C_BRANCO) hud.write("ASSISTENTE VITAL") hud.setTextColour(C_VERMELHO) hud.write(" ]--+")

    -- Borda Telemetria
    local trX = w - 30
    hud.setCursorPos(trX, 1)
    hud.write("+--[ ") hud.setTextColour(C_BRANCO) hud.write("TELEMETRIA") hud.setTextColour(C_VERMELHO) hud.write(" ]--+")
    hud.setCursorPos(trX, 6) hud.write("+--------------------------+")

    -- Borda Core OS
    local brY = h - 4
    hud.setCursorPos(trX, brY)
    hud.write("+--[ ") hud.setTextColour(C_BRANCO) hud.write("SISTEMA CORE_OS") hud.setTextColour(C_VERMELHO) hud.write(" ]--+")
end

-- ==========================================
-- 2. DESENHO DINÂMICO (ATUALIZAÇÃO INVISÍVEL)
-- ==========================================
local function updateDynamicHUD()
    -- Garante que o fundo de todo o texto seja sempre transparente
    hud.setBackgroundColour(C_TRANS)

    local myX, myY, myZ = baseX, baseY, baseZ
    local myHealth, myFood = 20, 20
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaInimigo = 99999
    local dadosRadar = {}
    
    local currentBiome, currentLight = "OFFLINE", 15
    local spawnRisk = false

    if env then
        pcall(function() currentBiome = env.getBiome() end)
        pcall(function() currentLight = env.getLightLevel() end)
        if currentLight < 7 then spawnRisk = true end
    end
    
    if detector then
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

        if detector.getPlayer then
            local okMeta, meta = pcall(detector.getPlayer, meuNick)
            if okMeta and type(meta) == "table" then
                if meta.health then myHealth = tonumber(meta.health) end
                if meta.foodLevel then myFood = tonumber(meta.foodLevel) end
            end
        end

        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then
            for _, p in ipairs(pList) do
                if p ~= meuNick then
                    local sP, pos = pcall(detector.getPlayerPos, p)
                    if sP and type(pos) == "table" and pos.x then
                        local dx, dy, dz = pos.x - myX, pos.y - myY, pos.z - myZ
                        local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                        local isAliado = aliados[p] == true
                        table.insert(dadosRadar, {nome = p, d = dist, dx = dx, dz = dz, aliado = isAliado})
                        
                        if dist <= raioAlerta and not isAliado then
                            inimigosProximos = inimigosProximos + 1
                            if dist < menorDistanciaInimigo then
                                menorDistanciaInimigo = dist
                                inimigoMaisProximo = p
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(dadosRadar, function(a, b) return a.d < b.d end)

    if inimigosProximos > 0 and speaker then
        if frame % 10 == 0 then speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 10 == 5 then 
            speaker.playSound("block.bell.resonate", 3.0, 0.5)
            speaker.playSound("entity.ghast.scream", 3.0, 0.6)
        end
    end

    local hexCode = string.format("0x%04X", math.random(0, 65535))
    local midX, midY = math.floor(w/2), math.floor(h/2)

    -- Alvo na Mira
    hud.setCursorPos(midX - 12, midY - 5)
    if inimigoMaisProximo then
        hud.setTextColour(C_ALERTA)
        hud.write(string.format("%-25s", "ALVO: " .. inimigoMaisProximo .. " (" .. menorDistanciaInimigo .. "m)"))
    else
        hud.write(string.format("%-25s", "")) 
    end

    -- Jarvis
    if jarvisAtual == "" then
        if spawnRisk and math.random(1, 150) == 1 then
            jarvisAtual = "JARVIS: Luz baixa. Risco de hostis."
            jarvisProgresso = 0
            jarvisTempoTela = 60
        elseif math.random(1, 300) == 1 then
            jarvisAtual = jarvisDicas[math.random(1, #jarvisDicas)]
            jarvisProgresso = 0
            jarvisTempoTela = 60
        end
    end

    if jarvisAtual ~= "" then
        if jarvisProgresso < #jarvisAtual then
            jarvisProgresso = jarvisProgresso + 2 
            if jarvisProgresso > #jarvisAtual then jarvisProgresso = #jarvisAtual end
            if speaker then speaker.playSound("block.note_block.bit", 2.0, 1.5 + (math.random(-2,2)*0.1)) end
        else
            jarvisTempoTela = jarvisTempoTela - 1
            if jarvisTempoTela <= 0 then jarvisAtual = "" end
        end
        local displayString = string.sub(jarvisAtual, 1, math.floor(jarvisProgresso))
        hud.setCursorPos(math.floor(midX - (#displayString / 2)), midY + 8)
        hud.setTextColour(C_JARVIS)
        hud.write(string.format("%-50s", displayString))
    else
        hud.setCursorPos(midX - 25, midY + 8)
        hud.write(string.format("%-50s", ""))
    end

    -- Limpa a parte de dentro do radar usando o fundo transparente
    for rY = radarCY - 5, radarCY + 5 do
        hud.setCursorPos(radarCX - 9, rY)
        hud.write("                  ")
    end

    -- Redesenha Borda e Centro do Radar
    hud.setTextColour(C_CINZA)
    for _, pt in ipairs(circlePoints) do
        hud.setCursorPos(pt.x, pt.y) hud.write(".")
    end
    hud.setCursorPos(radarCX, radarCY) hud.setTextColour(C_BRANCO) hud.write("+")
    hud.setCursorPos(radarCX, radarCY - visualRadius) hud.setTextColour(C_CINZA) hud.write("N")
    hud.setCursorPos(radarCX, radarCY + visualRadius) hud.write("S")

    -- Pontos dos Jogadores
    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta then
            local scale = visualRadius / raioAlerta
            local plotX = radarCX + math.floor(alvo.dx * scale * 1.5)
            local plotY = radarCY + math.floor(alvo.dz * scale)
            hud.setCursorPos(plotX, plotY)
            hud.setTextColour(alvo.aliado and C_VERDE or C_ALERTA)
            hud.write(alvo.aliado and "O" or "X")
        end
    end

    -- Assistente Vital Inferior
    local blY = h - 8
    hud.setCursorPos(1, blY + 1)
    hud.setTextColour(C_VERMELHO) hud.write("| ")
    
    if myHealth <= 10 then hud.setTextColour(C_ALERTA) hud.write(string.format("%-30s", "[!] DANO CRITICO!"))
    elseif spawnRisk then hud.setTextColour(C_ALERTA) hud.write(string.format("%-30s", "[!] RISCO DE SPAWN ("..currentLight..")"))
    elseif myFood <= 6 then hud.setTextColour(C_ALERTA) hud.write(string.format("%-30s", "[!] FOME ALTA!"))
    else hud.setTextColour(C_VERDE) hud.write(string.format("%-30s", "SISTEMAS VITAIS: OK")) end

    local row = 2
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta and printados < 4 then
            hud.setCursorPos(1, blY + row)
            hud.setTextColour(C_VERMELHO) hud.write("| ")
            hud.setTextColour(alvo.aliado and C_VERDE or C_ALERTA)
            local mark = alvo.aliado and "[O]" or "[X]"
            hud.write(string.format("%s %-12s %-5s      ", mark, string.sub(alvo.nome, 1, 12), alvo.d.."m"))
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 5 do
        hud.setCursorPos(1, blY + r)
        hud.write(string.format("| %-30s", ""))
    end

    -- Telemetria Superior Direita
    local trX = w - 30
    hud.setCursorPos(trX, 2)
    hud.setTextColour(C_CINZA) hud.write("  XYZ   : ") hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-17s", myX .. "," .. myY .. "," .. myZ))
    
    hud.setCursorPos(trX, 3)
    hud.setTextColour(C_CINZA) hud.write("  VELOC : ") hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-17s", speed .. " b/s ("..compass..")"))
    
    hud.setCursorPos(trX, 4)
    hud.setTextColour(C_CINZA) hud.write("  BIOMA : ") hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-17s", string.sub(currentBiome, 1, 17)))

    hud.setCursorPos(trX, 5)
    hud.setTextColour(C_CINZA) hud.write("  LUZ   : ") hud.setTextColour(spawnRisk and C_ALERTA or C_VERDE)
    hud.write(string.format("%-17s", currentLight .. "/15"))

    -- Core OS Inferior Direito
    local brY = h - 4
    hud.setCursorPos(trX, brY + 1)
    hud.setTextColour(C_CINZA) hud.write("  SYNC : ") hud.setTextColour(C_BRANCO)
    hud.write(string.format("%-18s", formatTime(os.time())))

    hud.setCursorPos(trX, brY + 2)
    hud.setTextColour(C_CINZA) hud.write("  UPT  : ") hud.setTextColour(C_CYAN)
    hud.write(string.format("%-18s", formatUptime(os.clock() - startTime)))

    hud.setCursorPos(trX, brY + 3)
    hud.setTextColour(C_CINZA) hud.write("  PING : ") hud.setTextColour(C_VERDE)
    hud.write(string.format("%-18s", math.random(12, 18) .. "ms"))

    hud.setCursorPos(trX, brY + 4)
    hud.setTextColour(C_CINZA) hud.write("  HASH : ") hud.setTextColour(C_ALERTA)
    hud.write(string.format("%-18s", hexCode))
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print(" RED_INDUSTRIES :: VISOR CRISTALINO")
print("======================================")
term.setTextColor(colors.white)
print(" > Telas limpas e transparentes.")
print(" > Pressione [Q] para DESLIGAR.")

drawStaticHUD() 

local running = true
local timer = os.startTimer(0.1)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        updateDynamicHUD() 
        frame = frame + 1
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

hud.setBackgroundColour(C_TRANS)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor encerrado.")
