function servidorMatlab()
    t = tcpip('127.0.0.1', 1234, 'InputBufferSize', 32000, 'NetworkRole', 'server', 'TimeOut', 0.5);    
    t.Terminator = 'CR';
    disp('servidor iniciado.');
    while(1)
        fopen(t);

        java.lang.Thread.sleep(1000); 
        %disp(t.BytesAvailable);
        %data = fread(t);
        resultados.solid = '1';
        resultados.simul = '2';
        resultados.comsol = '3';
        data = fscanf(t, "%s", t.BytesAvailable);
        %disp(data);
        fid = fopen('jsonfile.json', 'w');
        fprintf(fid,data);
        fclose(fid);
        decodedData = jsondecode(data);
        salidas = interpreter(decodedData);
        disp('salidas:');
        disp(salidas);
        fprintf(t, jsonencode(resultados));
        fclose(t);
    end

end
