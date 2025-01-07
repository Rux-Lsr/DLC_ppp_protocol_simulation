% --- Simulation du protocole PPP avec ARQ, contrôle de flux et en-têtes ---

% 1. Établissement du lien (LCP)
link.MTU = 1500; % Taille maximale de la trame
link.status = 'established'; % État du lien
disp('LCP: Link Established');

% --- Visualisation LCP ---
figure;
bar(1, 1, 'FaceColor', 'g'); % État établi
text(1, 1.1, 'Link Established', 'HorizontalAlignment', 'center');
ylim([0, 2]);
xlim([0, 2]);
title('LCP: Link Status');
ylabel('Status');
set(gca, 'XTick', [], 'YTick', []);
% -------------------------

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
    auth_status = 'Success';
else
    disp('CHAP: Authentification échouée');
    auth_status = 'Failed';
end

% --- Visualisation CHAP ---
figure;
plot([1, 2], [1, 1], '->', 'LineWidth', 2); % Challenge
text(1.5, 1.1, 'Challenge');
plot([2, 1], [0, 0], '->', 'LineWidth', 2); % Réponse
text(1.5, -0.1, 'Response');
text(1, 1.3, 'Serveur');
text(2, -0.3, 'Client');
text(1.5, 0.5, ['Auth Status: ' auth_status], 'HorizontalAlignment', 'center');
axis([-0.5, 3.5, -0.5, 1.5]);
title('CHAP: Authentication Flow');
set(gca, 'XTick', [], 'YTick', []);

% -------------------------

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

% --- Visualisation Trame PPP ---
figure;
parts = {'Start Flag', 'Header', 'Data', 'CRC', 'Footer', 'End Flag'};
positions = [1, 2, 3, 4, 5, 6];
bar(positions, ones(1, length(positions)), 'FaceColor', 'b');
text(positions, ones(1, length(positions)) + 0.1, parts, 'HorizontalAlignment', 'center');
ylim([0, 2]);
xlim([0, 7]);
title('PPP Frame Structure');
set(gca, 'XTick', [], 'YTick', []);
% -------------------------

% 4. Transmission avec bruit et ARQ (Stop-and-Wait)
max_retries = 3;
retry_count = 0;
original_signal = double(frame.data); % Enregistrer le signal original
transmitted_signal = original_signal + randn(1, length(frame.data)) * 0.01;
received_signals = {transmitted_signal}; % Initialiser le tableau des signaux reçus
tries = [0];
while retry_count < max_retries
    received_crc = crc32(char(transmitted_signal));
    if received_crc == frame.crc
        disp('Transmission réussie sans erreur');
        break;
    else
        disp('Erreur détectée dans la transmission, nouvelle tentative...');
        retry_count = retry_count + 1;
        transmitted_signal = original_signal + randn(1, length(frame.data)) * 0.01; % Retransmission
        received_signals{end+1} = transmitted_signal; % Ajouter les signaux recus dans le tableau
        tries = [tries, retry_count]; % Ajouter le nombre d'essai
    end
end

if retry_count == max_retries
    disp('Échec après plusieurs tentatives');
end

% --- Visualisation Transmission avec Bruit ---
figure;
plot(original_signal, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original Data');
hold on;
for i = 1:length(received_signals)
    plot(received_signals{i}, 'r--', 'LineWidth', 1, 'DisplayName', ['Transmission Attempt ' num2str(tries(i))]);
end
xlabel('Sample Index');
ylabel('Signal Value');
title('Data Transmission with Noise');
legend('show');
hold off;
% -------------------------

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

% --- Visualisation Fenêtre Glissante ---
figure;
positions = 1:window_size;
bar(positions, ones(1, window_size), 'FaceColor', 'g');
text(positions, ones(1, window_size) + 0.1, cellfun(@(x) ['Frame ' num2str(x)], num2cell(positions), 'UniformOutput', false), 'HorizontalAlignment', 'center');
ylim([0, 2]);
xlim([0, window_size + 1]);
title('Sliding Window');
xlabel('Frame Position in Window');
set(gca, 'XTick', [], 'YTick', []);
% -------------------------

% --- Fonction simple de hachage ---
function hash_value = simple_hash(input)
    % Fonction simple de hachage
    input = double(input); % Convertir l'entrée en valeurs numériques (ASCII)
    hash_value = mod(sum(input .* (1:length(input))), 1e9); % Hachage basique
end