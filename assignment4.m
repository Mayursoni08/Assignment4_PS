%% build_ferranti_model_v7.m
% EE315 - Assignment 4 : Ferranti Effect Demonstration
% ------------------------------------------------------------
% v7: last three port names confirmed by MATLAB's own errors:
%   Ground (Electrical Reference)  -> single port 'V'
%   PS2S_Send / PS2S_Receive       -> physical-signal input port 'input'
%   S2PS                           -> physical-signal output port 'output'
% Every other connection already succeeded in v6 and is unchanged.
% ------------------------------------------------------------

clear; clc;

%% 1. Parameters
f = 50; V_LL = 220e3; V_phN = V_LL/sqrt(3); Vm = V_phN*sqrt(2);
r_km = 0.05; l_km = 1e-3; c_km = 0.01e-6; len_km = 200;
R_total = r_km*len_km; L_total = l_km*len_km; C_total = c_km*len_km; C_half = C_total/2;
P_load = 0.33e6; R_load = V_phN^2/P_load;
Xc_total = 1/(2*pi*f*C_total); Qc_total = (V_LL^2)/Xc_total;
Q_reactor = Qc_total/3; L_reactor = V_phN^2/(2*pi*f*Q_reactor);

fprintf('============================================\n');
fprintf('EE315 FERRANTI EFFECT MODEL\n');
fprintf('============================================\n');
fprintf('MATLAB release  : %s\n', version('-release'));
fprintf('Frequency       = %.1f Hz\n', f);
fprintf('Voltage         = %.1f kV LL\n', V_LL/1e3);
fprintf('Line length     = %.1f km\n', len_km);
fprintf('Total R         = %.3f ohm/phase\n', R_total);
fprintf('Total L         = %.4f H/phase\n', L_total);
fprintf('Total C         = %.3f uF/phase\n', C_total*1e6);
fprintf('Line charging Q = %.3f MVAr\n', Qc_total/1e6);
fprintf('Reactor L       = %.4f H/phase\n', L_reactor);
fprintf('Light load      = %.3f MW\n', P_load*3/1e6);
fprintf('============================================\n');

%% 2. New model
modelName = 'ferranti_model';
if bdIsLoaded(modelName), close_system(modelName,0); end
if exist([modelName '.slx'],'file'), delete([modelName '.slx']); end
new_system(modelName);
open_system(modelName);

function h = addb(model, lib, name, pos)
    try
        h = add_block(lib, [model '/' name]);
        set_param(h, 'Position', pos);
    catch ME
        warning('BLOCK  "%s" NOT ADDED: %s', name, ME.message);
        h = [];
    end
end

function connect2(model, b1, p1, b2, p2, label)
    try
        simscape.addConnection([model '/' b1], p1, [model '/' b2], p2);
        fprintf('  OK   %-28s (%s.%s -> %s.%s)\n', label, b1, p1, b2, p2);
    catch ME
        warning('WIRE   %-28s FAILED: %s', label, ME.message);
    end
end

%% 3. Blocks
addb(modelName, 'nesl_utility/Solver Configuration', 'Solver_Config', [30 30 90 60]);
addb(modelName, 'fl_lib/Electrical/Electrical Elements/Electrical Reference', 'Ground', [30 400 90 430]);

h_src = addb(modelName, 'fl_lib/Electrical/Electrical Sources/AC Voltage Source', 'Grid_Source', [120 100 160 150]);
if ~isempty(h_src)
    try, set_param(h_src, 'amp', num2str(Vm)); catch, end
    try, set_param(h_src, 'freq', num2str(f)); catch, end
end

addb(modelName, 'fl_lib/Electrical/Electrical Sensors/Voltage Sensor', 'VSensor_Send', [260 60 300 100]);
h_c1 = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Capacitor', 'C_send', [220 250 260 300]);
if ~isempty(h_c1), set_param(h_c1, 'C', num2str(C_half)); end

h_r = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Resistor', 'R_line', [320 100 380 140]);
if ~isempty(h_r), set_param(h_r, 'R', num2str(R_total)); end

h_l = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Inductor', 'L_line', [420 100 480 140]);
if ~isempty(h_l), set_param(h_l, 'L', num2str(L_total)); end

addb(modelName, 'fl_lib/Electrical/Electrical Sensors/Voltage Sensor', 'VSensor_Receive', [560 60 600 100]);
h_c2 = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Capacitor', 'C_receive', [520 250 560 300]);
if ~isempty(h_c2), set_param(h_c2, 'C', num2str(C_half)); end

h_load = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Resistor', 'Light_Load', [620 250 660 300]);
if ~isempty(h_load), set_param(h_load, 'R', num2str(R_load)); end

h_sw = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Switch', 'Reactor_Switch', [700 200 740 240]);
h_reactor = addb(modelName, 'fl_lib/Electrical/Electrical Elements/Inductor', 'Shunt_Reactor', [700 260 740 300]);
if ~isempty(h_reactor), set_param(h_reactor, 'L', num2str(L_reactor)); end

h_step = addb(modelName, 'simulink/Sources/Step', 'Reactor_Control', [700 340 740 370]);
if ~isempty(h_step), set_param(h_step, 'Time', '0.1', 'Before', '0', 'After', '1'); end
addb(modelName, 'nesl_utility/Simulink-PS Converter', 'S2PS', [750 340 790 370]);

addb(modelName, 'nesl_utility/PS-Simulink Converter', 'PS2S_Send', [340 60 370 90]);
addb(modelName, 'nesl_utility/PS-Simulink Converter', 'PS2S_Receive', [640 60 670 90]);
h_scope = addb(modelName, 'simulink/Sinks/Scope', 'Scope_Vs_Vr', [720 60 760 100]);
if ~isempty(h_scope), set_param(h_scope, 'NumInputPorts', '2'); end

%% 4. Wiring -- ALL port names now confirmed
fprintf('\n--- Main current path ---\n');
connect2(modelName, 'Grid_Source', 'p', 'R_line', 'p', 'Source -> R_line');
connect2(modelName, 'R_line', 'n', 'L_line', 'p', 'R_line -> L_line');
connect2(modelName, 'L_line', 'n', 'Light_Load', 'p', 'L_line -> Light_Load');
connect2(modelName, 'L_line', 'n', 'Reactor_Switch', 'p', 'L_line -> Reactor_Switch');
connect2(modelName, 'Reactor_Switch', 'n', 'Shunt_Reactor', 'p', 'Switch -> Shunt_Reactor');

fprintf('\n--- Ground / reference rail (port = V) ---\n');
connect2(modelName, 'Grid_Source', 'n', 'Ground', 'V', 'Source(-) -> Ground');
connect2(modelName, 'C_send', 'n', 'Ground', 'V', 'C_send(-) -> Ground');
connect2(modelName, 'C_receive', 'n', 'Ground', 'V', 'C_receive(-) -> Ground');
connect2(modelName, 'Light_Load', 'n', 'Ground', 'V', 'Light_Load(-) -> Ground');
connect2(modelName, 'Shunt_Reactor', 'n', 'Ground', 'V', 'Reactor(-) -> Ground');
connect2(modelName, 'C_send', 'p', 'Grid_Source', 'p', 'C_send(+) -> Sending Node');
connect2(modelName, 'C_receive', 'p', 'L_line', 'n', 'C_receive(+) -> Receiving Node');

fprintf('\n--- Voltage sensors (parallel taps) ---\n');
connect2(modelName, 'VSensor_Send', 'p', 'Grid_Source', 'p', 'VSensor_Send(+) -> Sending Node');
connect2(modelName, 'VSensor_Send', 'n', 'Ground', 'V', 'VSensor_Send(-) -> Ground');
connect2(modelName, 'VSensor_Receive', 'p', 'L_line', 'n', 'VSensor_Receive(+) -> Receiving Node');
connect2(modelName, 'VSensor_Receive', 'n', 'Ground', 'V', 'VSensor_Receive(-) -> Ground');

fprintf('\n--- Solver configuration (port = V) ---\n');
connect2(modelName, 'Solver_Config', 'port', 'Ground', 'V', 'Solver_Config -> Ground');

fprintf('\n--- Physical-signal path (V / input / output / vT) ---\n');
connect2(modelName, 'VSensor_Send', 'V', 'PS2S_Send', 'input', 'VSensor_Send.V -> PS2S_Send');
connect2(modelName, 'VSensor_Receive', 'V', 'PS2S_Receive', 'input', 'VSensor_Receive.V -> PS2S_Receive');
connect2(modelName, 'S2PS', 'output', 'Reactor_Switch', 'vT', 'S2PS -> Reactor_Switch.vT');

%% 5. Plain Simulink-signal wiring (confirmed working since v5)
fprintf('\n--- Plain Simulink signal wiring ---\n');
try, add_line(modelName, 'PS2S_Send/1', 'Scope_Vs_Vr/1', 'autorouting', 'on'); fprintf('  OK   PS2S_Send -> Scope (ch1)\n'); catch ME, warning('%s', ME.message); end
try, add_line(modelName, 'PS2S_Receive/1', 'Scope_Vs_Vr/2', 'autorouting', 'on'); fprintf('  OK   PS2S_Receive -> Scope (ch2)\n'); catch ME, warning('%s', ME.message); end
try, add_line(modelName, 'Reactor_Control/1', 'S2PS/1', 'autorouting', 'on'); fprintf('  OK   Reactor_Control -> S2PS\n'); catch ME, warning('%s', ME.message); end

%% 6. Save
set_param(modelName, 'StopTime', '0.3');
save_system(modelName, fullfile(pwd, [modelName '.slx']));
fprintf('\n============================================\n');
fprintf('Model saved: %s.slx\n', modelName);
fprintf('All ports should now be fully connected. Open the model,\n');
fprintf('press Run, then double-click Scope_Vs_Vr.\n');
fprintf('============================================\n');