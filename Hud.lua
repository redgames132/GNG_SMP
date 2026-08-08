-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (COMBAT PRO)
-- V3.0 - Protocolo JARVIS (Undertale Voice)
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

-- Cores Táticas
local C_FUNDO = 0
local C_VERMELHO = colors.red
local C_CINZA = colors.gray
local C_BRANCO = colors.white
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime
local C_JARVIS = colors.lightBlue

-- Variáveis de Memória
local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0
local compass = "-"
local frame = 0
local startTime = os.clock()

-- ==========================================
-- SISTEMA JARVIS (DICAS E VOZ UNDERTALE)
-- ==========================================
local jarvisDicas = {
    "JARVIS: Mantenha sua estamina alta para manobras evasivas.",
    "JARVIS: Inimigos com armadura de Netherite sofrem mais com dano magico.",
    "JARVIS: Fique atento aos flancos. O minimapa e seu melhor amigo.",
    "JARVIS: Recuo tatico e uma estrategia valida. Nao morra de graca.",
    "JARVIS: Seus parametros vitais estao estaveis.",
    "JARVIS: Lembre-se de checar o nivel de durabilidade dos seus equipamentos."
}
local jarvisAtual = ""
local jarvisProgresso = 0
local jarvisTempoTela = 0

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
-- DESENHO DIRETO E GERENCIAMENTO DE DADOS
-- ==========================================
local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local myX, myY, myZ = baseX, baseY, baseZ
    local myHealth, myFood = 20, 20
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaInimigo = 99999
    local dadosRadar = {}
    
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
                        local dx = pos.x - myX
                        local dy = pos.y - myY
                        local dz = pos.z - myZ
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
    local distBase = math.floor(math.sqrt((myX - baseX)^2 + (myY - baseY)^2 + (myZ - baseZ)^2))

    -- Sirene Juízo Final
    if inimigosProximos > 0 and speaker then
        if frame % 10 == 0 then speaker.playSound("entity.wither.spawn", 3.0, 0.5)
        elseif frame % 10 == 5 then 
            speaker.playSound("block.bell.resonate", 3.0, 0.5)
            speaker.playSound("entity.ghast.scream", 3.0, 0.6)
        end
    end

    local hexCode = string.format("0x%04X", math.random(0, 65535))
    local colorTheme = inimigosProximos > 0 and C_VERMELHO or C_CYAN
    local midX = math.floor(w/2)
    local midY = math.floor(h/2)

    -- ==========================================
    -- MÓDULO JARVIS (VOZ E TEXTO DIGITADO)
    -- ==========================================
    -- Dispara uma nova dica aleatória (Média: 1 vez a cada 30 segundos)
    if jarvisAtual == "" and math.random(1, 300) == 1 then
        jarvisAtual = jarvisDicas[math.random(1, #jarvisDicas)]
        jarvisProgresso = 0
        jarvisTempoTela = 60 -- Fica na tela por 6 segundos (60 frames) depois de pronto
    end

    if jarvisAtual ~= "" then
        -- Se o texto ainda está sendo "digitado"
        if jarvisProgresso < #jarvisAtual then
            jarvisProgresso = jarvisProgresso + 2 -- Velocidade da digitação
            if jarvisProgresso > #jarvisAtual then jarvisProgresso = #jarvisAtual end
            
            -- EFEITO UNDERTALE (Toca um som agudo e curto enquanto digita)
            if speaker then
                -- Muda levemente o tom a cada letra para dar aquele efeito de "fala" distorcida
                local tom = 1.5 + (math.random(-2, 2) * 0.1)
                speaker.playSound("block.note_block.bit", 2.0, tom)
            end
        else
            -- Se já terminou de digitar, começa a contar o tempo pra sumir
            jarvisTempoTela = jarvisTempoTela - 1
            if jarvisTempoTela <= 0 then
                jarvisAtual = ""
            end
        end

        -- Desenha o texto do Jarvis abaixo da mira
        local displayString = string.sub(jarvisAtual, 1, math.floor(jarvisProgresso))
        local jX = math.floor(midX - (#displayString / 2))
        hud.setCursorPos(jX, midY + 8)
        hud.setTextColour(C_JARVIS)
        hud.write(displayString)
    end

    -- ==========================================
    -- 1. CENTRO DA TELA (MIRA + TARGET LOCK)
    -- ==========================================
    hud.setTextColour(colorTheme)
    hud.setCursorPos(midX - 10, midY - 2) hud.write("/")
    hud.setCursorPos(midX - 12, midY)     hud.write("[")
    hud.setCursorPos(midX - 10, midY + 2) hud.write("\\")
    
    hud.setCursorPos(midX + 10, midY - 2) hud.write("\\")
    hud.setCursorPos(midX + 12, midY)     hud.write("]")
    hud.setCursorPos(midX + 10, midY + 2) hud.write("/")

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

    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta then
            local scale = visualRadius / raioAlerta
            local plotX = radarCX + math.floor(alvo.dx * scale * 1.5)
            local plotY = radarCY + math.floor(alvo.dz * scale)
            
            hud.setCursorPos(plotX, plotY)
            if alvo.aliado then
                hud.setTextColour(C_VERDE)
                hud.write("O")
            else
                hud.setTextColour(C_ALERTA)
                hud.write("X")
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

    local row = 2
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.d <= raioAlerta and printados < 4 then
            hud.setCursorPos(1, blY + row)
            hud.setTextColour(C_VERMELHO)
            hud.write("| ")
            if alvo.aliado then
                hud.setTextColour(C_VERDE)
                hud.write(string.format("[O] %-14s %-5s", string.sub(alvo.nome, 1, 14), alvo.d.."m"))
            else
                hud.setTextColour(C_ALERTA)
                hud.write(string.format("[X] %-14s %-5s", string.sub(alvo.nome, 1, 14), alvo.d.."m"))
            end
            row = row + 1
            printados = printados + 1
        end
    end
    if printados == 0 then
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
print(" RED_INDUSTRIES :: COMBAT OS PRO V3")
print("======================================")
term.setTextColor(colors.white)
print(" > Protocolo JARVIS ativado com sucesso.")
print(" > Modulo de voz Undertale carregado.")
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
print("Visor de Combate e Jarvis encerrados.")
