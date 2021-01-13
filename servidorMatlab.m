function servidorMatlab()
    % definicion de servidor tcp
    t = tcpip('127.0.0.1', 1234, 'InputBufferSize', 2^15,...
        'OutputBufferSize', 2^15, 'NetworkRole', 'server', 'TimeOut', 20);
    % se define el caracter que sirve como indicador de fin de cadena
    t.Terminator = '~';
    disp('servidor iniciado.'); 
    while(1)
        % se bloquea el script en este punto hasta que llegue la conexion de un cliente
        fopen(t);

        pause(1); 
        
        % se lee el stream de datos y se convierte a cadena 
        data = fscanf(t, "%s", t.BytesAvailable);
        
        descriptor = fopen('archivo.json','w+');
        
        fwrite(descriptor, data(1:end-1));
        fclose(descriptor);

        % se convierte la cadena en formato json
        decodedData = jsondecode(data(1:end-1));

        

        outs = interpreter(decodedData);
        %disp(jsonencode(outs));

        fprintf(t, jsonencode(outs));

        fclose(t);
    end

end
