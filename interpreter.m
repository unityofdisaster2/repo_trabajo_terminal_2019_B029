function outs = interpreter(jsonObject)
    % nota, cuando se quiera modificar algo, hacerlo directamente sobre el
    % objeto y no sobre referencias ya que en matlab no hay paso o
    % igualacion de referencias
    
    
    
    % se obtiene el nombre de los objetos que componen el json
    objectNames = fieldnames(jsonObject);
    % se itera sobre el numero de objetos existentes
    % disp(jsonencode(jsonObject));
    
    for ii = 1:numel(objectNames)
        % se verifica si el objeto tiene un modelo de SolidWorks
        objetoActual = jsonObject.(objectNames{ii});
        
        try

            if strcmp('SolidWorks', objetoActual.staticParams.modelType)
                % creacion de celda de n*2 para guardar los valores numericos de cada parametro
                solidParams = cell(size(objetoActual.parametros, 1), 2);

                for numParam = 1:size(objetoActual.parametros)
                    % asignacion de valores que seran enviados a funcion
                    % modulo_CAD
                    solidParams{numParam, 1} = objetoActual.parametros(numParam).name;
                    solidParams{numParam, 2} = str2double(objetoActual.parametros(numParam).value);
                end

                solidModelName = objetoActual.staticParams.modelName;
                % se abre el modelo que sera utilizado por COMSOL
                modelo = mphopen(strcat(solidModelName, '.mph'));
                modulo_CAD(modelo, solidParams);
            end

        catch DI

            if strcmp('MATLAB:structRefFromNonStruct', DI.identifier)
                fprintf('objeto %s no tiene static params\n', objetoActual.name);
            else
                rethrow(DI);
            end

        end

        % si tiene procesos se itera sobre ellos
        try
            size(objetoActual.procesos);
        catch NE

            if strcmp('MATLAB:nonExistentField', NE.identifier)
                fprintf('objeto %s no tiene procesos\n', objetoActual.name);
                continue;
            else
                rethrow(NE);
            end

        end

        if size(objetoActual.procesos) > 0

            for jj = 1:size(objetoActual.procesos, 1)
                %disp(objetoActual.procesos(jj).parametros);
                if strcmp(objetoActual.procesos(jj).parametros.tipo, 'Simulink')
                    nombreModeloSim = objetoActual.procesos(jj).parametros.reference;
                    numReqs = size(objetoActual.procesos(jj).reqs, 1);
                    numInputs = size(objetoActual.procesos(jj).inputs.values, 1);

                    simulParams = cell(numReqs + numInputs, 2);

                    for ll = 1:numReqs
                        simulParams{ll, 1} = objetoActual.procesos(jj).reqs(ll).name;
                        simulParams{ll, 2} = str2double(objetoActual.procesos(jj).reqs(ll).value);
                    end

                    for mm = 1:numInputs
                        simulParams{numReqs + mm, 1} = objetoActual.procesos(jj).inputs.from(mm).port;
                        % se hace esta verificacion ya que los valores
                        % recibidos desde el frontend se detectan como
                        % cadena, pero los generados por la salida de
                        % otros procesos ya son inyectados como numeros,
                        % por esto no es necesario hacer la conversion.
                        if isnumeric(objetoActual.procesos(jj).inputs.values(mm))
                           simulParams{numReqs + mm, 2} = objetoActual.procesos(jj).inputs.values(mm);
                        else
                            simulParams{numReqs + mm, 2} = str2double(objetoActual.procesos(jj).inputs.values(mm));
                        end
                        
                    end

                    simRes = 0;
                    % disp('parametros simparams');
                    % disp(simulParams);
                    [tiempo, simRes] = modulo_simulink(nombreModeloSim, simulParams);
                    % se guarda el resultado en la propiedad values del
                    % proceso actual
                    jsonObject.(objectNames{ii}).procesos.outputs.values = ...
                        [jsonObject.(objectNames{ii}).procesos.outputs.values; simRes];
                    
                    % se distribuyen los resultados a todos los elementos a
                    % los que se dirija la salida del proceso
                    jsonObject = distribute_output(objetoActual, jj, jsonObject, simRes);

                    
                    fprintf('objeto padre: %s\n',objetoActual.name);
                    fprintf('resultado proceso %s: %f\n\n', objetoActual.procesos(jj).name, simRes);
                    processResults.(strcat(objetoActual.name,'_',objetoActual.procesos(jj).name)) = simRes;
                end

            end

        end

    end
    
    outs = processResults;
    % outs = jsonObject;

end


function updatedObject = distribute_output(objetoActual, processIndex, jsonObject, outValue)
    for toIndex = 1:size(objetoActual.procesos(processIndex).outputs.to, 1)
        % se guarda la referencia del arreglo que contiene
        % los elementos a los que se dirige la salida
        toReference = objetoActual.procesos(processIndex).outputs.to(toIndex);

        if (strcmp(toReference.type, 'opm.ChildObject') || ...
                strcmp(toReference.type, 'opm.Object'))
            
            nombreCampo = formatName(toReference.elementID);

            if strcmp(toReference.type, 'opm.ChildObject')
                % si se cumple esta condicion el valor se dirige a un output
                
                jsonObject.(nombreCampo).outputs.(toReference.port).values = ...
                    [jsonObject.(nombreCampo).outputs.(toReference.port).values; outValue];
				% se verifica si este output esta conectado a otros elementos
                if size(jsonObject.(nombreCampo).outputs.(toReference.port).to,1) > 0
                    % se envia la salida a los elementos a los que se conecte el output
                    jsonObject = send_from_object(jsonObject, outValue, ...
                        jsonObject.(nombreCampo).outputs.(toReference.port).to);
                end
            elseif strcmp(toReference.type, 'opm.ChildObject')
                %disp('se dirige a un input');
                jsonObject.(nombreCampo).inputs.(toReference.port).values = ...
                    [jsonObject.(nombreCampo).inputs.(toReference.port).values; outValue];
                
                
                if size(jsonObject.(nombreCampo).inputs.(toReference.port).to,1) > 0
                    %disp('hay que distribuir la salida');
                    jsonObject = send_from_object(jsonObject, outValue, ...
                        jsonObject.(nombreCampo).inputs.(toReference.port).to);
                    
                end
            end

        elseif strcmp(toReference.type, 'opm.Process')
            parentName = formatName(toReference.parent);
            for procNum = 1:size(jsonObject.(parentName).procesos,1)
                if strcmp(jsonObject.(parentName).procesos(procNum).id, toReference.elementID)
                    jsonObject.(parentName).procesos(procNum).inputs.values = ...
                        [jsonObject.(parentName).procesos(procNum).inputs.values; outValue];
                    
                    break;
                end
            end
        end
        
        
        
    end

    updatedObject = jsonObject;

end

function updatedObject = send_from_object(jsonObject, outValue, toArray)

    for toIndex = 1:size(toArray, 1)

        % se guarda la referencia del arreglo que contiene
        % los elementos a los que se dirige la salida
        toReference = toArray(toIndex);

        if (strcmp(toReference.type, 'opm.ChildObject') || ...
                strcmp(toReference.type, 'opm.Object'))
            
            nombreCampo = formatName(toReference.elementID);

            if strcmp(toReference.type, 'opm.ChildObject')
                
                jsonObject.(nombreCampo).outputs.(toReference.port).values = ...
                    [jsonObject.(nombreCampo).outputs.(toReference.port).values; outValue];

                if size(jsonObject.(nombreCampo).outputs.(toReference.port).to,1) > 0
                    %disp('hay que distribuir la salida');
                    jsonObject = send_from_object(jsonObject, outValue, ...
                        jsonObject.(nombreCampo).outputs.(toReference.port).to);
                end
            elseif strcmp(toReference.type, 'opm.ChildObject')
                %disp('se dirige a un input');
                jsonObject.(nombreCampo).inputs.(toReference.port).values = ...
                    [jsonObject.(nombreCampo).inputs.(toReference.port).values; outValue];
                
                
                if size(jsonObject.(nombreCampo).inputs.(toReference.port).to,1) > 0
                    %disp('hay que distribuir la salida');
                    jsonObject = send_from_object(jsonObject, outValue, ...
                        jsonObject.(nombreCampo).inputd.(toReference.port).to);                    
                end
            end

        elseif strcmp(toReference.type, 'opm.Process')
            parentName = formatName(toReference.parent);
            for procNum = 1:size(jsonObject.(parentName).procesos,1)
                if strcmp(jsonObject.(parentName).procesos(procNum).id, toReference.elementID)
                    jsonObject.(parentName).procesos(procNum).inputs.values = ...
                        [jsonObject.(parentName).procesos(procNum).inputs.values; outValue];
                    
                    break;
                end
            end
        end
        
        
    
    
    end

    updatedObject = jsonObject;

end


function newName = formatName(campo) 
    % es posible evitar esta validacion si se utilizan nombres de objeto unico como identificador de
    % campo en lugar del id generado por backbone.

    
    % si el valor ascii del primer caracter es un
    % numero, se inserta una x para coincidir con
    % el valor generado por jsondecode
    if campo(1) > 47 && campo(1) < 58
        campo = strcat('x', campo);
    end

    % se sustituyen guiones altos por guiones bajos
    % para que coincida la clave con la generada
    % por jsondecode
    newName = strrep(campo, '-', '_');

end

