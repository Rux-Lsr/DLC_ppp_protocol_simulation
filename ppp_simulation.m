% --- Simulation du protocole PPP avec ARQ, contrôle de flux et en-têtes ---

% 1. Établissement du lien (LCP)
link.MTU = 1500; % Taille maximale de la trame
link.status = 'established'; % État du lien
disp('LCP: Link Established');

% 2. Authentification (CHAP)
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

% 3. Encapsulation des données (avec en-tête et queue)
data = 'Hello, this is a PPP simulation!';
frame.start_flag = '01111110'; % Délimiteur de début
frame.header = 'Header info'; % En-tête de contrôle (peut inclure des adresses)
frame.data = data;
frame.crc = crc32(data); % Calcul du CRC
frame.footer = 'Footer info'; % Queue avec information CRC de fin
frame.end_flag = '01111110'; % Délimiteur de fin
disp('Trame PPP créée :');
disp(frame);

% 4. Transmission avec bruit et ARQ (Stop-and-Wait)
max_retries = 3;
retry_count = 0;
transmitted_signal = double(frame.data) + randn(1, length(frame.data)) * 0.01;
while retry_count < max_retries
    received_crc = crc32(char(transmitted_signal));
    if received_crc == frame.crc
        disp('Transmission réussie sans erreur');
        break;
    else
        disp('Erreur détectée dans la transmission, nouvelle tentative...');
        retry_count = retry_count + 1;
        transmitted_signal = double(frame.data) + randn(1, length(frame.data)) * 0.01; % Retransmission
    end
end
if retry_count == max_retries
    disp('Échec après plusieurs tentatives');
end

% 5. Sélection du protocole réseau (NCP - Network Control Protocol)
protocol = 'IPv4';
ncp.protocol_type = protocol;
ncp.data = 'Packet data for IPv4';
disp(['Protocole sélectionné : ', ncp.protocol_type]);
disp('Données encapsulées dans PPP');

% 6. Contrôle de flux avec fenêtre glissante
window_size = 4; % Taille de la fenêtre
buffer = {}; % Tampon des trames envoyées
for i = 1:window_size
    buffer{i} = frame.data; % Ajouter les trames dans le tampon
end
disp('Fenêtre glissante activée, envoi des trames :');
disp(buffer);

% --- Fonction simple de hachage ---
function hash_value = simple_hash(input)
    % Fonction simple de hachage
    input = double(input); % Convertir l'entrée en valeurs numériques (ASCII)
    hash_value = mod(sum(input .* (1:length(input))), 1e9); % Hachage basique
end
