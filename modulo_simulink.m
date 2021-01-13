function [analisis_time, analisis_data] = modulo_simulink(nombre_modelo, parametros) 
%se carga un modelo de simulink en memoria
try
    load_system(nombre_modelo);
catch ME
    disp(ME.identifier);
    if (strcmp(ME.identifier,'Simulink:Commands:OpenSystemUnknownSystem'))
        msg = ['Modelo: <',nombre_modelo, '> no encontrado'];
        causeException = MException('MATLAB:modelo_simulink:UnknownSys',msg);
        ME = addCause(ME,causeException);
    end
    rethrow(ME);
end

%se crea un objeto input que permite agregar parametros al modelo
in = Simulink.SimulationInput(nombre_modelo);

for ii = 1:size(parametros,1)
    %se establece el valor de un parametro del modelo ligando un nombre
    %en formato de cadena con un valor numerico
    in = in.setVariable(parametros{ii,1},parametros{ii,2}); 
end

%se ejecuta la simulacion con los valores establecidos en el ciclo
%anterior y se guarda su salida

try 
    salida = sim(in);    
catch ME
    msg = ['No se han cubierto todos los parametros del modelo : ',nombre_modelo];
    causeException = MException('MATLAB:modelo_simulink:MissingArgs',msg);
    ME = addCause(ME,causeException);        
    
    rethrow(ME);
end



yout = salida.get('yout');


%se guarda la senal generada por la simulacion y se realiza una
%extraccion de los datos y su relacion temporal

analisis_time = yout{1}.Values.Time;

analisis_data = yout{1}.Values.Data;
if (size(analisis_data,1) > 1 && size(analisis_data,2) ~= 0)
    plot(analisis_time,analisis_data);
    hold on;
    grid on;
    xlabel('tiempo');
    ylabel('datos');    
else
    analisis_time = 0;
end

end
