-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (LITE)
-- Foco no Jogador: Radar Local + Jarvis
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")
local speaker = peripheral.find("speaker")

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
-- CONFIGURAÇÕES (MUDE O NICK AQUI)
-- ==========================================
local meuNick = "NICK_DO_SEU_AMIGO" -- NICK EXATO DO JOGADOR
local raioAlerta = 100 -- Alcance do radar (em blocos)

local offsetMiraX = 0  
local offsetMiraY = 1  

-- Paleta Holográfica
local C_TRANS = 0
local C_VERMELHO = colors.red
local C_BRANCO = colors.white
local C_AMARELO = colors.yellow
local C_ALERTA = colors.orange
local C_CYAN = colors.cyan
local C_VERDE = colors.lime
local C_AZUL_CLARO = colors.lightBlue
local C_CINZA = colors.gray
local C_CINZA_ESCURO = colors.lightGray

local lastX, lastY, lastZ = nil, nil, nil
local speed, speedTicks = 0, 0

-- Sistema JARVIS
local jarvisAtivo = true 
local jarvisDicas = {
    "JARVIS: Mantenha sua estamina alta para evasao.",
    "JARVIS: O minimapa e a sua maior vantagem.",
    "JARVIS: Recuo tatico e uma estrategia valida.",
    "JARVIS: O cenario atual favorece emboscadas. Atencao.",
    "JARVIS: Varredura de perimetro concluida.",
    "JARVIS: Sistemas operando em capacidade nominal.",
    "JARVIS: Mantenha seu equipamento sempre reparado."
}
local jarvisAtual = ""
local jarvisProgresso = 0
local jarvisTempoTela = 0

-- Geometria do Radar
local radarCX, radarCY = 14, 10
local visualRadius = 7
local circlePoints = {}
for i = 0, 359, 15 do
    local rad = math.rad(i)
    table.insert(circlePoints, {
        x = radarCX + math.floor(math.cos(rad) * visualRadius * 1.5),
        y = radarCY + math.floor(math.sin(rad) * visualRadius)
    })
end

local function writeData(x, y, label, colLabel, value, colValue, pad)
    hud.setCursorPos(x, y)
    hud.setTextColour(colLabel)
    hud.write(label)
    hud.setTextColour(colValue)
    local str = tostring(value)
    local emptySpace = pad - #str
    if emptySpace < 0 then emptySpace = 0 end
    hud.write(str .. string.rep(" ", emptySpace))
end

-- ==========================================
-- 1. DESENHO ESTÁTICO (MOLDURAS)
-- ==========================================
local function drawStaticHUD()
    hud.setBackgroundColour(C_TRANS)
    hud.clear()
    hud.setTextColour(C_AZUL_CLARO)

    -- Radar Local
    hud.setCursorPos(1, 1) hud.write("+==[ RADAR DE AREA ]==============-")
    hud.setCursorPos(1, 2) hud.write("||")
    hud.setCursorPos(1, 3) hud.write("||")

    -- Log de Alvos
    hud.setCursorPos(1, h - 2) hud.write("||")
    hud.setCursorPos(1, h - 1) hud.write("||")
    hud.setCursorPos(1, h)     hud.write("+==[ ALVOS PROXIMOS ]=============-")

    hud.setTextColour(C_CINZA)
    hud.setCursorPos(2, math.floor(h/2) - 1) hud.write("[")
    hud.setCursorPos(2, math.floor(h/2) + 1) hud.write("[")
    hud.setCursorPos(w - 1, math.floor(h/2) - 1) hud.write("]")
    hud.setCursorPos(w - 1, math.floor(h/2) + 1) hud.write("]")
end

-- ==========================================
-- 2. DESENHO DINÂMICO
-- ==========================================
local function updateDynamicHUD()
    hud.setBackgroundColour(C_TRANS)

    local myX, myY, myZ = 0, 0, 0
    local dadosRadar = {}
    local inimigosProximos = 0
    local inimigoMaisProximo = nil
    local menorDistanciaDeMim = 99999
    
    if detector then
        speedTicks = speedTicks + 1
        
        -- Atualiza a própria posição
        local sucMy, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMy and type(myPos) == "table" and myPos.x then
            myX, myY, myZ = math.floor(myPos.x), math.floor(myPos.y), math.floor(myPos.z)
            
            if lastX == nil then lastX, lastY, lastZ = myX, myY, myZ end
            if speedTicks >= 10 then
                local dx, dy, dz = myX - lastX, myY - lastY, myZ - lastZ
                speed = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))
                lastX, lastY, lastZ = myX, myY, myZ
                speedTicks = 0
            end
        end

        -- Escaneia outros jogadores
        local suc, pList = pcall(detector.getOnlinePlayers)
        if suc and type(pList) == "table" then
            for _, p in ipairs(pList) do
                if p ~= meuNick then
                    local sP, pos = pcall(detector.getPlayerPos, p)
                    if sP and type(pos) == "table" and pos.x then
                        local dxM, dyM, dzM = pos.x - myX, pos.y - myY, pos.z - myZ
                        local distMe = math.floor(math.sqrt(dxM*dxM + dyM*dyM + dzM*dzM))
                        
                        table.insert(dadosRadar, {
                            nome = p, dM = distMe, dxM = dxM, dyM = dyM, dzM = dzM
                        })
                        
                        if distMe <= raioAlerta then
                            inimigosProximos = inimigosProximos + 1
                            if distMe < menorDistanciaDeMim then
                                menorDistanciaDeMim = distMe
                                inimigoMaisProximo = p
                            end
                        end
                    end
                end
            end
        end
    end

    table.sort(dadosRadar, function(a, b) return a.dM < b.dM end)

    local midX = math.floor(w/2) + offsetMiraX
    local midY = math.floor(h/2) + offsetMiraY

    -- Alvo travado na tela
    if inimigoMaisProximo then
        writeData(midX - 12, midY - 2, ">> ALVO: ", C_ALERTA, inimigoMaisProximo .. " ("..menorDistanciaDeMim.."m)", C_VERMELHO, 25)
    else
        writeData(midX - 12, midY - 2, "", C_ALERTA, "", C_VERMELHO, 35)
    end

    -- ==========================================
    -- SISTEMA JARVIS
    -- ==========================================
    if jarvisAtivo then
        if jarvisAtual == "" then
            -- Jarvis fala com frequência média (chance de 1 em 80)
            if math.random(1, 80) == 1 then
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
            writeData(math.floor(midX - (#displayString / 2)), midY + 4, "", C_BRANCO, displayString, C_CYAN, 60)
        else
            writeData(midX - 30, midY + 4, "", C_BRANCO, "", C_CYAN, 60)
        end
    else
        writeData(midX - 30, midY + 4, "", C_BRANCO, "", C_CYAN, 60)
    end

    -- ==========================================
    -- RADAR LOCAL (GRADE HOLOGRÁFICA)
    -- ==========================================
    for rY = radarCY - 7, radarCY + 7 do
        hud.setCursorPos(radarCX - 12, rY)
        hud.write("                        ")
    end

    hud.setTextColour(C_CINZA_ESCURO)
    for rY = radarCY - 5, radarCY + 5 do hud.setCursorPos(radarCX, rY) hud.write("|") end
    hud.setCursorPos(radarCX - 8, radarCY) hud.write("-------+-------")

    hud.setTextColour(C_AZUL_CLARO)
    for _, pt in ipairs(circlePoints) do hud.setCursorPos(pt.x, pt.y) hud.write(".") end
    
    hud.setCursorPos(radarCX, radarCY) hud.setTextColour(C_CYAN) hud.write("V")

    for _, alvo in ipairs(dadosRadar) do
        if alvo.dM <= raioAlerta then
            local scale = visualRadius / raioAlerta
            local plotX = radarCX + math.floor(alvo.dxM * scale * 1.5)
            local plotY = radarCY + math.floor(alvo.dzM * scale)
            hud.setCursorPos(plotX, plotY)
            hud.setTextColour(C_VERMELHO)
            hud.write("X")
        end
    end

    -- ==========================================
    -- LOG DE ALVOS (INFERIOR ESQUERDO)
    -- ==========================================
    local blY = h - 6
    hud.setCursorPos(3, blY)
    hud.setTextColour(C_AZUL_CLARO)
    hud.write("ALVOS (DE VOCE):")

    local row = 1
    local printados = 0
    for _, alvo in ipairs(dadosRadar) do
        if alvo.dM <= raioAlerta and printados < 4 then
            local elev = "-"
            if alvo.dyM > 4 then elev = "^" elseif alvo.dyM < -4 then elev = "v" end
            
            writeData(3, blY + row, "[HOSTIL]", C_ALERTA, " " .. elev .. " " .. string.sub(alvo.nome, 1, 10) .. " " .. alvo.dM .. "m", C_BRANCO, 25)
            row = row + 1
            printados = printados + 1
        end
    end
    for r = row, 4 do writeData(3, blY + r, "", C_BRANCO, "", C_BRANCO, 25) end

    -- Status do Jarvis (Inferior Direito)
    local jStatus = jarvisAtivo and "[ ONLINE ]" or "[ OFFLINE ]"
    local jColor = jarvisAtivo and C_VERDE or C_CINZA
    writeData(w - 24, h - 2, "A.I :: ", C_AZUL_CLARO, jStatus, jColor, 17)
end

-- ==========================================
-- LOOP PRINCIPAL
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.cyan)
print("======================================")
print(" RED_INDUSTRIES :: LITE EDITION")
print("======================================")
term.setTextColor(colors.white)
print(" > Focado exclusivamente no operador.")
print(" > Jarvis ativo.")
print(" > [J] Liga/Desliga Jarvis.")
print(" > [Q] Desliga o HUD.")

drawStaticHUD() 

local running = true
local timer = os.startTimer(0.1)

while running do
    local event, p1 = os.pullEvent()

    if event == "timer" and p1 == timer then
        updateDynamicHUD() 
        timer = os.startTimer(0.1)
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        elseif p1 == keys.j then
            jarvisAtivo = not jarvisAtivo
            if not jarvisAtivo then
                jarvisAtual = "" 
                if speaker then speaker.playSound("block.beacon.deactivate", 1.0, 1.0) end
            else
                if speaker then speaker.playSound("block.beacon.activate", 1.0, 2.0) end
            end
        end
    end
end

hud.setBackgroundColour(C_TRANS)
hud.clear()
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("Visor LITE encerrado.")
