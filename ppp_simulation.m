% --- Simulation du protocole PPP ---

% 1. Établissement du lien (LCP)
link.MTU = 1500; % Taille maximale de la trame
link.status = 'established'; % État du lien
disp('LCP: Link Established');

% 2. Authentification (CHAP - Challenge Handshake Authentication Protocol)
username = 'client';
password = 'securepassword';

% Serveur envoie un challenge
challenge = randi([0, 9], 1, 5); % Challenge aléatoire
disp(['Challenge envoyé : ', num2str(challenge)]);

% Client répond avec un hachage
response = num2str(simple_hash([password, num2str(challenge)])); % Utiliser simple_hash
disp(['Réponse envoyée : ', response]);

% Serveur vérifie le hachage
expected_response = num2str(simple_hash([password, num2str(challenge)]));
if strcmp(response, expected_response)
    disp('CHAP: Authentification réussie');
else
    disp('CHAP: Authentification échouée');
end

% 3. Encapsulation des données
frame = struct(); % Initialiser la structure
frame.start_flag = '01111110'; % Délimiteur de début
frame.data = data;
frame.crc = crc32(data); % Calcul du CRC
frame.end_flag = '01111110'; % Délimiteur de fin
disp('Trame PPP créée :');
disp(frame);


% 4. Transmission avec bruit
transmitted_signal = double(frame.data) + randn(1, length(frame.data)) * 0.01;
received_crc = crc32(char(transmitted_signal));
if received_crc == frame.crc
    disp('Transmission réussie sans erreur');
else
    disp('Erreur détectée dans la transmission');
end

% 5. Sélection du protocole réseau (NCP - Network Control Protocol)
protocol = 'IPv4'; % Peut être 'IPv6', 'AppleTalk', etc.
ncp.protocol_type = protocol;
ncp.data = 'Packet data for IPv4';
disp(['Protocole sélectionné : ', ncp.protocol_type]);
disp('Données encapsulées dans PPP');


% --- Fonction simple de hachage ---
function hash_value = simple_hash(input)
    % Fonction simple de hachage
    % Convertit l'entrée en valeurs ASCII et effectue une somme pondérée
    
    input = double(input); % Convertir l'entrée en valeurs numériques (ASCII)
    hash_value = mod(sum(input .* (1:length(input))), 1e9); % Hachage basique
end
