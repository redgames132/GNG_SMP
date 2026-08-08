-- ==========================================
-- HUD GLASSES - RED_INDUSTRIES_OS (PRO)
-- Tema: Cyberpunk / Vermelho Tático + Tecla Q
-- ==========================================

local hud = peripheral.find("hud_glasses")
local detector = peripheral.find("player_detector")

if not hud then
    term.clear()
    term.setCursorPos(1, 1)
    term.setTextColor(colors.red)
    print("ERRO CRITICO: HUD Modem nao encontrado!")
    print("Conecte o bloco HUD Modem ao computador.")
    return
end

-- ==========================================
-- CONFIGURAÇÕES (MUDE O SEU NICK AQUI)
-- ==========================================
local meuNick = "redgames132" -- Substitua pelo seu nick exato do Minecraft
local raioAlerta = 50            -- Raio de proximidade do radar (em blocos)

-- Cores do Tema
local C_FUNDO    = 0             -- 0 = Transparente
local C_VERMELHO = colors.red
local C_CINZA    = colors.gray
local C_BRANCO   = colors.white
local C_ALERTA   = colors.orange
local C_VERDE    = colors.lime
local C_CYAN     = colors.cyan

local frame = 0
local spinners = {"-", "\\", "|", "/"}

-- Formata os ticks do jogo para o formato HH:MM
local function formatTime(t)
    local hora = math.floor(t)
    local min = math.floor((t - hora) * 60)
    return string.format("%02d:%02d", hora, min)
end

-- ==========================================
-- DESENHO DA UI DO HUD
-- ==========================================
local function drawHUD()
    hud.setBackgroundColour(C_FUNDO)
    hud.clear()

    local animFrame = spinners[(frame % #spinners) + 1]

    -- 1. PAINEL SUPERIOR DE STATUS (BOX TÁTICO)
    hud.setCursorPos(1, 1)
    hud.setTextColour(C_VERMELHO)
    hud.write("+--[ ")
    hud.setTextColour(C_BRANCO)
    hud.write("RED_INDUSTRIES_OS")
    hud.setTextColour(C_VERMELHO)
    hud.write(" ]--+")

    hud.setCursorPos(1, 2)
    hud.setTextColour(C_VERMELHO)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("SYS: ")
    hud.setTextColour(C_VERDE)
    hud.write("ONLINE " .. animFrame)
    hud.setTextColour(C_CINZA)
    hud.write(" | ")
    hud.setTextColour(C_BRANCO)
    hud.write("D:" .. os.day() .. " " .. formatTime(os.time()))

    -- 2. RASTREAMENTO DE COORDENADAS (Sua Posição)
    local myX, myY, myZ = -573, 57, -1446 -- Fallback para a base
    if detector then
        local sucMyPos, myPos = pcall(detector.getPlayerPos, meuNick)
        if sucMyPos and myPos and myPos.x then
            myX = math.floor(myPos.x)
            myY = math.floor(myPos.y)
            myZ = math.floor(myPos.z)
        end
    end

    hud.setCursorPos(1, 3)
    hud.setTextColour(C_VERMELHO)
    hud.write("| ")
    hud.setTextColour(C_CINZA)
    hud.write("POS: ")
    hud.setTextColour(C_CYAN)
    hud.write(myX .. ", " .. myY .. ", " .. myZ)

    hud.setCursorPos(1, 4)
    hud.setTextColour(C_VERMELHO)
    hud.write("+-----------------------------+")

    -- 3. SEÇÃO DO RADAR DE PROXIMIDADE (50m)
    hud.setCursorPos(1, 6)
    hud.setTextColour(C_VERMELHO)
    hud.write("> SENSOR DE PROXIMIDADE (50m)")

    if detector then
        local suc, players = pcall(detector.getOnlinePlayers)
        if suc and type(players) == "table" then
            local row = 7
            local alvosEncontrados = 0

            for _, p in ipairs(players) do
                -- Ignora o seu próprio nick
                if p ~= meuNick then
                    local sP, pos = pcall(detector.getPlayerPos, p)
                    if sP and pos and pos.x then
                        local dx = pos.x - myX
                        local dy = pos.y - myY
                        local dz = pos.z - myZ
                        local dist = math.floor(math.sqrt(dx*dx + dy*dy + dz*dz))

                        hud.setCursorPos(2, row)

                        if dist <= raioAlerta then
                            -- Alerta Vermelho/Laranja para alvos muito próximos
                            hud.setTextColour(C_ALERTA)
                            hud.write("[!] " .. p)
                            hud.setTextColour(C_VERMELHO)
                            hud.write(" -> " .. dist .. "m")
                        else
                            -- Alvos mais distantes em cinza discreto
                            hud.setTextColour(C_CINZA)
                            hud.write("[-] " .. p .. " (" .. dist .. "m)")
                        end

                        row = row + 1
                        alvosEncontrados = alvosEncontrados + 1
                        if alvosEncontrados >= 6 then break end -- Mantém a tela limpa
                    end
                end
            end

            if alvosEncontrados == 0 then
                hud.setCursorPos(2, row)
                hud.setTextColour(C_CINZA)
                hud.write(">> Nenhum alvo no perimetro <<")
            end
        else
            hud.setCursorPos(2, 7)
            hud.setTextColour(C_VERMELHO)
            hud.write("[ ERRO NO SENSOR ]")
        end
    else
        hud.setCursorPos(2, 7)
        hud.setTextColour(C_CINZA)
        hud.write("[ SENSOR OFFLINE ]")
    end
end

-- ==========================================
-- LOOP PRINCIPAL (ESCUTA DE EVENTOS + TECLA Q)
-- ==========================================
term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.red)
print("======================================")
print("   RED_INDUSTRIES HUD OS - PRO")
print("======================================")
term.setTextColor(colors.white)
print(" > Transmissao visual estabelecida.")
print(" > Oculos online.")
print(" > Pressione [Q] no computador para SAIR.")
print("--------------------------------------")

local running = true
local timer = os.startTimer(0.25)

while running do
    local event, p1 = os.pullEvent()

    -- Atualiza a animação e o radar a cada 0.25s
    if event == "timer" and p1 == timer then
        drawHUD()
        frame = frame + 1
        timer = os.startTimer(0.25)

    -- Interrompe o script se apertar a tecla Q
    elseif event == "key" then
        if p1 == keys.q then
            running = false
        end
    end
end

-- Limpa os óculos e o terminal ao encerrar
hud.setBackgroundColour(C_FUNDO)
hud.clear()

term.clear()
term.setCursorPos(1, 1)
term.setTextColor(colors.lime)
print("HUD Red_Industries encerrado com sucesso.")
