function ppp_simul()

    % 1. Configuration dynamique
    config = configure_simulation();
    
    % On sauvegarde le mot de passe initial pour faire la comparaison plus tard
    initial_password = config.password;

    % Boucle de simulation
     figure(1); % Create a main figure
     set(gcf, 'Position', [100, 100, 1200, 800]); % Adjust figure size and position

    for sim_num = 1:config.num_simulations
        fprintf('\n--- Simulation %d ---\n', sim_num);
        
        % 2. Initialisation des variables
        link.MTU = config.link.MTU;
        link.status = 'established';
        
        % 3. Authentification (CHAP)
        [auth_success, challenge, auth_response] = authenticate(config.username, config.password, config.challenge_length, @simple_hash, initial_password);
        if auth_success
            disp('CHAP: Authentification réussie');
            auth_status = 'Success';
        else
            disp('CHAP: Authentification échouée');
            auth_status = 'Failed';
            % --- Visualisation CHAP ---
            visualize_chap(auth_status, challenge, auth_response, sim_num, initial_password, config.password, 1);
            % -------------------------
            continue;  % Passe à la prochaine simulation si l'authentification échoue
        end
        
         % --- Visualisation CHAP ---
            visualize_chap(auth_status, challenge, auth_response, sim_num, initial_password, config.password, 1);
           % -------------------------
        
        % 4. Création de la trame
        frame = encapsulate_data(config.data, config.header, config.footer);

         % --- Visualisation PPP Frame ---
        visualize_frame(frame, sim_num, 2);
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
           visualize_transmission(frame, received_signals, tries, sim_num, 3);
          % -------------------------
        % 6. Protocole de réseau (NCP)
        select_network_protocol(config.protocol);

        % 7. Control de flux
        simulate_sliding_window(frame.data, config.window_size, sim_num); % Call simulate_sliding_window without the subplot index.
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
    elseif config.noise_level < 0
        error('Noise level must be non-negative.');
    end
    
    config.max_retries = input('Nombre de retransmissions (par defaut 3) : ');
    if isempty(config.max_retries)
        config.max_retries = 3;
    elseif config.max_retries < 0
       error('Max retries must be non-negative.');
    end

    config.protocol = input('Protocole réseau (par defaut "IPv4"): ', 's');
     if isempty(config.protocol)
        config.protocol = 'IPv4';
    end
    
    config.window_size = input('Taille de la fenêtre (par defaut 4) : ');
    if isempty(config.window_size)
        config.window_size = 4;
    elseif config.window_size < 1
       error('Window size must be greater than 0.');
    end
    
    config.num_simulations = input('Nombre de simulations à exécuter (par defaut 1) : ');
    if isempty(config.num_simulations)
        config.num_simulations = 1;
    elseif config.num_simulations < 1
      error('Number of simulations must be greater than 0.');
    end
    
    config.force_no_error = input('Forcer la transmission sans erreur ? (1 pour oui, 0 pour non; par defaut 0) : ');
     if isempty(config.force_no_error)
        config.force_no_error = 0;
     end

end

% --- 2. Authentification (CHAP) ---
function [success, challenge, response] = authenticate(username, password, challenge_length, hash_function, initial_password)
    challenge = randi([0, 9], 1, challenge_length); % Challenge aléatoire
    disp(['Challenge envoyé : ', num2str(challenge)]);

    response = num2str(hash_function([password, num2str(challenge)])); % Utiliser simple_hash
    disp(['Réponse envoyée : ', response]);

    expected_response = num2str(hash_function([initial_password, num2str(challenge)])); %Utiliser le mot de passe initial pour verifier le hash du serveur
    success = strcmp(response, expected_response);
end


% --- 3. Encapsulation des données ---
function frame = encapsulate_data(data, header, footer)
    frame.start_flag = '01111110';
    frame.header = header;
    frame.data = char(data);  % Store data as a char array
    frame.crc = crc32(frame.data);
    frame.footer = footer;
    frame.end_flag = '01111110';
    disp('Trame PPP créée :');
    disp(frame);
end


% --- 4. Transmission avec bruit et ARQ ---
function [success, received_signals] = transmit_data(frame, noise_level, max_retries, force_no_error)
    retry_count = 0;
    received_signals = {}; % tableau contenant les signaux reçus
    
    data_as_double = double(frame.data);
    if force_no_error
        transmitted_signal = data_as_double; % Pas de bruit si force_no_error == 1
    else
       transmitted_signal = data_as_double + randn(1, length(data_as_double)) * noise_level;
    end
     received_signals{end+1} = transmitted_signal;
    while retry_count < max_retries
        received_crc = crc32(char(transmitted_signal));
        if received_crc == frame.crc
           success= true;
           return;
        else
            disp('Erreur détectée dans la transmission, nouvelle tentative...');
            retry_count = retry_count + 1;
             if force_no_error
                transmitted_signal = data_as_double;  % Pas de bruit si force_no_error == 1
            else
                transmitted_signal = data_as_double + randn(1, length(data_as_double)) * noise_level; % Retransmission avec bruit
            end
           received_signals{end+1} = transmitted_signal;
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
function simulate_sliding_window(data, window_size, sim_num)
    buffer = {};
    for i = 1:window_size
        buffer{i} = data;
    end
    disp('Fenêtre glissante activée, envoi des trames :');
    disp(buffer);
     % No visualization call for sliding window here
end

% --- Fonction simple de hachage ---
function hash_value = simple_hash(input)
    input = double(input);
    hash_value = mod(sum(input .* (1:length(input))), 1e9);
end
% --- Visualisation CHAP ---
function visualize_chap(auth_status, challenge, response, sim_num, initial_password, input_password, subplot_index)
    subplot(2, 2, subplot_index);
    cla;
     % Challenge arrow (Green)
    plot([1, 2], [1, 1], '->', 'LineWidth', 2, 'Color', 'b');
    text(1.5, 1.1, 'Challenge');
     % Response arrow (Red)
    plot([2, 1], [0, 0], '->', 'LineWidth', 2, 'Color', 'r');
    text(1.5, -0.1, 'Response');
    text(1, 1.3, 'Serveur');
    text(2, -0.3, 'Client');
    text(1.5, 0.5, ['Auth Status: ' auth_status], 'HorizontalAlignment', 'center');
    
     text(1, 0.8, ['Challenge: ' num2str(challenge)],'HorizontalAlignment', 'center', 'FontSize', 8);
    text(2, -0.2, ['Response: ' response], 'HorizontalAlignment', 'center', 'FontSize', 8);
     text(1, 0.6, ['Server Hash Pass: ' num2str(simple_hash([initial_password, num2str(challenge)]))], 'HorizontalAlignment', 'center', 'FontSize', 8);
     text(2, -0.4, ['Client Hash Pass: ' num2str(simple_hash([input_password, num2str(challenge)]))], 'HorizontalAlignment', 'center', 'FontSize', 8);

    axis([-0.5, 3.5, -0.5, 1.5]);
    title(['CHAP: Authentication Flow (Sim ', num2str(sim_num),')']);
    set(gca, 'XTick', [], 'YTick', []);
    drawnow; % Mettre à jour le graphique
end
% --- Visualisation Transmission avec Bruit ---
function visualize_transmission(frame, received_signals, tries, sim_num, subplot_index)
     subplot(2, 2, subplot_index);
     cla;
      data_length = min(20, length(frame.data)); % Display only 20 samples of data for clarity
     original_signal = double(frame.data(1:data_length)); % Using a small portion of data
     plot(original_signal, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Original Data');
     hold on;
     
      cmap = colormap(parula(length(received_signals)));  % Get a colormap
    for i = 1:length(received_signals)
        noisy_signal = received_signals{i};
        plot(noisy_signal(1:data_length), 'Color', cmap(i,:), 'LineStyle', '--', 'LineWidth', 1, 'DisplayName', ['Transmission Attempt ' num2str(tries(i))]);
    end
    xlabel('Sample Index');
    ylabel('Signal Value');
    title(['Data Transmission with Noise (Sim ', num2str(sim_num),')']);
    legend('show');
    hold off;
   drawnow;
end

% --- Visualisation PPP Frame ---
function visualize_frame(frame, sim_num, subplot_index)
    subplot(2, 2, subplot_index);
    cla;
    % Create a string representation of the frame
    frame_str = ['Start Flag: ', frame.start_flag, char(10),...
                 'Header: ', frame.header, char(10),...
                 'Data: ', frame.data, char(10),...
                 'CRC: ', num2str(frame.crc), char(10),...
                 'Footer: ', frame.footer, char(10),...
                 'End Flag: ', frame.end_flag];
    % Display the frame as text
    text(0.1, 0.9, frame_str, 'FontSize', 10, 'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
    title(['PPP Frame Structure (Sim ', num2str(sim_num),')']);
     axis([0, 1, 0, 1]);
     set(gca, 'XTick', [], 'YTick', []);
    drawnow;
end
% --- Exécution de la simulation ---
ppp_simul();