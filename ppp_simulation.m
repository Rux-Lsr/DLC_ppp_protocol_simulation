% --- Simulation du protocole PPP dynamique avec visualisation ---

function ppp_simul()

    % 1. Configuration dynamique
    config = configure_simulation();

    % Boucle de simulation
    for sim_num = 1:config.num_simulations
        fprintf('\n--- Simulation %d ---\n', sim_num);
        
        % 2. Initialisation des variables
        link.MTU = config.link.MTU;
        link.status = 'established';

       % --- Visualisation LCP ---
        figure(1);
        bar(1, 1, 'FaceColor', 'g'); % État établi
        text(1, 1.1, 'Link Established', 'HorizontalAlignment', 'center');
        ylim([0, 2]);
        xlim([0, 2]);
        title(['LCP: Link Status (Sim ', num2str(sim_num),')']);
        ylabel('Status');
        set(gca, 'XTick', [], 'YTick', []);
        drawnow; % Mettre à jour le graphique
        % -------------------------
        
        % 3. Authentification (CHAP)
        [auth_success, auth_response] = authenticate(config.username, config.password, config.challenge_length, @simple_hash);
        if auth_success
            disp('CHAP: Authentification réussie');
            auth_status = 'Success';
        else
            disp('CHAP: Authentification échouée');
            auth_status = 'Failed';
             % --- Visualisation CHAP ---
             figure(2);
            plot([1, 2], [1, 1], '->', 'LineWidth', 2); % Challenge
            text(1.5, 1.1, 'Challenge');
            plot([2, 1], [0, 0], '->', 'LineWidth', 2); % Réponse
            text(1.5, -0.1, 'Response');
            text(1, 1.3, 'Serveur');
            text(2, -0.3, 'Client');
            text(1.5, 0.5, ['Auth Status: ' auth_status], 'HorizontalAlignment', 'center');
            axis([-0.5, 3.5, -0.5, 1.5]);
             title(['CHAP: Authentication Flow (Sim ', num2str(sim_num),')']);
            set(gca, 'XTick', [], 'YTick', []);
            drawnow; % Mettre à jour le graphique
           % -------------------------
            continue;  % Passe à la prochaine simulation si l'authentification échoue
        end
        
         % --- Visualisation CHAP ---
            figure(2);
            plot([1, 2], [1, 1], '->', 'LineWidth', 2); % Challenge
            text(1.5, 1.1, 'Challenge');
            plot([2, 1], [0, 0], '->', 'LineWidth', 2); % Réponse
            text(1.5, -0.1, 'Response');
            text(1, 1.3, 'Serveur');
            text(2, -0.3, 'Client');
            text(1.5, 0.5, ['Auth Status: ' auth_status], 'HorizontalAlignment', 'center');
            axis([-0.5, 3.5, -0.5, 1.5]);
             title(['CHAP: Authentication Flow (Sim ', num2str(sim_num),')']);
            set(gca, 'XTick', [], 'YTick', []);
            drawnow; % Mettre à jour le graphique
           % -------------------------
        
        % 4. Création de la trame
        frame = encapsulate_data(config.data, config.header, config.footer);
        
         % --- Visualisation Trame PPP ---
            figure(3);
            parts = {'Start Flag', 'Header', 'Data', 'CRC', 'Footer', 'End Flag'};
            positions = [1, 2, 3, 4, 5, 6];
            bar(positions, ones(1, length(positions)), 'FaceColor', 'b');
            text(positions, ones(1, length(positions)) + 0.1, parts, 'HorizontalAlignment', 'center');
            ylim([0, 2]);
            xlim([0, 7]);
             title(['PPP Frame Structure (Sim ', num2str(sim_num),')']);
            set(gca, 'XTick', [], 'YTick', []);
            drawnow; % Mettre à jour le graphique
            % -------------------------

        % 5. Transmission avec bruit et ARQ
        [transmission_result, received_signals] = transmit_data(frame, config.noise_level, config.max_retries, config.force_no_error);
        if transmission_result
           disp('Transmission réussie');
            tries = 1:length(received_signals);
        else
            disp('Échec après plusieurs tentatives de transmission.');
            tries = 1:length(received_signals);

        end

         % --- Visualisation Transmission avec Bruit ---
            figure(4);
            original_signal = double(frame.data);
            plot(original_signal, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original Data');
            hold on;
            for i = 1:length(received_signals)
                plot(received_signals{i}, 'r--', 'LineWidth', 1, 'DisplayName', ['Transmission Attempt ' num2str(tries(i))]);
            end
             xlabel('Sample Index');
            ylabel('Signal Value');
            title(['Data Transmission with Noise (Sim ', num2str(sim_num),')']);
            legend('show');
            hold off;
           drawnow;
          % -------------------------


        % 6. Protocole de réseau (NCP)
        select_network_protocol(config.protocol);

        % 7. Control de flux
        simulate_sliding_window(frame.data, config.window_size);
        
          % --- Visualisation Fenêtre Glissante ---
        figure(5);
        positions = 1:config.window_size;
        bar(positions, ones(1, config.window_size), 'FaceColor', 'g');
        text(positions, ones(1, config.window_size) + 0.1, cellfun(@(x) ['Frame ' num2str(x)], num2cell(positions), 'UniformOutput', false), 'HorizontalAlignment', 'center');
        ylim([0, 2]);
        xlim([0, config.window_size + 1]);
        title(['Sliding Window (Sim ', num2str(sim_num),')']);
        xlabel('Frame Position in Window');
        set(gca, 'XTick', [], 'YTick', []);
        drawnow;
        % -------------------------

    end
end

% --- 1. Configuration de la simulation ---
function config = configure_simulation()
    disp('--- Configuration de la simulation ---');
    config.link.MTU = input('Entrez la MTU (par defaut 1500) : ');
    if isempty(config.link.MTU)
        config.link.MTU = 1500;
    end
    config.username = input('Nom d''utilisateur (par defaut client): ', 's');
    if isempty(config.username)
       config.username = 'client';
    end
     config.password = input('Mot de passe (par defaut securepassword): ', 's');
    if isempty(config.password)
       config.password = 'securepassword';
    end
    config.challenge_length = input('Longueur du challenge (par defaut 5): ');
     if isempty(config.challenge_length)
       config.challenge_length = 5;
     end
    config.data = input('Données à transmettre (par defaut "Hello, this is a PPP simulation!"): ', 's');
    if isempty(config.data)
        config.data = 'Hello, this is a PPP simulation!';
    end
    config.header = input('En-tête (par defaut "Header info"): ', 's');
        if isempty(config.header)
       config.header = 'Header info';
    end
        config.footer = input('Pied de page (par defaut "Footer info"): ', 's');
        if isempty(config.footer)
            config.footer = 'Footer info';
         end

    config.noise_level = input('Niveau de bruit (par defaut 0.01) : ');
    if isempty(config.noise_level)
        config.noise_level = 0.01;
    end
    config.max_retries = input('Nombre de retransmissions (par defaut 3) : ');
    if isempty(config.max_retries)
        config.max_retries = 3;
    end
    config.protocol = input('Protocole réseau (par defaut "IPv4"): ', 's');
     if isempty(config.protocol)
        config.protocol = 'IPv4';
    end
    config.window_size = input('Taille de la fenêtre (par defaut 4) : ');
    if isempty(config.window_size)
        config.window_size = 4;
    end
    config.num_simulations = input('Nombre de simulations à exécuter (par defaut 1) : ');
    if isempty(config.num_simulations)
        config.num_simulations = 1;
    end
    config.force_no_error = input('Forcer la transmission sans erreur ? (1 pour oui, 0 pour non; par defaut 0) : ');
     if isempty(config.force_no_error)
        config.force_no_error = 0;
     end

end

% --- 2. Authentification (CHAP) ---
function [success, response] = authenticate(username, password, challenge_length, hash_function)
    challenge = randi([0, 9], 1, challenge_length); % Challenge aléatoire
    disp(['Challenge envoyé : ', num2str(challenge)]);

    response = num2str(hash_function([password, num2str(challenge)])); % Utiliser simple_hash
    disp(['Réponse envoyée : ', response]);

    expected_response = num2str(hash_function([password, num2str(challenge)]));
    success = strcmp(response, expected_response);
end


% --- 3. Encapsulation des données ---
function frame = encapsulate_data(data, header, footer)
    frame.start_flag = '01111110';
    frame.header = header;
    frame.data = data;
    frame.crc = crc32(data);
    frame.footer = footer;
    frame.end_flag = '01111110';
    disp('Trame PPP créée :');
    disp(frame);
end


% --- 4. Transmission avec bruit et ARQ ---
function [success, received_signals] = transmit_data(frame, noise_level, max_retries, force_no_error)
    retry_count = 0;
     received_signals = {}; % tableau contenant les signaux reçus
    if force_no_error
        transmitted_signal = double(frame.data); % Pas de bruit si force_no_error == 1
        received_signals{end+1} = transmitted_signal;
    else
         transmitted_signal = double(frame.data) + randn(1, length(frame.data)) * noise_level;
          received_signals{end+1} = transmitted_signal;
    end


    while retry_count < max_retries
        received_crc = crc32(char(transmitted_signal));
        if received_crc == frame.crc
           success= true;
           return;
        else
            disp('Erreur détectée dans la transmission, nouvelle tentative...');
            retry_count = retry_count + 1;
            if force_no_error
                transmitted_signal = double(frame.data);  % Pas de bruit si force_no_error == 1
                received_signals{end+1} = transmitted_signal;
            else
                transmitted_signal = double(frame.data) + randn(1, length(frame.data)) * noise_level; % Retransmission avec bruit
                  received_signals{end+1} = transmitted_signal;
            end

        end
    end
     success = false;
end

% --- 5. Sélection du protocole réseau (NCP) ---
function select_network_protocol(protocol)
    ncp.protocol_type = protocol;
    ncp.data = ['Packet data for ' protocol];
    disp(['Protocole sélectionné : ', ncp.protocol_type]);
    disp('Données encapsulées dans PPP');
end

% --- 6. Contrôle de flux avec fenêtre glissante ---
function simulate_sliding_window(data, window_size)
    buffer = {};
    for i = 1:window_size
        buffer{i} = data;
    end
    disp('Fenêtre glissante activée, envoi des trames :');
    disp(buffer);
end

% --- Fonction simple de hachage ---
function hash_value = simple_hash(input)
    input = double(input);
    hash_value = mod(sum(input .* (1:length(input))), 1e9);
end

% --- Exécution de la simulation ---
ppp_simul();