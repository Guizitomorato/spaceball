<!DOCTYPE html>
<html>
<head>
    <title>Jogo Multiplayer</title>
    <style>
        /* Estilos para o canvas */
        #gameCanvas {
            border: 1px solid black;
        }
    </style>
</head>
<body>
    <div id="nicknameDialog">
        <label for="nickname">Nickname:</label>
        <input type="text" id="nickname" maxlength="20">
        <button onclick="setNickname()">Confirmar</button>
    </div>
    <canvas id="gameCanvas" width="800" height="600"></canvas>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.1.2/socket.io.js"></script>
    <script>
        const socket = io('http://localhost:5000'); // Conexão com o servidor

        const canvas = document.getElementById('gameCanvas');
        const ctx = canvas.getContext('2d');
        const moveSpeed = 5;

        let playerX = canvas.width / 2;
        let playerY = canvas.height / 2;
        let moveX = 0;
        let moveY = 0;
        let nickname = '';
        let playerId = null;
        let gameStarted = false;
        const players = {}; // Armazenar informações dos jogadores conectados

        function setNickname() {
            const inputNickname = document.getElementById('nickname').value;
            if (inputNickname.trim() !== '') {
                nickname = inputNickname;
                document.getElementById('nicknameDialog').style.display = 'none'; // Esconder o diálogo de entrada do nickname
                gameStarted = true; // Permitir o início do jogo
                socket.emit('setNickname', { nickname }); // Enviar o nickname para o servidor
                startGame();
            }
        }

        function startGame() {
            document.getElementById('gameCanvas').style.display = 'block'; // Mostrar o canvas
            playerId = socket.id; // Armazenar o ID do jogador local
            setupEventListeners(); // Configurar os eventos de movimentação do jogador
            updatePosition();
        }

        socket.on('connect', () => {
            console.log(`Conectado com o ID: ${socket.id}`);
        });

        socket.on('disconnect', () => {
            console.log(`Desconectado do servidor`);
            // Limpeza do jogo, caso necessário
        });

        socket.on('playerLeft', (data) => {
            if (gameStarted) {
                const leftPlayerNickname = data.nickname;
                delete players[leftPlayerNickname];
            }
        });

        socket.on('update', (serverPlayers) => {
            if (gameStarted) {
                // Atualizar as informações dos jogadores conectados
                for (const [socketId, playerData] of Object.entries(serverPlayers)) {
                    if (socketId === playerId) {
                        // Se o jogador local, atualize a posição
                        playerX = playerData.x;
                        playerY = playerData.y;
                        nickname = playerData.nickname;
                    } else {
                        // Se jogador remoto, atualize a lista de jogadores
                        players[socketId] = { x: playerData.x, y: playerData.y, nickname: playerData.nickname };
                    }
                }

                // Limpar o canvas antes de desenhar os jogadores atualizados
                ctx.clearRect(0, 0, canvas.width, canvas.height);

                // Desenhar todos os jogadores
                for (const playerData of Object.values(players)) {
                    const x = playerData.x;
                    const y = playerData.y;
                    const remoteNickname = playerData.nickname;

                    ctx.beginPath();
                    ctx.arc(x, y, 10, 0, 2 * Math.PI);
                    ctx.fillStyle = 'red'; // Jogador remoto é vermelho
                    ctx.fill();
                    ctx.closePath();

                    ctx.font = '12px Arial';
                    ctx.textAlign = 'center';
                    ctx.fillText(remoteNickname, x, y - 20);
                }

                // Desenhar o jogador local (bola) na posição x, y
                ctx.beginPath();
                ctx.arc(playerX, playerY, 10, 0, 2 * Math.PI);
                ctx.fillStyle = 'blue'; // Jogador local é azul
                ctx.fill();
                ctx.closePath();
                ctx.font = '12px Arial';
                ctx.textAlign = 'center';
                ctx.fillText(nickname, playerX, playerY - 20);
            }
        });

        function sendMove(x, y) {
            socket.emit('move', { x, y });
        }

        // Capturar eventos de teclas para movimentar o jogador local
        function setupEventListeners() {
            document.addEventListener('keydown', (event) => {
                switch (event.keyCode) {
                    case 37: // Esquerda
                        moveX = -moveSpeed;
                        break;
                    case 38: // Cima
                        moveY = -moveSpeed;
                        break;
                    case 39: // Direita
                        moveX = moveSpeed;
                        break;
                    case 40: // Baixo
                        moveY = moveSpeed;
                        break;
                }
            });

            document.addEventListener('keyup', () => {
                moveX = 0;
                moveY = 0;
            });
        }

        function updatePosition() {
            if (gameStarted) {
                requestAnimationFrame(updatePosition);

                // Atualizar a posição do jogador local com base nas teclas pressionadas
                playerX += moveX;
                playerY += moveY;

                // Restringir a posição da bola aos limites da tela
                playerX = Math.max(10, Math.min(canvas.width - 10, playerX));
                playerY = Math.max(10, Math.min(canvas.height - 10, playerY));

                // Enviar a posição atualizada para o servidor
                sendMove(playerX, playerY);
            }
        }

        // Iniciar o jogo após o carregamento da página
        document.addEventListener('DOMContentLoaded', () => {
            document.getElementById('nicknameDialog').style.display = 'block'; // Mostrar o diálogo de entrada do nickname
        });

        updatePosition();
    </script>
</body>
</html>
